from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.user import User
from app.models.resume import Resume, ResumeAnalysis
from app.models.audit import AuditLog
from app.schemas.analysis import (
    AnalysisRequest,
    ResumeAnalysisResponse,
    ResumeImprovementRequest,
    ResumeImprovementResponse,
)
from app.auth.dependencies import get_current_active_user
from app.ai.service import ai_service

router = APIRouter(prefix="/api/resumes", tags=["AI Resume Analysis"])


@router.post("/{id}/analyze", response_model=ResumeAnalysisResponse)
def analyze_resume(
    id: int,
    req: AnalysisRequest,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    resume = db.query(Resume).filter(Resume.id == id).first()
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")

    if resume.user_id != current_user.id and current_user.role != "ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    if not resume.extracted_text or len(resume.extracted_text.strip()) < 10:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Resume does not contain sufficient text for analysis."
        )

    # Perform analysis
    result = ai_service.analyze(
        resume_text=resume.extracted_text,
        target_job_title=req.target_job_title,
        target_job_description=req.target_job_description,
        force_fallback=req.force_fallback,
    )

    analysis_obj = ResumeAnalysis(
        resume_id=resume.id,
        overall_score=result.get("overall_score", 80.0),
        ats_score=result.get("ats_score", 82.0),
        analysis_mode=result.get("analysis_mode", "deterministic_fallback"),
        contact_info=result.get("contact_info", {}),
        summary_analysis=result.get("summary_analysis", {}),
        skills=result.get("skills", []),
        education=result.get("education", []),
        experience=result.get("experience", []),
        projects=result.get("projects", []),
        certifications=result.get("certifications", []),
        achievements=result.get("achievements", []),
        section_scores=result.get("section_scores", {}),
        strengths=result.get("strengths", []),
        weaknesses=result.get("weaknesses", []),
        detected_keywords=result.get("detected_keywords", []),
        missing_keywords=result.get("missing_keywords", []),
        industry_keywords=result.get("industry_keywords", []),
        content_feedback=result.get("content_feedback", {}),
        ats_feedback=result.get("ats_feedback", {}),
        recommendations=result.get("recommendations", []),
        improvements=result.get("improvements", []),
    )
    db.add(analysis_obj)
    db.commit()
    db.refresh(analysis_obj)

    # Audit log
    audit = AuditLog(
        user_id=current_user.id,
        action="ANALYZE_RESUME",
        entity_type="resume_analysis",
        entity_id=str(analysis_obj.id),
        details={"score": analysis_obj.overall_score, "ats_score": analysis_obj.ats_score}
    )
    db.add(audit)
    db.commit()

    return analysis_obj


@router.get("/{id}/analysis", response_model=ResumeAnalysisResponse)
def get_resume_analysis(
    id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    resume = db.query(Resume).filter(Resume.id == id).first()
    if not resume:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")

    if resume.user_id != current_user.id and current_user.role != "ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    latest = db.query(ResumeAnalysis).filter(ResumeAnalysis.resume_id == id).order_by(ResumeAnalysis.created_at.desc()).first()
    if not latest:
        # Trigger on-demand analysis if none exists yet
        result = ai_service.analyze(resume.extracted_text or "General Candidate")
        latest = ResumeAnalysis(
            resume_id=resume.id,
            overall_score=result.get("overall_score", 75.0),
            ats_score=result.get("ats_score", 80.0),
            analysis_mode=result.get("analysis_mode", "deterministic_fallback"),
            contact_info=result.get("contact_info", {}),
            summary_analysis=result.get("summary_analysis", {}),
            skills=result.get("skills", []),
            education=result.get("education", []),
            experience=result.get("experience", []),
            projects=result.get("projects", []),
            certifications=result.get("certifications", []),
            achievements=result.get("achievements", []),
            section_scores=result.get("section_scores", {}),
            strengths=result.get("strengths", []),
            weaknesses=result.get("weaknesses", []),
            detected_keywords=result.get("detected_keywords", []),
            missing_keywords=result.get("missing_keywords", []),
            industry_keywords=result.get("industry_keywords", []),
            content_feedback=result.get("content_feedback", {}),
            ats_feedback=result.get("ats_feedback", {}),
            recommendations=result.get("recommendations", []),
            improvements=result.get("improvements", []),
        )
        db.add(latest)
        db.commit()
        db.refresh(latest)

    return latest


@router.post("/improve-text", response_model=ResumeImprovementResponse)
def improve_resume_text(
    req: ResumeImprovementRequest,
    current_user: User = Depends(get_current_active_user),
):
    if not req.original_text or len(req.original_text.strip()) < 3:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Text to improve is too short.")

    improved = ai_service.improve_text(
        section=req.section,
        original_text=req.original_text,
        role_target=req.role_target or "Software Engineer",
    )
    return ResumeImprovementResponse(**improved)
