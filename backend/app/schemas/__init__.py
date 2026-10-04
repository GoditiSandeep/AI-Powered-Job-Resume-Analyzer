from app.schemas.auth import LoginRequest, RegisterRequest, TokenResponse, TokenData
from app.schemas.user import UserBase, UserCreate, UserUpdate, UserResponse, UserProfileResponse
from app.schemas.resume import ResumeBase, ResumeCreate, ResumeResponse, ResumeDetailResponse, ResumeAnalysisSummary
from app.schemas.analysis import AnalysisRequest, ResumeAnalysisResponse, ResumeImprovementRequest, ResumeImprovementResponse
from app.schemas.job import JobBase, JobCreate, JobUpdate, JobResponse, JobMatchResponse, SavedJobResponse
from app.schemas.application import ApplicationCreate, ApplicationUpdate, ApplicationResponse, ApplicationStatsResponse
from app.schemas.skill import SkillBase, SkillResponse, SkillGapRequest, SkillGapResponse
from app.schemas.career import CareerRecommendationResponse
from app.schemas.admin import AdminDashboardStats, AdminAnalyticsResponse, AdminUserStatusUpdate, AdminUserRoleUpdate

__all__ = [
    "LoginRequest",
    "RegisterRequest",
    "TokenResponse",
    "TokenData",
    "UserBase",
    "UserCreate",
    "UserUpdate",
    "UserResponse",
    "UserProfileResponse",
    "ResumeBase",
    "ResumeCreate",
    "ResumeResponse",
    "ResumeDetailResponse",
    "ResumeAnalysisSummary",
    "AnalysisRequest",
    "ResumeAnalysisResponse",
    "ResumeImprovementRequest",
    "ResumeImprovementResponse",
    "JobBase",
    "JobCreate",
    "JobUpdate",
    "JobResponse",
    "JobMatchResponse",
    "SavedJobResponse",
    "ApplicationCreate",
    "ApplicationUpdate",
    "ApplicationResponse",
    "ApplicationStatsResponse",
    "SkillBase",
    "SkillResponse",
    "SkillGapRequest",
    "SkillGapResponse",
    "CareerRecommendationResponse",
    "AdminDashboardStats",
    "AdminAnalyticsResponse",
    "AdminUserStatusUpdate",
    "AdminUserRoleUpdate",
]
