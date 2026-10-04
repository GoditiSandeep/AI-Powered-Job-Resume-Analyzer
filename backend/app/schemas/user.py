import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class UserBase(BaseModel):
    name: str
    email: str
    username: Optional[str] = None
    title: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None


class UserCreate(UserBase):
    password: str
    role: Optional[str] = "USER"


class UserUpdate(BaseModel):
    name: Optional[str] = None
    username: Optional[str] = None
    title: Optional[str] = None
    location: Optional[str] = None
    bio: Optional[str] = None
    password: Optional[str] = None


class UserResponse(UserBase):
    model_config = ConfigDict(from_attributes=True)

    id: int
    role: str
    is_active: bool
    created_at: datetime.datetime
    updated_at: datetime.datetime


class UserProfileResponse(UserResponse):
    model_config = ConfigDict(from_attributes=True)

    resumes_count: int = 0
    applications_count: int = 0
    saved_jobs_count: int = 0
    latest_resume_score: Optional[float] = None
    latest_ats_score: Optional[float] = None
