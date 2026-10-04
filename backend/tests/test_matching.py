import io


def test_job_match_calculation(client, auth_headers):
    # Upload resume with Python, FastAPI, Docker
    resume_content = b"""
    Godithi Sandeep
    Email: sandeep@demo.com
    Skills: Python, FastAPI, Docker, PostgreSQL, React, Git
    Experience: 3 years building web apps.
    Education: B.Tech CSE
    """
    files = {"file": ("match_resume.txt", io.BytesIO(resume_content), "text/plain")}
    client.post("/api/resumes/upload", headers=auth_headers, files=files)

    # Get a job id
    jobs = client.get("/api/jobs").json()
    target_job = [j for j in jobs if "Full Stack" in j["title"]][0]

    # Calculate match
    response = client.get(f"/api/jobs/{target_job['id']}/match", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()

    assert data["job_id"] == target_job["id"]
    assert data["overall_match_percentage"] > 50.0
    assert "matched_skills" in data
    assert len(data["matched_skills"]) > 0
    assert "improvement_recommendations" in data


def test_career_recommendations(client, auth_headers):
    # Upload resume
    resume_content = b"""
    Godithi Sandeep
    Email: sandeep@demo.com
    Skills: Python, FastAPI, PyTorch, Scikit-Learn, Docker, NLP
    """
    files = {"file": ("ml_resume.txt", io.BytesIO(resume_content), "text/plain")}
    client.post("/api/resumes/upload", headers=auth_headers, files=files)

    response = client.get("/api/recommendations", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()

    assert len(data) >= 5
    role_titles = [r["role_title"] for r in data]
    assert "AI/ML Engineer" in role_titles or "Python Developer" in role_titles
    assert data[0]["match_percentage"] > 40.0
