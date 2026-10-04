def test_application_lifecycle(client, auth_headers):
    jobs = client.get("/api/jobs").json()
    job_id = jobs[0]["id"]

    # 1. Create Application
    create_payload = {
        "job_id": job_id,
        "status": "Applied",
        "notes": "Applied via company careers portal."
    }
    app_res = client.post("/api/applications", headers=auth_headers, json=create_payload)
    assert app_res.status_code == 201
    app_data = app_res.json()
    app_id = app_data["id"]
    assert app_data["status"] == "Applied"
    assert app_data["notes"] == "Applied via company careers portal."

    # 2. List Applications
    list_res = client.get("/api/applications", headers=auth_headers)
    assert list_res.status_code == 200
    assert any(a["id"] == app_id for a in list_res.json())

    # 3. Update Application Status to Interview
    update_payload = {
        "status": "Interview",
        "notes": "Technical screening scheduled."
    }
    update_res = client.put(f"/api/applications/{app_id}", headers=auth_headers, json=update_payload)
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "Interview"

    # 4. Check Stats
    stats_res = client.get("/api/applications/stats", headers=auth_headers)
    assert stats_res.status_code == 200
    stats = stats_res.json()
    assert stats["interviews"] >= 1

    # 5. Delete Application
    del_res = client.delete(f"/api/applications/{app_id}", headers=auth_headers)
    assert del_res.status_code == 200
