from fastapi import APIRouter
from app.config.settings import settings

router = APIRouter(tags=["Health"])


@router.get("/health")
def health_check():
    return {
        "status": "healthy",
        "project": settings.PROJECT_NAME,
        "owner": settings.PROJECT_OWNER,
        "version": settings.VERSION,
        "environment": settings.ENVIRONMENT,
    }
