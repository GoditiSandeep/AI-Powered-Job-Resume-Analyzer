import datetime
from sqlalchemy import Column, Integer, String, Text, Float, DateTime, ForeignKey, JSON
from sqlalchemy.orm import relationship
from app.database.base import Base


class Resume(Base):
    __tablename__ = "resumes"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    file_name = Column(String(255), nullable=False)
    file_type = Column(String(50), nullable=False)  # pdf, docx, doc, txt
    file_path = Column(String(500), nullable=False)
    file_size_bytes = Column(Integer, nullable=True)
    extracted_text = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    # Relationships
    user = relationship("User", back_populates="resumes")
    analyses = relationship("ResumeAnalysis", back_populates="resume", cascade="all, delete-orphan", order_by="desc(ResumeAnalysis.created_at)")


class ResumeAnalysis(Base):
    __tablename__ = "resume_analyses"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    resume_id = Column(Integer, ForeignKey("resumes.id", ondelete="CASCADE"), nullable=False, index=True)
    overall_score = Column(Float, nullable=False)  # 0 - 100
    ats_score = Column(Float, nullable=False)  # 0 - 100

    # Structured Extractions
    contact_info = Column(JSON, default=dict)  # {name, email, phone, location, linkedin, github, portfolio}
    summary_analysis = Column(JSON, default=dict)  # {text, score, strengths, weaknesses, improved_version}
    skills = Column(JSON, default=list)  # list of detected skills with category
    education = Column(JSON, default=list)  # list of education items
    experience = Column(JSON, default=list)  # list of experience items
    projects = Column(JSON, default=list)  # list of project items
    certifications = Column(JSON, default=list)  # list of certifications
    achievements = Column(JSON, default=list)  # list of achievements

    # Detailed Evaluation
    section_scores = Column(JSON, default=dict)  # {contact, summary, education, experience, projects, skills, certifications}
    strengths = Column(JSON, default=list)
    weaknesses = Column(JSON, default=list)
    detected_keywords = Column(JSON, default=list)
    missing_keywords = Column(JSON, default=list)
    industry_keywords = Column(JSON, default=list)
    content_feedback = Column(JSON, default=dict)  # {weak_verbs, vague_statements, readability, clarity}
    ats_feedback = Column(JSON, default=dict)  # {structure, keyword_density, formatting_risks, compliance_status}
    recommendations = Column(JSON, default=list)
    improvements = Column(JSON, default=list)  # list of before/after transformation suggestions

    analysis_mode = Column(String(50), default="fallback")  # "ai_llm" or "deterministic_fallback"
    created_at = Column(DateTime, default=datetime.datetime.utcnow, nullable=False)

    # Relationships
    resume = relationship("Resume", back_populates="analyses")
