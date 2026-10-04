import io
from app.database.seed_data import DEMO_RESUME_TEXT


def test_complete_end_to_end_user_and_admin_workflow(client):
    # ========================================================
    # 1. USER WORKFLOW
    # ========================================================

    # A. Register new candidate
    candidate_email = "e2e.candidate@example.com"
    candidate_pass = "CandidatePass123!"
    reg_res = client.post("/api/auth/register", json={
        "name": "E2E Candidate",
        "email": candidate_email,
        "username": "e2e_candidate",
        "password": candidate_pass
    })
    assert reg_res.status_code == 201

    # B. Login
    login_res = client.post("/api/auth/login", json={
        "username_or_email": candidate_email,
        "password": candidate_pass
    })
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]
    user_headers = {"Authorization": f"Bearer {token}"}

    # C. Get Profile / Dashboard
    me_res = client.get("/api/auth/me", headers=user_headers)
    assert me_res.status_code == 200
    assert me_res.json()["email"] == candidate_email

    # D. Upload Demo Resume
    files = {"file": ("Godithi_Sandeep_Demo_Resume.txt", io.BytesIO(DEMO_RESUME_TEXT.encode("utf-8")), "text/plain")}
    upload_res = client.post("/api/resumes/upload", headers=user_headers, files=files)
    assert upload_res.status_code == 201
    resume_id = upload_res.json()["id"]

    # E. Run AI/Fallback Analysis
    analysis_res = client.post(
        f"/api/resumes/{resume_id}/analyze",
        headers=user_headers,
        json={"target_job_title": "Full Stack Developer"}
    )
    assert analysis_res.status_code == 200
    analysis = analysis_res.json()
    assert analysis["overall_score"] >= 70.0
    assert analysis["ats_score"] >= 70.0
    assert len(analysis["skills"]) >= 5

    # F. Check Skill Gaps
    gap_res = client.post("/api/skills/gaps", headers=user_headers, json={"target_role": "Full Stack Developer"})
    assert gap_res.status_code == 200
    assert gap_res.json()["target_role"] == "Full Stack Developer"

    # G. Get Career Recommendations
    recs_res = client.get("/api/recommendations", headers=user_headers)
    assert recs_res.status_code == 200
    assert len(recs_res.json()) >= 3

    # H. Browse Jobs
    jobs_res = client.get("/api/jobs", headers=user_headers)
    assert jobs_res.status_code == 200
    jobs = jobs_res.json()
    assert len(jobs) >= 10
    target_job = jobs[0]

    # I. Check Job Match
    match_res = client.get(f"/api/jobs/{target_job['id']}/match", headers=user_headers)
    assert match_res.status_code == 200
    match_data = match_res.json()
    assert match_data["overall_match_percentage"] > 0.0

    # J. Save Job
    save_res = client.post(f"/api/jobs/{target_job['id']}/save", headers=user_headers)
    assert save_res.status_code == 200
    assert save_res.json()["is_saved"] is True

    # K. Apply for Job
    apply_res = client.post("/api/applications", headers=user_headers, json={
        "job_id": target_job["id"],
        "status": "Applied",
        "notes": "E2E test application"
    })
    assert apply_res.status_code == 201
    app_id = apply_res.json()["id"]

    # L. Update Application Status
    update_res = client.put(f"/api/applications/{app_id}", headers=user_headers, json={
        "status": "Interview",
        "notes": "Technical round completed successfully."
    })
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "Interview"

    # M. Logout
    logout_res = client.post("/api/auth/logout", headers=user_headers)
    assert logout_res.status_code == 200

    # ========================================================
    # 2. ADMIN WORKFLOW
    # ========================================================

    # A. Login as Admin
    admin_login = client.post("/api/auth/login", json={
        "username_or_email": "admin@analyzer.local",
        "password": "TestAdminPass2026!"
    })
    assert admin_login.status_code == 200
    admin_token = admin_login.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    # B. Inspect Admin Dashboard
    dash_res = client.get("/api/admin/dashboard", headers=admin_headers)
    assert dash_res.status_code == 200
    assert dash_res.json()["total_users"] >= 2
    assert dash_res.json()["total_applications"] >= 1

    # C. Inspect Analytics
    analytics_res = client.get("/api/admin/analytics", headers=admin_headers)
    assert analytics_res.status_code == 200
    assert "users_growth" in analytics_res.json()

    # D. View Users
    users_list = client.get("/api/admin/users", headers=admin_headers)
    assert users_list.status_code == 200
    assert len(users_list.json()) >= 2

    # E. Admin Job CRUD
    create_job_res = client.post("/api/admin/jobs", headers=admin_headers, json={
        "title": "Principal Architect",
        "company": "Scale Cloud Inc",
        "location": "Remote",
        "salary": "₹45,00,000+",
        "employment_type": "Full-time",
        "experience": "8+ years",
        "description": "Lead enterprise system architectures.",
        "responsibilities": ["Lead tech strategy."],
        "required_skills": ["Python", "FastAPI", "Kubernetes", "AWS"],
        "preferred_skills": ["Docker", "PostgreSQL"],
    })
    assert create_job_res.status_code == 201
    new_job_id = create_job_res.json()["id"]

    # Delete test job
    del_job_res = client.delete(f"/api/admin/jobs/{new_job_id}", headers=admin_headers)
    assert del_job_res.status_code == 200

    # F. Admin Logout
    admin_logout = client.post("/api/auth/logout", headers=admin_headers)
    assert admin_logout.status_code == 200
