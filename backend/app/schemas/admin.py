import datetime
from typing import List, Dict, Any, Optional
from pydantic import BaseModel


class AdminUserStatusUpdate(BaseModel):
    is_active: bool


class AdminUserRoleUpdate(BaseModel):
    role: str  # USER, ADMIN


class AdminDashboardStats(BaseModel):
    total_users: int
    active_users: int
    total_resumes: int
    total_analyses: int
    total_jobs: int
    total_applications: int
    average_resume_score: float
    average_ats_score: float


class AdminAnalyticsResponse(BaseModel):
    stats: AdminDashboardStats
    users_growth: List[Dict[str, Any]]
    analyses_over_time: List[Dict[str, Any]]
    applications_by_status: Dict[str, int]
    score_distribution: Dict[str, int]
    top_resume_skills: List[Dict[str, Any]]
    top_job_skills: List[Dict[str, Any]]
    popular_jobs: List[Dict[str, Any]]
