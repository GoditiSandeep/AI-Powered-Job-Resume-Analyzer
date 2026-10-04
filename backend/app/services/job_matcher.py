import re
from typing import Dict, Any, List, Optional
from app.models.job import Job
from app.models.resume import ResumeAnalysis


class JobMatcher:
    """
    Dynamic Job Matching Engine.
    Calculates precise match percentage between a user's analyzed resume and a Job listing.
    """

    @staticmethod
    def calculate_match(job: Job, analysis: Optional[ResumeAnalysis]) -> Dict[str, Any]:
        if not analysis:
            return {
                "job_id": job.id,
                "job_title": job.title,
                "company": job.company,
                "overall_match_percentage": 0.0,
                "skill_match_score": 0.0,
                "keyword_match_score": 0.0,
                "experience_match_score": 0.0,
                "education_match_score": 0.0,
                "matched_skills": [],
                "missing_skills": job.required_skills or [],
                "match_reasons": ["Upload and analyze a resume to calculate your personalized job match."],
                "improvement_recommendations": ["Upload your latest resume to see skill alignment."],
            }

        # Extract user resume skills
        resume_skills_raw = analysis.skills or []
        user_skills_set = {
            s["name"].lower() if isinstance(s, dict) else str(s).lower()
            for s in resume_skills_raw
        }
        
        # Add detected keywords to skill set
        if analysis.detected_keywords:
            for kw in analysis.detected_keywords:
                user_skills_set.add(kw.lower())

        job_required = [s.strip() for s in (job.required_skills or []) if s.strip()]
        job_preferred = [s.strip() for s in (job.preferred_skills or []) if s.strip()]

        matched_skills = []
        missing_skills = []

        for req_skill in job_required:
            req_lower = req_skill.lower()
            if any(req_lower == u or req_lower in u or u in req_lower for u in user_skills_set):
                matched_skills.append(req_skill)
            else:
                missing_skills.append(req_skill)

        # 1. Skill Match Score (0 - 100)
        if job_required:
            skill_match_score = (len(matched_skills) / len(job_required)) * 100.0
        else:
            skill_match_score = 80.0

        # 2. Keyword Match Score (0 - 100)
        desc_lower = job.description.lower()
        keyword_hits = 0
        total_keywords_checked = max(1, len(user_skills_set))
        for u_skill in user_skills_set:
            if u_skill in desc_lower:
                keyword_hits += 1
        keyword_match_score = min(100.0, (keyword_hits / min(total_keywords_checked, 10)) * 100.0)

        # 3. Experience Match Score
        exp_score = 85.0
        if analysis.experience and len(analysis.experience) > 0:
            exp_score = min(100.0, 70.0 + len(analysis.experience) * 15.0)
        elif "senior" in job.title.lower() or "lead" in job.title.lower():
            exp_score = 45.0

        # 4. Education Match Score
        edu_score = 90.0 if analysis.education and len(analysis.education) > 0 else 60.0

        # Overall Weighted Score
        overall_match = (
            skill_match_score * 0.50 +
            keyword_match_score * 0.20 +
            exp_score * 0.20 +
            edu_score * 0.10
        )
        overall_match = max(15.0, min(99.0, overall_match))

        # Generate reasons and recommendations
        match_reasons = []
        if len(matched_skills) > 0:
            match_reasons.append(f"Strong match for core required skills: {', '.join(matched_skills[:4])}.")
        if keyword_match_score > 70.0:
            match_reasons.append(f"Resume text closely reflects the responsibilities and tech stack of {job.company}.")
        if exp_score >= 80.0:
            match_reasons.append("Your career experience timeline aligns well with this position.")

        improvement_recommendations = []
        if missing_skills:
            improvement_recommendations.append(f"Acquiring skills in {', '.join(missing_skills[:3])} will boost your match percentage significantly.")
        if keyword_match_score < 60.0:
            improvement_recommendations.append(f"Tailor your resume project descriptions to incorporate keywords from {job.title} job duties.")

        if not improvement_recommendations:
            improvement_recommendations.append("Your profile is exceptionally aligned! We recommend applying immediately.")

        return {
            "job_id": job.id,
            "job_title": job.title,
            "company": job.company,
            "overall_match_percentage": round(overall_match, 1),
            "skill_match_score": round(skill_match_score, 1),
            "keyword_match_score": round(keyword_match_score, 1),
            "experience_match_score": round(exp_score, 1),
            "education_match_score": round(edu_score, 1),
            "matched_skills": matched_skills,
            "missing_skills": missing_skills,
            "match_reasons": match_reasons,
            "improvement_recommendations": improvement_recommendations,
        }


job_matcher = JobMatcher()
