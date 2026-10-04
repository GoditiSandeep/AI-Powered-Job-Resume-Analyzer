import os
from typing import List, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "AI Powered Job & Resume Analyzer"
    PROJECT_OWNER: str = "Godithi Kiran Sri Sai Sandeep"
    VERSION: str = "1.0.0"
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    API_V1_STR: str = "/api"

    # Administrator
    ADMIN_USERNAME: str = "Godithi Sandeep"
    ADMIN_EMAIL: str = "admin@analyzer.local"
    ADMIN_PASSWORD: str = "Admin@Secure2026"

    # JWT
    JWT_SECRET: str = "super_secret_jwt_key_job_resume_analyzer_2026_change_in_production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days

    # Database
    DATABASE_URL: str = "sqlite:///./job_resume_analyzer.db"

    # AI Config
    AI_API_KEY: str = ""
    AI_BASE_URL: str = "https://api.openai.com/v1"
    AI_MODEL: str = "gpt-4o-mini"
    AI_TIMEOUT: int = 30

    # Uploads
    MAX_UPLOAD_SIZE_MB: int = 10
    UPLOAD_DIR: str = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "uploads")
    ALLOWED_EXTENSIONS: List[str] = ["pdf", "docx", "doc", "txt"]

    # CORS
    CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
        "*",
    ]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="allow",
    )


settings = Settings()

# Ensure uploads directory exists
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
