from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.user import User
from app.models.skill import Skill
from app.models.resume import Resume, ResumeAnalysis
from app.schemas.skill import SkillResponse, SkillGapRequest, SkillGapResponse
from app.auth.dependencies import get_current_active_user
from app.services.career_service import career_service

router = APIRouter(prefix="/api/skills", tags=["Skills & Gap Analysis"])


@router.get("", response_model=List[SkillResponse])
def get_skills(
    category: Optional[str] = Query(None, description="Filter skills by category"),
    db: Session = Depends(get_db)
):
    query = db.query(Skill)
    if category:
        query = query.filter(Skill.category == category.strip().lower())
    return query.order_by(Skill.name.asc()).all()


@router.post("/gaps", response_model=SkillGapResponse)
def analyze_skill_gaps(
    req: SkillGapRequest,
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

    gap_result = career_service.analyze_skill_gap(req.target_role, latest_analysis)
    return SkillGapResponse(**gap_result)
