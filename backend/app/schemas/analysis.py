import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, ConfigDict


class AnalysisRequest(BaseModel):
    target_job_title: Optional[str] = None
    target_job_description: Optional[str] = None
    force_fallback: bool = False


class ImprovementItem(BaseModel):
    section: str
    original: str
    improved: str
    reason: str


class ResumeAnalysisResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    resume_id: int
    overall_score: float
    ats_score: float
    analysis_mode: str

    contact_info: Optional[Dict[str, Any]] = Field(default_factory=dict)
    summary_analysis: Optional[Dict[str, Any]] = Field(default_factory=dict)
    skills: Optional[List[Any]] = Field(default_factory=list)
    education: Optional[List[Any]] = Field(default_factory=list)
    experience: Optional[List[Any]] = Field(default_factory=list)
    projects: Optional[List[Any]] = Field(default_factory=list)
    certifications: Optional[List[Any]] = Field(default_factory=list)
    achievements: Optional[List[Any]] = Field(default_factory=list)

    section_scores: Optional[Dict[str, Any]] = Field(default_factory=dict)
    strengths: Optional[List[Any]] = Field(default_factory=list)
    weaknesses: Optional[List[Any]] = Field(default_factory=list)
    detected_keywords: Optional[List[Any]] = Field(default_factory=list)
    missing_keywords: Optional[List[Any]] = Field(default_factory=list)
    industry_keywords: Optional[List[Any]] = Field(default_factory=list)
    content_feedback: Optional[Dict[str, Any]] = Field(default_factory=dict)
    ats_feedback: Optional[Dict[str, Any]] = Field(default_factory=dict)
    recommendations: Optional[List[Any]] = Field(default_factory=list)
    improvements: Optional[List[Any]] = Field(default_factory=list)
    created_at: datetime.datetime


class ResumeImprovementRequest(BaseModel):
    section: str
    original_text: str
    role_target: Optional[str] = "Software Engineer"


class ResumeImprovementResponse(BaseModel):
    section: str
    original_text: str
    improved_text: str
    key_changes: List[str]
    impact_score_boost: int
