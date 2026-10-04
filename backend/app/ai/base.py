from abc import ABC, abstractmethod
from typing import Dict, Any, Optional


class BaseResumeAnalyzer(ABC):
    """Abstract interface for resume analysis implementations."""

    @abstractmethod
    def analyze(
        self,
        resume_text: str,
        target_job_title: Optional[str] = None,
        target_job_description: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Perform comprehensive resume analysis and return a structured dictionary matching ResumeAnalysisResponse schema."""
        pass

    @abstractmethod
    def improve_text(
        self,
        section: str,
        original_text: str,
        role_target: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Generate high-impact before/after rewrite of a resume section."""
        pass
