import datetime
from sqlalchemy import Column, Integer, String, Text, Boolean, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.database.base import Base


class Job(Base):
    __tablename__ = "jobs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String(255), nullable=False, index=True)
    company = Column(String(255), nullable=False, index=True)
    location = Column(String(255), nullable=False, index=True)
    salary = Column(String(100), nullable=True)
    employment_type = Column(String(100), default="Full-time", nullable=False)  # Full-time, Part-time, Remote, Contract, Hybrid
    experience = Column(String(100), default="1-3 years", nullable=False)
    description = Column(Text, nullable=False)
    responsibilities = Column(JSON, default=list)  # list of bullet points
    required_skills = Column(JSON, default=list)  # list of skill strings
    preferred_skills = Column(JSON, default=list)  # list of skill strings
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow, nullable=False)

    # Relationships
    job_skills = relationship("JobSkill", back_populates="job", cascade="all, delete-orphan")
    saved_by_users = relationship("SavedJob", back_populates="job", cascade="all, delete-orphan")
    applications = relationship("Application", back_populates="job", cascade="all, delete-orphan")


class JobSkill(Base):
    __tablename__ = "job_skills"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    job_id = Column(Integer, ForeignKey("jobs.id", ondelete="CASCADE"), nullable=False, index=True)
    skill_id = Column(Integer, ForeignKey("skills.id", ondelete="CASCADE"), nullable=False, index=True)
    is_required = Column(Boolean, default=True, nullable=False)

    job = relationship("Job", back_populates="job_skills")
    skill = relationship("Skill", back_populates="job_skills")


class SavedJob(Base):
    __tablename__ = "saved_jobs"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    job_id = Column(Integer, ForeignKey("jobs.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    user = relationship("User", back_populates="saved_jobs")
    job = relationship("Job", back_populates="saved_by_users")
