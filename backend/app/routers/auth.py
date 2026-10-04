from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, func
from app.database.session import get_db
from app.models.user import User
from app.models.resume import Resume, ResumeAnalysis
from app.models.application import Application
from app.models.job import SavedJob
from app.models.audit import AuditLog
from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse
from app.schemas.user import UserResponse, UserProfileResponse, UserUpdate
from app.auth.security import get_password_hash, verify_password
from app.auth.jwt import create_access_token
from app.auth.dependencies import get_current_active_user
from app.config.settings import settings

router = APIRouter(prefix="/api/auth", tags=["Authentication"])


@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    # Check if user already exists
    existing = db.query(User).filter(
        or_(User.email == req.email.lower(), User.username == (req.username or req.email.lower()))
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="An account with this email or username already exists."
        )

    # Check if this matches admin config
    is_admin = (req.email.lower() == settings.ADMIN_EMAIL.lower())
    role = "ADMIN" if is_admin else "USER"

    new_user = User(
        name=req.name.strip(),
        email=req.email.lower().strip(),
        username=req.username.strip() if req.username else req.email.split("@")[0],
        hashed_password=get_password_hash(req.password),
        role=role,
        is_active=True,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    # Log audit
    audit = AuditLog(user_id=new_user.id, action="REGISTER", entity_type="user", entity_id=str(new_user.id))
    db.add(audit)
    db.commit()

    # Generate token
    token_payload = {"sub": str(new_user.id), "email": new_user.email, "role": new_user.role}
    token = create_access_token(token_payload)

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user={
            "id": new_user.id,
            "name": new_user.name,
            "email": new_user.email,
            "username": new_user.username,
            "role": new_user.role,
        }
    )


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    identifier = req.username_or_email.strip().lower()
    user = db.query(User).filter(
        or_(User.email == identifier, func.lower(User.username) == identifier)
    ).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/username or password."
        )

    if not verify_password(req.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email/username or password."
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account has been deactivated. Please contact administrator."
        )

    # Audit log
    audit = AuditLog(user_id=user.id, action="LOGIN", entity_type="user", entity_id=str(user.id))
    db.add(audit)
    db.commit()

    token_payload = {"sub": str(user.id), "email": user.email, "role": user.role}
    token = create_access_token(token_payload)

    return TokenResponse(
        access_token=token,
        token_type="bearer",
        expires_in=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user={
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "username": user.username,
            "role": user.role,
        }
    )


@router.post("/logout")
def logout(current_user: User = Depends(get_current_active_user), db: Session = Depends(get_db)):
    audit = AuditLog(user_id=current_user.id, action="LOGOUT", entity_type="user", entity_id=str(current_user.id))
    db.add(audit)
    db.commit()
    return {"message": "Successfully logged out."}


@router.get("/me", response_model=UserProfileResponse)
def get_current_user_profile(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    resumes_count = db.query(func.count(Resume.id)).filter(Resume.user_id == current_user.id).scalar() or 0
    apps_count = db.query(func.count(Application.id)).filter(Application.user_id == current_user.id).scalar() or 0
    saved_count = db.query(func.count(SavedJob.id)).filter(SavedJob.user_id == current_user.id).scalar() or 0

    latest_analysis = (
        db.query(ResumeAnalysis)
        .join(Resume, ResumeAnalysis.resume_id == Resume.id)
        .filter(Resume.user_id == current_user.id)
        .order_by(ResumeAnalysis.created_at.desc())
        .first()
    )

    return UserProfileResponse(
        id=current_user.id,
        name=current_user.name,
        email=current_user.email,
        username=current_user.username,
        role=current_user.role,
        is_active=current_user.is_active,
        title=current_user.title,
        location=current_user.location,
        bio=current_user.bio,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at,
        resumes_count=resumes_count,
        applications_count=apps_count,
        saved_jobs_count=saved_count,
        latest_resume_score=latest_analysis.overall_score if latest_analysis else None,
        latest_ats_score=latest_analysis.ats_score if latest_analysis else None,
    )


@router.put("/me", response_model=UserResponse)
def update_profile(
    req: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    if req.name is not None:
        current_user.name = req.name.strip()
    if req.username is not None:
        current_user.username = req.username.strip()
    if req.title is not None:
        current_user.title = req.title.strip()
    if req.location is not None:
        current_user.location = req.location.strip()
    if req.bio is not None:
        current_user.bio = req.bio.strip()
    if req.password is not None and len(req.password.strip()) >= 6:
        current_user.hashed_password = get_password_hash(req.password)

    db.commit()
    db.refresh(current_user)
    return current_user
