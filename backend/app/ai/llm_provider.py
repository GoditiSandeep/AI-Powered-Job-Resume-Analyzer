import json
import re
from typing import Dict, Any, Optional
import httpx
from app.config.settings import settings
from app.ai.base import BaseResumeAnalyzer
from app.ai.prompts import RESUME_ANALYSIS_SYSTEM_PROMPT, RESUME_IMPROVEMENT_SYSTEM_PROMPT


class LLMResumeAnalyzer(BaseResumeAnalyzer):
    """
    OpenAI-compatible LLM Resume Analyzer client.
    Supports any standard LLM provider via configurable base URL, API key, and model.
    """

    def __init__(self):
        self.api_key = settings.AI_API_KEY
        self.base_url = settings.AI_BASE_URL.rstrip("/")
        self.model = settings.AI_MODEL
        self.timeout = settings.AI_TIMEOUT

    def is_configured(self) -> bool:
        return bool(self.api_key and len(self.api_key.strip()) > 5)

    def analyze(
        self,
        resume_text: str,
        target_job_title: Optional[str] = None,
        target_job_description: Optional[str] = None,
    ) -> Dict[str, Any]:
        if not self.is_configured():
            raise ValueError("LLM provider is not configured with a valid AI_API_KEY.")

        user_content = f"RESUME TEXT:\n{resume_text}\n\n"
        if target_job_title:
            user_content += f"TARGET JOB TITLE: {target_job_title}\n"
        if target_job_description:
            user_content += f"TARGET JOB DESCRIPTION:\n{target_job_description}\n"

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": RESUME_ANALYSIS_SYSTEM_PROMPT},
                {"role": "user", "content": user_content},
            ],
            "temperature": 0.2,
            "response_format": {"type": "json_object"} if "gpt" in self.model else None,
        }

        with httpx.Client(timeout=self.timeout) as client:
            response = client.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload,
            )
            response.raise_for_status()
            data = response.json()
            content = data["choices"][0]["message"]["content"].strip()

            # Clean markdown wrappers if any
            if content.startswith("```"):
                content = re.sub(r"^```(?:json)?\n?", "", content)
                content = re.sub(r"\n?```$", "", content)

            parsed = json.loads(content)
            parsed["analysis_mode"] = "ai_llm"
            return parsed

    def improve_text(
        self,
        section: str,
        original_text: str,
        role_target: Optional[str] = "Software Engineer",
    ) -> Dict[str, Any]:
        if not self.is_configured():
            raise ValueError("LLM provider is not configured with a valid AI_API_KEY.")

        prompt = f"Section: {section}\nTarget Role: {role_target}\nOriginal Text: {original_text}"

        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }

        payload = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": RESUME_IMPROVEMENT_SYSTEM_PROMPT},
                {"role": "user", "content": prompt},
            ],
            "temperature": 0.3,
        }

        with httpx.Client(timeout=self.timeout) as client:
            response = client.post(
                f"{self.base_url}/chat/completions",
                headers=headers,
                json=payload,
            )
            response.raise_for_status()
            data = response.json()
            content = data["choices"][0]["message"]["content"].strip()
            if content.startswith("```"):
                content = re.sub(r"^```(?:json)?\n?", "", content)
                content = re.sub(r"\n?```$", "", content)
            return json.loads(content)


llm_analyzer = LLMResumeAnalyzer()
