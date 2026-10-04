import io


def test_upload_resume_txt_success(client, auth_headers):
    resume_content = b"""
    Godithi Kiran Sri Sai Sandeep
    Email: sandeep.test@example.com | Phone: +91 9876543210
    Technical Skills: Python, FastAPI, React, PostgreSQL, Docker, Git.
    Education: B.Tech in Computer Science, 2024.
    Experience: Software Engineer Intern at CloudTech. Developed REST APIs and microservices.
    Projects: AI Powered Job & Resume Analyzer.
    """
    files = {"file": ("test_resume.txt", io.BytesIO(resume_content), "text/plain")}
    response = client.post("/api/resumes/upload", headers=auth_headers, files=files)
    assert response.status_code == 201
    data = response.json()
    assert data["file_name"] == "test_resume.txt"
    assert "Python" in data["extracted_text"]


def test_upload_empty_resume_fails(client, auth_headers):
    files = {"file": ("empty.txt", io.BytesIO(b""), "text/plain")}
    response = client.post("/api/resumes/upload", headers=auth_headers, files=files)
    assert response.status_code == 400
    assert "empty" in response.json()["detail"].lower()


def test_upload_invalid_file_extension_fails(client, auth_headers):
    files = {"file": ("malicious.exe", io.BytesIO(b"fake payload"), "application/octet-stream")}
    response = client.post("/api/resumes/upload", headers=auth_headers, files=files)
    assert response.status_code == 400
    assert "unsupported file format" in response.json()["detail"].lower()


def test_list_resumes(client, auth_headers):
    # Upload one first
    resume_content = b"Candidate Name\nEmail: candidate@test.com\nSkills: Python, SQL"
    files = {"file": ("resume_list_test.txt", io.BytesIO(resume_content), "text/plain")}
    client.post("/api/resumes/upload", headers=auth_headers, files=files)

    response = client.get("/api/resumes", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 1


def test_delete_resume(client, auth_headers):
    resume_content = b"Candidate Name\nEmail: todelete@test.com\nSkills: Python"
    files = {"file": ("resume_to_delete.txt", io.BytesIO(resume_content), "text/plain")}
    up_res = client.post("/api/resumes/upload", headers=auth_headers, files=files)
    resume_id = up_res.json()["id"]

    del_res = client.delete(f"/api/resumes/{resume_id}", headers=auth_headers)
    assert del_res.status_code == 200
    assert del_res.json()["id"] == resume_id
