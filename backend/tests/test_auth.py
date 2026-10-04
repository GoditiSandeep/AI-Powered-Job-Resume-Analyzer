def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "Godithi Kiran Sri Sai Sandeep" in data["owner"]


def test_user_registration(client):
    payload = {
        "name": "Jane Doe",
        "email": "jane.doe@example.com",
        "username": "janedoe",
        "password": "SecurePassword123!"
    }
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "jane.doe@example.com"


def test_duplicate_registration_fails(client):
    payload = {
        "name": "Alex Duplicate",
        "email": "demo@analyzer.local",  # Already seeded
        "password": "Password123!"
    }
    response = client.post("/api/auth/register", json=payload)
    assert response.status_code == 400
    assert "already exists" in response.json()["detail"]


def test_user_login_success(client):
    payload = {
        "username_or_email": "demo@analyzer.local",
        "password": "DemoUser123!"
    }
    response = client.post("/api/auth/login", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["user"]["email"] == "demo@analyzer.local"


def test_user_login_invalid_password(client):
    payload = {
        "username_or_email": "demo@analyzer.local",
        "password": "WrongPassword!"
    }
    response = client.post("/api/auth/login", json=payload)
    assert response.status_code == 401
    assert "Invalid email/username or password" in response.json()["detail"]


def test_get_current_user_profile(client, auth_headers):
    response = client.get("/api/auth/me", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "testuser@example.com"
    assert "resumes_count" in data
