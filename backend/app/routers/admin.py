from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from app.database.session import get_db
from app.models.user import User
from app.models.job import Job
from app.models.resume import Resume, ResumeAnalysis
from app.models.application import Application
from app.models.audit import AuditLog
from app.schemas.user import UserResponse, UserProfileResponse
from app.schemas.job import JobCreate, JobUpdate, JobResponse
from app.schemas.admin import (
    AdminDashboardStats,
    AdminAnalyticsResponse,
    AdminUserStatusUpdate,
    AdminUserRoleUpdate,
)
from app.auth.dependencies import get_current_admin
from app.services.admin_service import admin_service

router = APIRouter(prefix="/api/admin", tags=["Admin Portal"])


@router.get("/dashboard", response_model=AdminDashboardStats)
def get_admin_dashboard(
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    return admin_service.get_dashboard_stats(db)


@router.get("/analytics", response_model=AdminAnalyticsResponse)
def get_admin_analytics(
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    return admin_service.get_analytics(db)


@router.get("/users", response_model=List[UserProfileResponse])
def list_admin_users(
    search: Optional[str] = Query(None, description="Search by name, email, or username"),
    role: Optional[str] = Query(None, description="Filter by role USER or ADMIN"),
    is_active: Optional[bool] = Query(None, description="Filter by active status"),
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    query = db.query(User)

    if search:
        s = f"%{search.strip().lower()}%"
        query = query.filter(
            or_(
                func.lower(User.name).like(s),
                func.lower(User.email).like(s),
                func.lower(User.username).like(s),
            )
        )

    if role:
        query = query.filter(User.role == role.upper())

    if is_active is not None:
        query = query.filter(User.is_active == is_active)

    users = query.order_by(User.created_at.desc()).all()

    results = []
    for u in users:
        resumes_count = len(u.resumes) if u.resumes else 0
        apps_count = len(u.applications) if u.applications else 0
        saved_count = len(u.saved_jobs) if u.saved_jobs else 0

        latest_analysis = (
            db.query(ResumeAnalysis)
            .join(Resume, ResumeAnalysis.resume_id == Resume.id)
            .filter(Resume.user_id == u.id)
            .order_by(ResumeAnalysis.created_at.desc())
            .first()
        )

        results.append(
            UserProfileResponse(
                id=u.id,
                name=u.name,
                email=u.email,
                username=u.username,
                role=u.role,
                is_active=u.is_active,
                title=u.title,
                location=u.location,
                bio=u.bio,
                created_at=u.created_at,
                updated_at=u.updated_at,
                resumes_count=resumes_count,
                applications_count=apps_count,
                saved_jobs_count=saved_count,
                latest_resume_score=latest_analysis.overall_score if latest_analysis else None,
                latest_ats_score=latest_analysis.ats_score if latest_analysis else None,
            )
        )

    return results


@router.get("/users/{id}", response_model=UserProfileResponse)
def get_user_detail(
    id: int,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    u = db.query(User).filter(User.id == id).first()
    if not u:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    resumes_count = len(u.resumes) if u.resumes else 0
    apps_count = len(u.applications) if u.applications else 0
    saved_count = len(u.saved_jobs) if u.saved_jobs else 0

    latest_analysis = (
        db.query(ResumeAnalysis)
        .join(Resume, ResumeAnalysis.resume_id == Resume.id)
        .filter(Resume.user_id == u.id)
        .order_by(ResumeAnalysis.created_at.desc())
        .first()
    )

    return UserProfileResponse(
        id=u.id,
        name=u.name,
        email=u.email,
        username=u.username,
        role=u.role,
        is_active=u.is_active,
        title=u.title,
        location=u.location,
        bio=u.bio,
        created_at=u.created_at,
        updated_at=u.updated_at,
        resumes_count=resumes_count,
        applications_count=apps_count,
        saved_jobs_count=saved_count,
        latest_resume_score=latest_analysis.overall_score if latest_analysis else None,
        latest_ats_score=latest_analysis.ats_score if latest_analysis else None,
    )


@router.patch("/users/{id}/status", response_model=UserResponse)
def update_user_status(
    id: int,
    req: AdminUserStatusUpdate,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    if user.id == current_admin.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You cannot deactivate your own admin account.")

    user.is_active = req.is_active
    db.commit()
    db.refresh(user)

    audit = AuditLog(
        user_id=current_admin.id,
        action="UPDATE_USER_STATUS",
        entity_type="user",
        entity_id=str(user.id),
        details={"is_active": req.is_active}
    )
    db.add(audit)
    db.commit()

    return user


@router.patch("/users/{id}/role", response_model=UserResponse)
def update_user_role(
    id: int,
    req: AdminUserRoleUpdate,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    if req.role.upper() not in ["USER", "ADMIN"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role must be USER or ADMIN.")

    user.role = req.role.upper()
    db.commit()
    db.refresh(user)

    audit = AuditLog(
        user_id=current_admin.id,
        action="UPDATE_USER_ROLE",
        entity_type="user",
        entity_id=str(user.id),
        details={"role": req.role.upper()}
    )
    db.add(audit)
    db.commit()

    return user


@router.delete("/users/{id}", status_code=status.HTTP_200_OK)
def delete_user(
    id: int,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    user = db.query(User).filter(User.id == id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found.")

    if user.id == current_admin.id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="You cannot delete your own admin account.")

    db.delete(user)
    db.commit()

    audit = AuditLog(
        user_id=current_admin.id,
        action="DELETE_USER",
        entity_type="user",
        entity_id=str(id)
    )
    db.add(audit)
    db.commit()

    return {"message": "User deleted successfully.", "id": id}


# Admin Job Management Endpoints
@router.get("/jobs", response_model=List[JobResponse])
def get_admin_jobs(
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    jobs = db.query(Job).order_by(Job.created_at.desc()).all()
    return jobs


@router.post("/jobs", response_model=JobResponse, status_code=status.HTTP_201_CREATED)
def admin_create_job(
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
    return new_job


@router.put("/jobs/{id}", response_model=JobResponse)
def admin_update_job(
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
    return job


@router.delete("/jobs/{id}", status_code=status.HTTP_200_OK)
def admin_delete_job(
    id: int,
    current_admin: User = Depends(get_current_admin),
    db: Session = Depends(get_db)
):
    job = db.query(Job).filter(Job.id == id).first()
    if not job:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Job not found.")

    db.delete(job)
    db.commit()
    return {"message": "Job deleted successfully.", "id": id}
