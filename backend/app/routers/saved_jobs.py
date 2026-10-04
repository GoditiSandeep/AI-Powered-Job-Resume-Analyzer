from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.user import User
from app.models.job import Job, SavedJob
from app.models.resume import Resume, ResumeAnalysis
from app.models.application import Application
from app.schemas.job import JobResponse
from app.auth.dependencies import get_current_active_user
from app.services.job_matcher import job_matcher

router = APIRouter(prefix="/api/jobs", tags=["Saved Jobs"])


@router.post("/{id}/save", status_code=status.HTTP_200_OK)
def save_job(
    id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    job = db.query(Job).filter(Job.id == id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found.")

    existing = db.query(SavedJob).filter(SavedJob.user_id == current_user.id, SavedJob.job_id == id).first()
    if not existing:
        saved = SavedJob(user_id=current_user.id, job_id=id)
        db.add(saved)
        db.commit()

    return {"message": "Job saved successfully.", "job_id": id, "is_saved": True}


@router.delete("/{id}/save", status_code=status.HTTP_200_OK)
def unsave_job(
    id: int,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    saved = db.query(SavedJob).filter(SavedJob.user_id == current_user.id, SavedJob.job_id == id).first()
    if saved:
        db.delete(saved)
        db.commit()

    return {"message": "Job unsaved successfully.", "job_id": id, "is_saved": False}


@router.get("/saved", response_model=List[JobResponse])
def get_saved_jobs(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    saved_records = (
        db.query(SavedJob)
        .filter(SavedJob.user_id == current_user.id)
        .order_by(SavedJob.created_at.desc())
        .all()
    )

    latest_analysis = (
        db.query(ResumeAnalysis)
        .join(Resume, ResumeAnalysis.resume_id == Resume.id)
        .filter(Resume.user_id == current_user.id)
        .order_by(ResumeAnalysis.created_at.desc())
        .first()
    )

    app_records = db.query(Application.job_id, Application.status).filter(Application.user_id == current_user.id).all()
    app_status_map = {r[0]: r[1] for r in app_records}

    results = []
    for s in saved_records:
        job = s.job
        if not job or not job.is_active:
            continue

        match_score = None
        if latest_analysis:
            match_data = job_matcher.calculate_match(job, latest_analysis)
            match_score = match_data["overall_match_percentage"]

        results.append(
            JobResponse(
                id=job.id,
                title=job.title,
                company=job.company,
                location=job.location,
                salary=job.salary,
                employment_type=job.employment_type,
                experience=job.experience,
                description=job.description,
                responsibilities=job.responsibilities or [],
                required_skills=job.required_skills or [],
                preferred_skills=job.preferred_skills or [],
                is_active=job.is_active,
                created_at=job.created_at,
                updated_at=job.updated_at,
                is_saved=True,
                application_status=app_status_map.get(job.id),
                match_percentage=match_score,
            )
        )

    return results
