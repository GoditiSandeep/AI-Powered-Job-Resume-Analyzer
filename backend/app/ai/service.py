import logging
from typing import Dict, Any, Optional
from app.ai.base import BaseResumeAnalyzer
from app.ai.fallback_analyzer import fallback_analyzer
from app.ai.llm_provider import llm_analyzer

logger = logging.getLogger(__name__)


class AIService(BaseResumeAnalyzer):
    """
    Main AI Service Orchestrator.
    Attempts primary LLM analysis if API key is provided, and gracefully defaults
    to deterministic FallbackAnalyzer on any error or when operating without API keys.
    """

    def analyze(
        self,
        resume_text: str,
        target_job_title: Optional[str] = None,
        target_job_description: Optional[str] = None,
        force_fallback: bool = False,
    ) -> Dict[str, Any]:
        if not force_fallback and llm_analyzer.is_configured():
            try:
                logger.info("Attempting AI LLM Resume Analysis...")
                result = llm_analyzer.analyze(
                    resume_text=resume_text,
                    target_job_title=target_job_title,
                    target_job_description=target_job_description,
                )
                # Verify required keys
                if "overall_score" in result and "ats_score" in result:
                    result["analysis_mode"] = "ai_llm"
                    return result
            except Exception as e:
                logger.warning(f"LLM analysis failed, falling back to deterministic analyzer: {e}")

        logger.info("Using Deterministic Fallback Resume Analyzer...")
        result = fallback_analyzer.analyze(
            resume_text=resume_text,
            target_job_title=target_job_title,
            target_job_description=target_job_description,
        )
        result["analysis_mode"] = "deterministic_fallback"
        return result

    def improve_text(
        self,
        section: str,
        original_text: str,
        role_target: Optional[str] = "Software Engineer",
        force_fallback: bool = False,
    ) -> Dict[str, Any]:
        if not force_fallback and llm_analyzer.is_configured():
            try:
                return llm_analyzer.improve_text(
                    section=section,
                    original_text=original_text,
                    role_target=role_target,
                )
            except Exception as e:
                logger.warning(f"LLM text improvement failed, using fallback: {e}")

        return fallback_analyzer.improve_text(
            section=section,
            original_text=original_text,
            role_target=role_target,
        )


ai_service = AIService()
