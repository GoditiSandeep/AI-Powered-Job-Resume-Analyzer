def test_admin_dashboard_stats(client, admin_headers):
    response = client.get("/api/admin/dashboard", headers=admin_headers)
    assert response.status_code == 200
    data = response.json()
    assert "total_users" in data
    assert "total_jobs" in data
    assert "total_resumes" in data
    assert data["total_jobs"] >= 10


def test_admin_analytics(client, admin_headers):
    response = client.get("/api/admin/analytics", headers=admin_headers)
    assert response.status_code == 200
    data = response.json()
    assert "users_growth" in data
    assert "analyses_over_time" in data
    assert "score_distribution" in data
    assert "top_resume_skills" in data


def test_regular_user_access_admin_forbidden(client, auth_headers):
    response = client.get("/api/admin/dashboard", headers=auth_headers)
    assert response.status_code == 403
    assert "Administrator privileges required" in response.json()["detail"]


def test_admin_user_management(client, admin_headers):
    # List users
    users_res = client.get("/api/admin/users", headers=admin_headers)
    assert users_res.status_code == 200
    users = users_res.json()
    assert len(users) >= 1
    target_user = [u for u in users if u["role"] == "USER"][0]

    # Get user detail
    detail_res = client.get(f"/api/admin/users/{target_user['id']}", headers=admin_headers)
    assert detail_res.status_code == 200
    assert detail_res.json()["id"] == target_user["id"]

    # Toggle status
    patch_res = client.patch(
        f"/api/admin/users/{target_user['id']}/status",
        headers=admin_headers,
        json={"is_active": False}
    )
    assert patch_res.status_code == 200
    assert patch_res.json()["is_active"] is False

    # Restore status
    client.patch(
        f"/api/admin/users/{target_user['id']}/status",
        headers=admin_headers,
        json={"is_active": True}
    )


def test_admin_job_crud(client, admin_headers):
    job_payload = {
        "title": "Lead Cloud Architect",
        "company": "Enterprise Global",
        "location": "Remote",
        "salary": "₹30,00,000+",
        "employment_type": "Full-time",
        "experience": "7+ years",
        "description": "Architect enterprise cloud migration systems.",
        "responsibilities": ["Lead cloud architecture team."],
        "required_skills": ["AWS", "Kubernetes", "Terraform"],
        "preferred_skills": ["Python", "Go"],
    }
    create_res = client.post("/api/admin/jobs", headers=admin_headers, json=job_payload)
    assert create_res.status_code == 201
    job_id = create_res.json()["id"]

    # Update
    update_res = client.put(
        f"/api/admin/jobs/{job_id}",
        headers=admin_headers,
        json={"salary": "₹35,00,000+"}
    )
    assert update_res.status_code == 200
    assert update_res.json()["salary"] == "₹35,00,000+"

    # Delete
    del_res = client.delete(f"/api/admin/jobs/{job_id}", headers=admin_headers)
    assert del_res.status_code == 200
