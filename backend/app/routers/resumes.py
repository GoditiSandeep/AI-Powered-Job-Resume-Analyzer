import os
import uuid
import datetime
from typing import List
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, status
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.user import User
from app.models.resume import Resume, ResumeAnalysis
from app.models.audit import AuditLog
from app.schemas.resume import ResumeResponse, ResumeDetailResponse
from app.auth.dependencies import get_current_active_user
from app.services.resume_parser import resume_parser
from app.ai.service import ai_service
from app.config.settings import settings

router = APIRouter(prefix="/api/resumes", tags=["Resumes"])


@router.post("/upload", response_model=ResumeDetailResponse, status_code=status.HTTP_201_CREATED)
async def upload_resume(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    # 1. Validate file extension
    filename = file.filename or "resume.pdf"
    ext = filename.split(".")[-1].lower() if "." in filename else ""
    if ext not in settings.ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file format '.{ext}'. Allowed formats are: {', '.join(settings.ALLOWED_EXTENSIONS)}"
        )

    # 2. Read file content and validate size
    content = await file.read()
    if len(content) == 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is empty. Please upload a valid document."
        )

    max_bytes = settings.MAX_UPLOAD_SIZE_MB * 1024 * 1024
    if len(content) > max_bytes:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File exceeds maximum size of {settings.MAX_UPLOAD_SIZE_MB}MB."
        )

    # 3. Save to disk securely
    unique_name = f"{uuid.uuid4().hex}_{filename}"
    save_path = os.path.join(settings.UPLOAD_DIR, unique_name)
    with open(save_path, "wb") as f:
        f.write(content)

    # 4. Extract text
    try:
        extracted_text = resume_parser.extract_text_from_file(save_path, ext)
    except Exception as e:
        extracted_text = f"Resume text extracted with warnings: {str(e)}"

    # 5. Create Resume in DB
    resume = Resume(
        user_id=current_user.id,
        file_name=filename,
        file_type=ext,
        file_path=save_path,
        file_size_bytes=len(content),
        extracted_text=extracted_text,
    )
    db.add(resume)
    db.commit()
    db.refresh(resume)

    # 6. Run initial analysis
    try:
        analysis_data = ai_service.analyze(extracted_text)
        analysis_obj = ResumeAnalysis(
            resume_id=resume.id,
            overall_score=analysis_data.get("overall_score", 75.0),
            ats_score=analysis_data.get("ats_score", 80.0),
            analysis_mode=analysis_data.get("analysis_mode", "deterministic_fallback"),
            contact_info=analysis_data.get("contact_info", {}),
            summary_analysis=analysis_data.get("summary_analysis", {}),
            skills=analysis_data.get("skills", []),
            education=analysis_data.get("education", []),
            experience=analysis_data.get("experience", []),
            projects=analysis_data.get("projects", []),
            certifications=analysis_data.get("certifications", []),
            achievements=analysis_data.get("achievements", []),
            section_scores=analysis_data.get("section_scores", {}),
            strengths=analysis_data.get("strengths", []),
            weaknesses=analysis_data.get("weaknesses", []),
            detected_keywords=analysis_data.get("detected_keywords", []),
            missing_keywords=analysis_data.get("missing_keywords", []),
            industry_keywords=analysis_data.get("industry_keywords", []),
            content_feedback=analysis_data.get("content_feedback", {}),
            ats_feedback=analysis_data.get("ats_feedback", {}),
            recommendations=analysis_data.get("recommendations", []),
            improvements=analysis_data.get("improvements", []),
        )
        db.add(analysis_obj)
        db.commit()
        db.refresh(resume)
    except Exception as e:
        db.rollback()

    # Log audit
    audit = AuditLog(
        user_id=current_user.id,
        action="UPLOAD_RESUME",
        entity_type="resume",
        entity_id=str(resume.id),
        details={"file_name": filename, "file_size": len(content)}
    )
    db.add(audit)
    db.commit()

    return resume


@router.get("", response_model=List[ResumeResponse])
def get_user_resumes(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    resumes = db.query(Resume).filter(Resume.user_id == current_user.id).order_by(Resume.created_at.desc()).all()
    results = []
    for r in resumes:
        latest = r.analyses[0] if r.analyses else None
        latest_summary = None
        if latest:
            latest_summary = {
                "id": latest.id,
                "overall_score": latest.overall_score,
                "ats_score": latest.ats_score,
                "analysis_mode": latest.analysis_mode,
                "created_at": latest.created_at,
            }
        results.append(
            ResumeResponse(
                id=r.id,
                user_id=r.user_id,
                file_name=r.file_name,
                file_type=r.file_type,
                file_path=r.file_path,
                file_size_bytes=r.file_size_bytes,
                created_at=r.created_at,
                latest_analysis=latest_summary,
            )
        )
    return results


@router.get("/{id}", response_model=ResumeDetailResponse)
def get_resume_by_id(
    id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    resume = db.query(Resume).filter(Resume.id == id).first()
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")

    if resume.user_id != current_user.id and current_user.role != "ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    return resume


@router.delete("/{id}", status_code=status.HTTP_200_OK)
def delete_resume(
    id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    resume = db.query(Resume).filter(Resume.id == id).first()
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")

    if resume.user_id != current_user.id and current_user.role != "ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    # Remove file on disk if exists
    if os.path.exists(resume.file_path):
        try:
            os.remove(resume.file_path)
        except Exception:
            pass

    db.delete(resume)
    db.commit()

    # Log audit
    audit = AuditLog(
        user_id=current_user.id,
        action="DELETE_RESUME",
        entity_type="resume",
        entity_id=str(id)
    )
    db.add(audit)
    db.commit()

    return {"message": "Resume deleted successfully.", "id": id}
