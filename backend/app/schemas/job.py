import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field, ConfigDict


class JobBase(BaseModel):
    title: str = Field(..., min_length=2, max_length=255)
    company: str = Field(..., min_length=2, max_length=255)
    location: str = Field(..., min_length=2, max_length=255)
    salary: Optional[str] = "₹10,00,000 - ₹15,00,000"
    employment_type: str = "Full-time"
    experience: str = "1-3 years"
    description: str
    responsibilities: Optional[List[Any]] = Field(default_factory=list)
    required_skills: Optional[List[Any]] = Field(default_factory=list)
    preferred_skills: Optional[List[Any]] = Field(default_factory=list)
    is_active: bool = True


class JobCreate(JobBase):
    pass


class JobUpdate(BaseModel):
    title: Optional[str] = None
    company: Optional[str] = None
    location: Optional[str] = None
    salary: Optional[str] = None
    employment_type: Optional[str] = None
    experience: Optional[str] = None
    description: Optional[str] = None
    responsibilities: Optional[List[Any]] = None
    required_skills: Optional[List[Any]] = None
    preferred_skills: Optional[List[Any]] = None
    is_active: Optional[bool] = None


class JobResponse(JobBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    created_at: datetime.datetime
    updated_at: datetime.datetime
    is_saved: Optional[bool] = False
    application_status: Optional[str] = None
    match_percentage: Optional[float] = None


class JobMatchResponse(BaseModel):
    job_id: int
    job_title: str
    company: str
    overall_match_percentage: float
    skill_match_score: float
    keyword_match_score: float
    experience_match_score: float
    education_match_score: float
    matched_skills: List[str]
    missing_skills: List[str]
    match_reasons: List[str]
    improvement_recommendations: List[str]


class SavedJobResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    job_id: int
    job: JobResponse
    created_at: datetime.datetime
