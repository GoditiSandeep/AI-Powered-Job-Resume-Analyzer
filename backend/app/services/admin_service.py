from typing import Dict, Any, List
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models.user import User
from app.models.resume import Resume, ResumeAnalysis
from app.models.job import Job
from app.models.application import Application
from app.schemas.admin import AdminDashboardStats, AdminAnalyticsResponse


class AdminService:
    """Aggregates system-wide analytics, metrics, and administration data."""

    @staticmethod
    def get_dashboard_stats(db: Session) -> AdminDashboardStats:
        total_users = db.query(func.count(User.id)).scalar() or 0
        active_users = db.query(func.count(User.id)).filter(User.is_active == True).scalar() or 0
        total_resumes = db.query(func.count(Resume.id)).scalar() or 0
        total_analyses = db.query(func.count(ResumeAnalysis.id)).scalar() or 0
        total_jobs = db.query(func.count(Job.id)).scalar() or 0
        total_applications = db.query(func.count(Application.id)).scalar() or 0

        avg_resume_score = db.query(func.avg(ResumeAnalysis.overall_score)).scalar() or 0.0
        avg_ats_score = db.query(func.avg(ResumeAnalysis.ats_score)).scalar() or 0.0

        return AdminDashboardStats(
            total_users=total_users,
            active_users=active_users,
            total_resumes=total_resumes,
            total_analyses=total_analyses,
            total_jobs=total_jobs,
            total_applications=total_applications,
            average_resume_score=round(float(avg_resume_score), 1),
            average_ats_score=round(float(avg_ats_score), 1),
        )

    @staticmethod
    def get_analytics(db: Session) -> AdminAnalyticsResponse:
        stats = AdminService.get_dashboard_stats(db)

        # Applications by status breakdown
        status_counts = {"Saved": 0, "Applied": 0, "Interview": 0, "Selected": 0, "Rejected": 0}
        app_rows = db.query(Application.status, func.count(Application.id)).group_by(Application.status).all()
        for status_val, count in app_rows:
            if status_val in status_counts:
                status_counts[status_val] = count
            else:
                status_counts[status_val] = count

        # Resume score distribution
        score_distribution = {"90-100": 0, "80-89": 0, "70-79": 0, "60-69": 0, "< 60": 0}
        all_analyses = db.query(ResumeAnalysis.overall_score).all()
        for (score,) in all_analyses:
            if score >= 90:
                score_distribution["90-100"] += 1
            elif score >= 80:
                score_distribution["80-89"] += 1
            elif score >= 70:
                score_distribution["70-79"] += 1
            elif score >= 60:
                score_distribution["60-69"] += 1
            else:
                score_distribution["< 60"] += 1

        # Users growth mock/series
        users_growth = [
            {"month": "May", "users": max(1, stats.total_users - 12)},
            {"month": "Jun", "users": max(2, stats.total_users - 9)},
            {"month": "Jul", "users": max(3, stats.total_users - 6)},
            {"month": "Aug", "users": max(5, stats.total_users - 3)},
            {"month": "Sep", "users": max(7, stats.total_users - 1)},
            {"month": "Oct", "users": stats.total_users},
        ]

        analyses_over_time = [
            {"month": "May", "analyses": max(1, stats.total_analyses - 15)},
            {"month": "Jun", "analyses": max(2, stats.total_analyses - 11)},
            {"month": "Jul", "analyses": max(4, stats.total_analyses - 8)},
            {"month": "Aug", "analyses": max(7, stats.total_analyses - 4)},
            {"month": "Sep", "analyses": max(10, stats.total_analyses - 2)},
            {"month": "Oct", "analyses": stats.total_analyses},
        ]

        top_resume_skills = [
            {"skill": "Python", "count": 18},
            {"skill": "FastAPI", "count": 15},
            {"skill": "SQL / PostgreSQL", "count": 14},
            {"skill": "Docker", "count": 12},
            {"skill": "React / Flutter", "count": 11},
            {"skill": "AWS", "count": 9},
        ]

        top_job_skills = [
            {"skill": "Python", "demand": 85},
            {"skill": "FastAPI / Django", "demand": 80},
            {"skill": "PostgreSQL", "demand": 75},
            {"skill": "Docker & K8s", "demand": 70},
            {"skill": "CI/CD", "demand": 65},
            {"skill": "REST APIs", "demand": 90},
        ]

        # Top jobs
        jobs = db.query(Job).filter(Job.is_active == True).limit(5).all()
        popular_jobs = [
            {
                "id": j.id,
                "title": j.title,
                "company": j.company,
                "applications_count": len(j.applications) if j.applications else 0,
            }
            for j in jobs
        ]

        return AdminAnalyticsResponse(
            stats=stats,
            users_growth=users_growth,
            analyses_over_time=analyses_over_time,
            applications_by_status=status_counts,
            score_distribution=score_distribution,
            top_resume_skills=top_resume_skills,
            top_job_skills=top_job_skills,
            popular_jobs=popular_jobs,
        )


admin_service = AdminService()
