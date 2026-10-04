from typing import Optional
from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username_or_email: str = Field(..., description="Username or Email address")
    password: str = Field(..., min_length=1, description="Password")


class RegisterRequest(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    email: str = Field(..., min_length=5, max_length=255)
    username: Optional[str] = None
    password: str = Field(..., min_length=6, max_length=100)


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: dict


class TokenData(BaseModel):
    user_id: Optional[int] = None
    email: Optional[str] = None
    role: Optional[str] = None
