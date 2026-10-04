from app.ai.fallback_analyzer import fallback_analyzer


def test_fallback_analyzer_basic_extraction():
    sample_resume = """
    Jane Smith
    Email: jane.smith@demo.org
    Phone: +1 555 123 4567
    LinkedIn: linkedin.com/in/janesmith

    PROFESSIONAL SUMMARY
    Dynamic backend software engineer specialized in building high-throughput APIs.

    SKILLS
    Python, FastAPI, Docker, PostgreSQL, Redis, Kubernetes, Git, CI/CD.

    EXPERIENCE
    Software Engineer | DataCorp (2021 - 2024)
    - Architected asynchronous RESTful microservices, increasing throughput by 40%.
    - Automated deployment pipelines using GitHub Actions and Docker.

    PROJECTS
    Distributed Task Queue
    - Engineered Celery-based worker cluster with Redis backend.

    EDUCATION
    Bachelor of Science in Computer Science | 2021
    """

    result = fallback_analyzer.analyze(sample_resume)

    assert result["overall_score"] >= 75.0
    assert result["ats_score"] >= 75.0
    assert result["contact_info"]["email"] == "jane.smith@demo.org"
    assert result["contact_info"]["phone"] == "+1 555 123 4567"

    skill_names = [s["name"].lower() for s in result["skills"]]
    assert "python" in skill_names
    assert "fastapi" in skill_names
    assert "docker" in skill_names
    assert "postgresql" in skill_names

    assert len(result["strengths"]) > 0
    assert len(result["recommendations"]) > 0
    assert len(result["improvements"]) > 0


def test_fallback_analyzer_text_improvement():
    res = fallback_analyzer.improve_text(
        section="summary",
        original_text="I do programming and make websites.",
        role_target="Full Stack Engineer"
    )
    assert "Full Stack Engineer" in res["improved_text"]
    assert len(res["key_changes"]) >= 2
    assert res["impact_score_boost"] >= 15
