def test_get_skills_library(client):
    response = client.get("/api/skills")
    assert response.status_code == 200
    skills = response.json()
    assert len(skills) >= 20
    names = [s["name"] for s in skills]
    assert "Python" in names
    assert "Docker" in names
    assert "FastAPI" in names


def test_skill_gap_analysis(client, auth_headers):
    payload = {"target_role": "Full Stack Developer"}
    response = client.post("/api/skills/gaps", headers=auth_headers, json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["target_role"] == "Full Stack Developer"
    assert "matched_skills" in data
    assert "missing_skills" in data
    assert "learning_recommendations" in data
