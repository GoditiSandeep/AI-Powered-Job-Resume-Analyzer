from app.routers.health import router as health_router
from app.routers.auth import router as auth_router
from app.routers.resumes import router as resumes_router
from app.routers.analysis import router as analysis_router
from app.routers.jobs import router as jobs_router
from app.routers.matching import router as matching_router
from app.routers.saved_jobs import router as saved_jobs_router
from app.routers.applications import router as applications_router
from app.routers.skills import router as skills_router
from app.routers.admin import router as admin_router

__all__ = [
    "health_router",
    "auth_router",
    "resumes_router",
    "analysis_router",
    "jobs_router",
    "matching_router",
    "saved_jobs_router",
    "applications_router",
    "skills_router",
    "admin_router",
]
