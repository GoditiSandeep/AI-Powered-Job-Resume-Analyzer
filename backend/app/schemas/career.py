from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class CareerRecommendationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: Optional[int] = None
    role_title: str
    match_percentage: float
    current_skills: List[str]
    required_skills: List[str]
    skill_gaps: List[str]
    next_steps: List[str]
    salary_range: Optional[str] = None
    demand_level: str = "High"
