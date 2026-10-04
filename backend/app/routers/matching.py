from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.user import User
from app.models.job import Job
from app.models.resume import Resume, ResumeAnalysis
from app.schemas.job import JobMatchResponse
from app.schemas.career import CareerRecommendationResponse
from app.auth.dependencies import get_current_active_user
from app.services.job_matcher import job_matcher
from app.services.career_service import career_service

router = APIRouter(tags=["Matching & Recommendations"])


@router.get("/api/jobs/{id}/match", response_model=JobMatchResponse)
def get_job_match(
    id: int,
    resume_id: Optional[int] = Query(None, description="Optional specific resume ID to match against"),
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    job = db.query(Job).filter(Job.id == id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found.")

    # Find the target resume analysis
    if resume_id:
        resume = db.query(Resume).filter(Resume.id == resume_id, Resume.user_id == current_user.id).first()
        if not resume:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Resume not found.")
        analysis = db.query(ResumeAnalysis).filter(ResumeAnalysis.resume_id == resume.id).order_by(ResumeAnalysis.created_at.desc()).first()
    else:
        analysis = (
            db.query(ResumeAnalysis)
            .join(Resume, ResumeAnalysis.resume_id == Resume.id)
            .filter(Resume.user_id == current_user.id)
            .order_by(ResumeAnalysis.created_at.desc())
            .first()
        )

    match_result = job_matcher.calculate_match(job, analysis)
    return JobMatchResponse(**match_result)


@router.get("/api/recommendations", response_model=List[CareerRecommendationResponse])
def get_career_recommendations(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    latest_analysis = (
        db.query(ResumeAnalysis)
        .join(Resume, ResumeAnalysis.resume_id == Resume.id)
        .filter(Resume.user_id == current_user.id)
        .order_by(ResumeAnalysis.created_at.desc())
        .first()
    )

    recommendations = career_service.get_career_recommendations(latest_analysis)
    return [CareerRecommendationResponse(**r) for r in recommendations]
