def test_list_jobs(client):
    response = client.get("/api/jobs")
    assert response.status_code == 200
    jobs = response.json()
    assert len(jobs) >= 10
    titles = [j["title"] for j in jobs]
    assert "Junior Software Developer" in titles
    assert "Full Stack Developer" in titles
    assert "AI/ML Engineer" in titles


def test_filter_jobs_by_search(client):
    response = client.get("/api/jobs?search=Python")
    assert response.status_code == 200
    jobs = response.json()
    assert len(jobs) >= 1
    assert any("Python" in j["title"] or "Python" in j["description"] for j in jobs)


def test_filter_jobs_by_location(client):
    response = client.get("/api/jobs?location=Remote")
    assert response.status_code == 200
    jobs = response.json()
    assert len(jobs) >= 1
    for j in jobs:
        assert "Remote" in j["location"]


def test_get_job_detail(client):
    list_res = client.get("/api/jobs")
    first_id = list_res.json()[0]["id"]

    response = client.get(f"/api/jobs/{first_id}")
    assert response.status_code == 200
    job = response.json()
    assert job["id"] == first_id
    assert "required_skills" in job
    assert len(job["responsibilities"]) > 0
