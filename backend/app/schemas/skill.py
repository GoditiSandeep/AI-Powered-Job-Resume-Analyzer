from typing import List, Optional, Dict
from pydantic import BaseModel, ConfigDict


class SkillBase(BaseModel):
    name: str
    category: str = "technical"


class SkillResponse(SkillBase):
    model_config = ConfigDict(from_attributes=True)

    id: int


class SkillGapRequest(BaseModel):
    target_role: str


class SkillGapResponse(BaseModel):
    target_role: str
    match_percentage: float
    matched_skills: List[str]
    missing_skills: List[str]
    high_priority: List[str]
    medium_priority: List[str]
    low_priority: List[str]
    learning_recommendations: List[Dict[str, str]]
