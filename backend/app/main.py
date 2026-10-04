import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError

from app.config.settings import settings
from app.database.init_db import init_db
from app.routers import (
    health_router,
    auth_router,
    saved_jobs_router,
    jobs_router,
    resumes_router,
    analysis_router,
    matching_router,
    applications_router,
    skills_router,
    admin_router,
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("job_resume_analyzer")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Initializing application database and seed fixtures...")
    init_db()
    logger.info(f"{settings.PROJECT_NAME} initialized successfully.")
    yield
    logger.info("Application shutdown.")


app = FastAPI(
    title=settings.PROJECT_NAME,
    description=(
        "AI-Powered Job & Resume Analyzer API. "
        "Provides end-to-end resume text extraction, dynamic ATS & resume scoring, "
        "intelligent job matching, career path recommendations, skill gap analysis, "
        "job application tracking, and an administrative management portal.\n\n"
        f"**Project Owner**: {settings.PROJECT_OWNER}"
    ),
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Exception handlers
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = []
    for err in exc.errors():
        loc = " -> ".join([str(l) for l in err.get("loc", [])])
        msg = err.get("msg", "Validation error")
        errors.append(f"{loc}: {msg}")
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "Validation Error",
            "detail": errors,
            "message": "Invalid request payload format."
        }
    )


# Include all routers (ordered for URL precedence)
app.include_router(health_router)
app.include_router(health_router, prefix=settings.API_V1_STR)
app.include_router(auth_router)
app.include_router(saved_jobs_router)
app.include_router(jobs_router)
app.include_router(resumes_router)
app.include_router(analysis_router)
app.include_router(matching_router)
app.include_router(applications_router)
app.include_router(skills_router)
app.include_router(admin_router)

# Mount frontend web build if available
frontend_build_dir = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "frontend",
    "build",
    "web"
)

if os.path.exists(frontend_build_dir):
    from fastapi.staticfiles import StaticFiles
    app.mount("/app", StaticFiles(directory=frontend_build_dir, html=True), name="frontend_web")
    logger.info(f"Mounted Flutter web application at /app from {frontend_build_dir}")


@app.get("/")
def root():
    return {
        "message": f"Welcome to {settings.PROJECT_NAME} API",
        "owner": settings.PROJECT_OWNER,
        "docs": "/docs",
        "health": "/health",
        "web_app": "/app" if os.path.exists(frontend_build_dir) else None,
        "status": "operational"
    }
