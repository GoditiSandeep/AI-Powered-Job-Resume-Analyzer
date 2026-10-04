def test_save_and_unsave_job(client, auth_headers):
    jobs = client.get("/api/jobs").json()
    job_id = jobs[0]["id"]

    # Save
    save_res = client.post(f"/api/jobs/{job_id}/save", headers=auth_headers)
    assert save_res.status_code == 200
    assert save_res.json()["is_saved"] is True

    # List saved
    list_saved = client.get("/api/jobs/saved", headers=auth_headers)
    assert list_saved.status_code == 200
    saved_jobs = list_saved.json()
    assert any(j["id"] == job_id for j in saved_jobs)

    # Unsave
    unsave_res = client.delete(f"/api/jobs/{job_id}/save", headers=auth_headers)
    assert unsave_res.status_code == 200
    assert unsave_res.json()["is_saved"] is False

    # List saved again
    list_saved_after = client.get("/api/jobs/saved", headers=auth_headers)
    assert not any(j["id"] == job_id for j in list_saved_after.json())
