import io
from app.ai.fallback_analyzer import fallback_analyzer


def test_resume_analysis_endpoint(client, auth_headers):
    # Upload resume
    resume_content = b"""
    Godithi Sandeep
    Email: sandeep.goditi@example.com | Phone: +91 9876543210
    LinkedIn: linkedin.com/in/godithisandeep | GitHub: github.com/GoditiSandeep

    SUMMARY
    Senior Full Stack Engineer with 4+ years of expertise designing microservices with Python, FastAPI, and React.

    SKILLS
    Python, FastAPI, Django, React, PostgreSQL, Docker, Kubernetes, AWS, Git, CI/CD.

    EXPERIENCE
    Lead Software Engineer | TechCorp (2022 - Present)
    - Architected scalable backend handling 100k requests/sec, reducing latency by 45%.
    - Spearheaded microservices migration to AWS ECS.

    EDUCATION
    B.Tech Computer Science | 2022
    """
    files = {"file": ("analysis_test.txt", io.BytesIO(resume_content), "text/plain")}
    upload_res = client.post("/api/resumes/upload", headers=auth_headers, files=files)
    resume_id = upload_res.json()["id"]

    # Trigger targeted analysis
    analyze_payload = {
        "target_job_title": "Full Stack Developer",
        "target_job_description": "Looking for Python, FastAPI, React, and PostgreSQL experience."
    }
    response = client.post(f"/api/resumes/{resume_id}/analyze", headers=auth_headers, json=analyze_payload)
    assert response.status_code == 200
    data = response.json()

    assert data["overall_score"] > 60.0
    assert data["ats_score"] > 60.0
    assert "skills" in data
    assert len(data["skills"]) >= 5
    assert "section_scores" in data
    assert "Contact Information" in data["section_scores"]
    assert len(data["strengths"]) > 0
    assert len(data["recommendations"]) > 0


def test_resume_improve_text_endpoint(client, auth_headers):
    payload = {
        "section": "Professional Summary",
        "original_text": "Worked on python and website development.",
        "role_target": "Senior Python Developer"
    }
    response = client.post("/api/resumes/improve-text", headers=auth_headers, json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "improved_text" in data
    assert len(data["improved_text"]) > len(data["original_text"])
    assert data["impact_score_boost"] > 0
