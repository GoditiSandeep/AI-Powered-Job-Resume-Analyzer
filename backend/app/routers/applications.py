from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.database.session import get_db
from app.models.user import User
from app.models.job import Job
from app.models.application import Application
from app.models.audit import AuditLog
from app.schemas.application import (
    ApplicationCreate,
    ApplicationUpdate,
    ApplicationResponse,
    ApplicationStatsResponse,
)
from app.schemas.job import JobResponse
from app.auth.dependencies import get_current_active_user

router = APIRouter(prefix="/api/applications", tags=["Application Tracker"])


@router.get("/stats", response_model=ApplicationStatsResponse)
def get_application_stats(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    apps = db.query(Application.status, func.count(Application.id)).filter(
        Application.user_id == current_user.id
    ).group_by(Application.status).all()

    counts = {"Saved": 0, "Applied": 0, "Interview": 0, "Selected": 0, "Rejected": 0}
    total = 0
    for s_val, count in apps:
        total += count
        if s_val in counts:
            counts[s_val] = count

    return ApplicationStatsResponse(
        total_applications=total,
        saved=counts["Saved"],
        applied=counts["Applied"],
        interviews=counts["Interview"],
        selected=counts["Selected"],
        rejected=counts["Rejected"],
    )


@router.get("", response_model=List[ApplicationResponse])
def list_applications(
    status_filter: Optional[str] = None,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    query = db.query(Application).filter(Application.user_id == current_user.id)
    if status_filter:
        query = query.filter(func.lower(Application.status) == status_filter.strip().lower())

    applications = query.order_by(Application.updated_at.desc()).all()

    results = []
    for app in applications:
        job_data = None
        if app.job:
            job_data = JobResponse(
                id=app.job.id,
                title=app.job.title,
                company=app.job.company,
                location=app.job.location,
                salary=app.job.salary,
                employment_type=app.job.employment_type,
                experience=app.job.experience,
                description=app.job.description,
                responsibilities=app.job.responsibilities or [],
                required_skills=app.job.required_skills or [],
                preferred_skills=app.job.preferred_skills or [],
                is_active=app.job.is_active,
                created_at=app.job.created_at,
                updated_at=app.job.updated_at,
                is_saved=False,
                application_status=app.status,
            )

        results.append(
            ApplicationResponse(
                id=app.id,
                user_id=app.user_id,
                job_id=app.job_id,
                status=app.status,
                notes=app.notes,
                interview_date=app.interview_date,
                applied_date=app.applied_date,
                created_at=app.created_at,
                updated_at=app.updated_at,
                job=job_data,
            )
        )
    return results


@router.post("", response_model=ApplicationResponse, status_code=status.HTTP_201_CREATED)
def create_application(
    req: ApplicationCreate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    job = db.query(Job).filter(Job.id == req.job_id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found.")

    # Check if existing application exists
    existing = db.query(Application).filter(
        Application.user_id == current_user.id,
        Application.job_id == req.job_id
    ).first()

    if existing:
        # Update existing
        existing.status = req.status
        if req.notes is not None:
            existing.notes = req.notes
        if req.interview_date is not None:
            existing.interview_date = req.interview_date
        db.commit()
        db.refresh(existing)
        app_obj = existing
    else:
        app_obj = Application(
            user_id=current_user.id,
            job_id=req.job_id,
            status=req.status,
            notes=req.notes,
            interview_date=req.interview_date,
        )
        db.add(app_obj)
        db.commit()
        db.refresh(app_obj)

    # Log audit
    audit = AuditLog(
        user_id=current_user.id,
        action="APPLY_JOB",
        entity_type="application",
        entity_id=str(app_obj.id),
        details={"job_id": job.id, "job_title": job.title, "status": app_obj.status}
    )
    db.add(audit)
    db.commit()

    return app_obj


@router.put("/{id}", response_model=ApplicationResponse)
def update_application(
    id: int,
    req: ApplicationUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    app = db.query(Application).filter(Application.id == id).first()
    if not app:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found.")

    if app.user_id != current_user.id and current_user.role != "ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    if req.status is not None:
        app.status = req.status
    if req.notes is not None:
        app.notes = req.notes
    if req.interview_date is not None:
        app.interview_date = req.interview_date

    db.commit()
    db.refresh(app)
    return app


@router.delete("/{id}", status_code=status.HTTP_200_OK)
def delete_application(
    id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    app = db.query(Application).filter(Application.id == id).first()
    if not app:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found.")

    if app.user_id != current_user.id and current_user.role != "ADMIN":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied.")

    db.delete(app)
    db.commit()
    return {"message": "Application removed successfully.", "id": id}
