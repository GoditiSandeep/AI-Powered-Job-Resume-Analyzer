import datetime
from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.database.base import Base


class CareerRecommendation(Base):
    __tablename__ = "career_recommendations"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    role_title = Column(String(255), nullable=False)
    match_percentage = Column(Float, nullable=False)
    current_skills = Column(JSON, default=list)
    required_skills = Column(JSON, default=list)
    skill_gaps = Column(JSON, default=list)
    next_steps = Column(JSON, default=list)
    salary_range = Column(String(100), nullable=True)
    demand_level = Column(String(50), default="High", nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="career_recommendations")


class SkillGap(Base):
    __tablename__ = "skill_gaps"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    target_role = Column(String(255), nullable=False)
    matched_skills = Column(JSON, default=list)
    missing_skills = Column(JSON, default=list)
    high_priority = Column(JSON, default=list)
    medium_priority = Column(JSON, default=list)
    low_priority = Column(JSON, default=list)
    learning_recommendations = Column(JSON, default=list)
    match_percentage = Column(Float, default=0.0)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="skill_gaps")
