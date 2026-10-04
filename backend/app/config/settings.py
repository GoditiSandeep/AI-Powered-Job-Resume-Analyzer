import os
from typing import List
from pydantic import model_validator
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
    ADMIN_PASSWORD: str
    DEMO_USER_PASSWORD: str | None = None

    # JWT
    JWT_SECRET: str
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

    @model_validator(mode="after")
    def validate_production_configuration(self):
        if self.ENVIRONMENT.lower() not in {"production", "prod"}:
            return self

        if self.DEBUG:
            raise ValueError("DEBUG must be false in production.")
        if len(self.JWT_SECRET) < 32 or self.JWT_SECRET.startswith("CHANGE_THIS"):
            raise ValueError("Set JWT_SECRET to a unique random value of at least 32 characters.")
        if len(self.ADMIN_PASSWORD) < 12 or self.ADMIN_PASSWORD == "CHANGE_THIS_LOCALLY":
            raise ValueError("Set ADMIN_PASSWORD to a unique password of at least 12 characters.")
        if self.DEMO_USER_PASSWORD is not None:
            raise ValueError("Do not configure DEMO_USER_PASSWORD in production.")
        if self.ADMIN_EMAIL.endswith(".local") or "@" not in self.ADMIN_EMAIL:
            raise ValueError("Set ADMIN_EMAIL to a real email address in production.")
        if not self.DATABASE_URL.startswith(("postgres://", "postgresql://", "postgresql+psycopg://")):
            raise ValueError("Production requires a persistent PostgreSQL DATABASE_URL.")
        if any(
            origin == "*" or not origin.startswith("https://")
            for origin in self.CORS_ORIGINS
        ):
            raise ValueError("Production CORS_ORIGINS must contain only trusted HTTPS origins.")
        return self


settings = Settings()

# Ensure uploads directory exists
os.makedirs(settings.UPLOAD_DIR, exist_ok=True)
