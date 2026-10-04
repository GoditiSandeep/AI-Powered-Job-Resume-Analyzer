import datetime
from typing import Optional, Dict
from pydantic import BaseModel, Field, ConfigDict
from app.schemas.job import JobResponse


class ApplicationCreate(BaseModel):
    job_id: int
    status: str = Field(default="Applied", description="Saved, Applied, Interview, Selected, Rejected")
    notes: Optional[str] = None
    interview_date: Optional[datetime.datetime] = None


class ApplicationUpdate(BaseModel):
    status: Optional[str] = Field(None, description="Saved, Applied, Interview, Selected, Rejected")
    notes: Optional[str] = None
    interview_date: Optional[datetime.datetime] = None


class ApplicationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    job_id: int
    status: str
    notes: Optional[str] = None
    interview_date: Optional[datetime.datetime] = None
    applied_date: datetime.datetime
    created_at: datetime.datetime
    updated_at: datetime.datetime
    job: Optional[JobResponse] = None


class ApplicationStatsResponse(BaseModel):
    total_applications: int
    saved: int
    applied: int
    interviews: int
    selected: int
    rejected: int
