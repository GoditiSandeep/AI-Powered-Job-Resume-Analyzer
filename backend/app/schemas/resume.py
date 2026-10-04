import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict


class ResumeBase(BaseModel):
    file_name: str
    file_type: str


class ResumeCreate(ResumeBase):
    file_path: str
    file_size_bytes: Optional[int] = None
    extracted_text: Optional[str] = None


class ResumeAnalysisSummary(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    resume_id: Optional[int] = None
    overall_score: float
    ats_score: float
    analysis_mode: str
    created_at: datetime.datetime


class ResumeResponse(ResumeBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    file_path: str
    file_size_bytes: Optional[int] = None
    created_at: datetime.datetime
    latest_analysis: Optional[ResumeAnalysisSummary] = None


class ResumeDetailResponse(ResumeBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    file_path: str
    file_size_bytes: Optional[int] = None
    extracted_text: Optional[str] = None
    created_at: datetime.datetime
    analyses: List[ResumeAnalysisSummary] = []
