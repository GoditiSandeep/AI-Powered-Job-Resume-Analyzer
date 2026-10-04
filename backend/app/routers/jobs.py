from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from app.database.session import get_db
from app.models.user import User
from app.models.job import Job, SavedJob
from app.models.application import Application
from app.models.resume import Resume, ResumeAnalysis
from app.models.audit import AuditLog
from app.schemas.job import JobCreate, JobUpdate, JobResponse
from app.auth.dependencies import get_current_active_user, get_optional_current_user, get_current_admin
from app.services.job_matcher import job_matcher

router = APIRouter(prefix="/api/jobs", tags=["Job Management"])


@router.get("", response_model=List[JobResponse])
def list_jobs(
    search: Optional[str] = Query(None, description="Search across title, company, description"),
    location: Optional[str] = Query(None, description="Filter by location"),
    employment_type: Optional[str] = Query(None, description="Filter by employment type"),
    experience: Optional[str] = Query(None, description="Filter by experience"),
    skill: Optional[str] = Query(None, description="Filter by required skill"),
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Job).filter(Job.is_active == True)

    if search:
        s = f"%{search.strip().lower()}%"
        query = query.filter(
            or_(
                func.lower(Job.title).like(s),
                func.lower(Job.company).like(s),
                func.lower(Job.description).like(s),
            )
        )

    if location:
        query = query.filter(func.lower(Job.location).like(f"%{location.strip().lower()}%"))

    if employment_type:
        query = query.filter(func.lower(Job.employment_type) == employment_type.strip().lower())

    if experience:
        query = query.filter(func.lower(Job.experience).like(f"%{experience.strip().lower()}%"))

    jobs = query.order_by(Job.created_at.desc()).all()

    # Get current user saved jobs and applications if logged in
    saved_job_ids = set()
    app_status_map = {}
    latest_analysis = None

    if current_user:
        saved_records = db.query(SavedJob.job_id).filter(SavedJob.user_id == current_user.id).all()
        saved_job_ids = {r[0] for r in saved_records}

        app_records = db.query(Application.job_id, Application.status).filter(Application.user_id == current_user.id).all()
        app_status_map = {r[0]: r[1] for r in app_records}

        # Fetch latest resume analysis for match calculation
        latest_analysis = (
            db.query(ResumeAnalysis)
            .join(Resume, ResumeAnalysis.resume_id == Resume.id)
            .filter(Resume.user_id == current_user.id)
            .order_by(ResumeAnalysis.created_at.desc())
            .first()
        )

    results = []
    for job in jobs:
        # Filter by skill if requested
        if skill:
            req_skills_lower = [str(sk).lower() for sk in (job.required_skills or [])]
            if not any(skill.lower() in sk for sk in req_skills_lower):
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
                is_saved=(job.id in saved_job_ids),
                application_status=app_status_map.get(job.id),
                match_percentage=match_score,
            )
        )

    return results


@router.get("/{id}", response_model=JobResponse)
def get_job_details(
    id: int,
    current_user: Optional[User] = Depends(get_optional_current_user),
    db: Session = Depends(get_db)
):
    job = db.query(Job).filter(Job.id == id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found.")

    is_saved = False
    app_status = None
    match_score = None

    if current_user:
        saved = db.query(SavedJob).filter(SavedJob.user_id == current_user.id, SavedJob.job_id == id).first()
        is_saved = bool(saved)

        app = db.query(Application).filter(Application.user_id == current_user.id, Application.job_id == id).first()
        if app:
            app_status = app.status

        latest_analysis = (
            db.query(ResumeAnalysis)
            .join(Resume, ResumeAnalysis.resume_id == Resume.id)
            .filter(Resume.user_id == current_user.id)
            .order_by(ResumeAnalysis.created_at.desc())
            .first()
        )
        if latest_analysis:
            match_data = job_matcher.calculate_match(job, latest_analysis)
            match_score = match_data["overall_match_percentage"]

    return JobResponse(
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
        is_saved=is_saved,
        application_status=app_status,
        match_percentage=match_score,
    )


@router.post("", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
def create_job(
    req: JobCreate,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    new_job = Job(
        title=req.title.strip(),
        company=req.company.strip(),
        location=req.location.strip(),
        salary=req.salary,
        employment_type=req.employment_type,
        experience=req.experience,
        description=req.description.strip(),
        responsibilities=req.responsibilities or [],
        required_skills=req.required_skills or [],
        preferred_skills=req.preferred_skills or [],
        is_active=req.is_active,
    )
    db.add(new_job)
    db.commit()
    db.refresh(new_job)

    # Log audit
    audit = AuditLog(
        user_id=current_admin.id,
        action="CREATE_JOB",
        entity_type="job",
        entity_id=str(new_job.id),
        details={"title": new_job.title, "company": new_job.company}
    )
    db.add(audit)
    db.commit()

    return new_job


@router.put("/{id}", response_model=JobResponse)
def update_job(
    id: int,
    req: JobUpdate,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    job = db.query(Job).filter(Job.id == id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found.")

    if req.title is not None:
        job.title = req.title.strip()
    if req.company is not None:
        job.company = req.company.strip()
    if req.location is not None:
        job.location = req.location.strip()
    if req.salary is not None:
        job.salary = req.salary
    if req.employment_type is not None:
        job.employment_type = req.employment_type
    if req.experience is not None:
        job.experience = req.experience
    if req.description is not None:
        job.description = req.description.strip()
    if req.responsibilities is not None:
        job.responsibilities = req.responsibilities
    if req.required_skills is not None:
        job.required_skills = req.required_skills
    if req.preferred_skills is not None:
        job.preferred_skills = req.preferred_skills
    if req.is_active is not None:
        job.is_active = req.is_active

    db.commit()
    db.refresh(job)

    # Log audit
    audit = AuditLog(
        user_id=current_admin.id,
        action="UPDATE_JOB",
        entity_type="job",
        entity_id=str(job.id),
        details={"title": job.title}
    )
    db.add(audit)
    db.commit()

    return job


@router.delete("/{id}", status_code=status.HTTP_200_OK)
def delete_job(
    id: int,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    job = db.query(Job).filter(Job.id == id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found.")

    db.delete(job)
    db.commit()

    # Log audit
    audit = AuditLog(
        user_id=current_admin.id,
        action="DELETE_JOB",
        entity_type="job",
        entity_id=str(id)
    )
    db.add(audit)
    db.commit()

    return {"message": "Job deleted successfully.", "id": id}
