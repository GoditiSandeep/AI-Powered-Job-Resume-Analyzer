import httpx
import json
import os

def run_live_verification():
    base_url = "http://127.0.0.1:8000"
    client = httpx.Client(base_url=base_url, timeout=15.0)

    print("=== LIVE API VERIFICATION SUITE ===")
    
    # 1. Health
    print("\n1. Testing Health Endpoint...")
    r = client.get("/health")
    assert r.status_code == 200, f"Health check failed: {r.text}"
    health = r.json()
    print(f"Health Status: {health.get('status')} | Database: {health.get('database')}")

    # 2. Login
    print("\n2. Testing User Authentication (Demo User)...")
    r = client.post("/api/auth/login", json={
        "username_or_email": os.environ["DEMO_USER_EMAIL"],
        "password": os.environ["DEMO_USER_PASSWORD"],
    })
    assert r.status_code == 200, f"Login failed: {r.text}"
    auth_data = r.json()
    token = auth_data["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print(f"Authenticated as: {auth_data['user']['name']} ({auth_data['user']['email']}) | Role: {auth_data['user']['role']}")

    # 3. Profile
    print("\n3. Testing Get Current User Profile (/api/auth/me)...")
    r = client.get("/api/auth/me", headers=headers)
    assert r.status_code == 200, f"Get profile failed: {r.text}"
    profile = r.json()
    print(f"Profile retrieved successfully: {profile['name']} ({profile['email']})")

    # 4. Resumes List
    print("\n4. Testing List Resumes (/api/resumes)...")
    r = client.get("/api/resumes", headers=headers)
    assert r.status_code == 200, f"List resumes failed: {r.text}"
    existing_resumes = r.json()
    print(f"Found {len(existing_resumes)} existing resume(s).")

    # 5. Resume Upload & Extraction
    print("\n5. Testing Resume Upload and Text Extraction...")
    sample_resume = """
Jane Doe
Email: jane.doe@example.com
Phone: +1 555-0199
LinkedIn: linkedin.com/in/janedoe
GitHub: github.com/janedoe

PROFESSIONAL SUMMARY
Senior Full Stack Engineer with 5+ years of experience designing and scaling distributed systems with Python, FastAPI, React, PostgreSQL, Docker, and AWS. Architected microservices serving over 2M active users with 99.99% uptime.

TECHNICAL SKILLS
Languages: Python, JavaScript, TypeScript, SQL, Go
Frameworks: FastAPI, Django, React, Next.js, Node.js
Databases: PostgreSQL, Redis, MongoDB
Cloud & DevOps: AWS, Docker, Kubernetes, CI/CD, GitHub Actions

EXPERIENCE
Lead Software Engineer | CloudTech Solutions (2022 - Present)
- Architected and deployed microservices backend using FastAPI and PostgreSQL, improving throughput by 45%.
- Integrated Redis caching layer reducing API response latency from 320ms to 45ms.
- Mentored junior engineers and led Agile sprint ceremonies.

EDUCATION
B.S. in Computer Science | University of Technology (2016 - 2020)
"""
    files = {"file": ("jane_doe_live_test.txt", sample_resume.encode("utf-8"), "text/plain")}
    r = client.post("/api/resumes/upload", headers=headers, files=files)
    assert r.status_code == 201, f"Upload resume failed: {r.text}"
    uploaded = r.json()
    resume_id = uploaded["id"]
    analyses = uploaded.get("analyses", [])
    latest = analyses[0] if analyses else {}
    print(f"Upload Successful! Resume ID: {resume_id}")
    print(f"File Name: {uploaded.get('file_name')} | Size: {uploaded.get('file_size_bytes')} bytes")
    print(f"Initial Overall Score: {latest.get('overall_score')}/100")
    print(f"Initial ATS Score: {latest.get('ats_score')}/100")
    print(f"Analysis Mode: {latest.get('analysis_mode')}")

    # 6. Resume Analysis against Job Description
    print("\n6. Testing Resume Analysis against Target Job Description...")
    analyze_payload = {
        "target_job_title": "Senior Python Backend Architect",
        "target_job_description": "We are looking for a Senior Python Backend Architect with expertise in Python, FastAPI, PostgreSQL, Docker, Kubernetes, Microservices, and Cloud architecture."
    }
    r = client.post(f"/api/resumes/{resume_id}/analyze", headers=headers, json=analyze_payload)
    assert r.status_code == 200, f"Analyze resume failed: {r.text}"
    analysis_result = r.json()
    print(f"ATS Score with Target Job: {analysis_result.get('ats_score')}")
    print(f"Detected Keywords: {analysis_result.get('detected_keywords')}")
    print(f"Missing Keywords: {analysis_result.get('missing_keywords')}")
    print(f"Strengths ({len(analysis_result.get('strengths', []))}):")
    for s in analysis_result.get("strengths", [])[:3]:
        print(f"  + {s}")
    print(f"Weaknesses ({len(analysis_result.get('weaknesses', []))}):")
    for w in analysis_result.get("weaknesses", [])[:3]:
        print(f"  - {w}")
    print(f"Recommendations ({len(analysis_result.get('recommendations', []))}):")
    for rec in analysis_result.get("recommendations", [])[:3]:
        print(f"  * {rec}")

    # 7. Job Matching
    print("\n7. Testing Resume-to-Job Matching...")
    r = client.get("/api/jobs", headers=headers)
    assert r.status_code == 200, f"Get jobs failed: {r.text}"
    jobs = r.json()
    assert len(jobs) > 0, "No jobs available for matching"
    job_id = jobs[0]["id"]
    r = client.get(f"/api/jobs/{job_id}/match", headers=headers, params={"resume_id": resume_id})
    assert r.status_code == 200, f"Job match failed: {r.text}"
    match_result = r.json()
    print(f"Match for Job '{match_result.get('job_title')}' at '{match_result.get('company')}':")
    print(f"  Overall Match Score: {match_result.get('overall_match_percentage')}%")
    print(f"  Skills Match: {match_result.get('skill_match_score')}%")
    print(f"  Matched Skills: {match_result.get('matched_skills')}")
    print(f"  Missing Skills: {match_result.get('missing_skills')}")

    # 8. Skill Gap Analysis
    print("\n8. Testing Skill Gap Analysis (/api/skills/gaps)...")
    r = client.post("/api/skills/gaps", headers=headers, json={"target_role": "Backend Engineer"})
    assert r.status_code == 200, f"Skill gaps failed: {r.text}"
    gap_data = r.json()
    print(f"Role: {gap_data.get('target_role')} | Match: {gap_data.get('match_percentage')}%")
    print(f"Missing Critical Skills: {gap_data.get('missing_skills')}")
    print(f"Acquired Skills: {gap_data.get('acquired_skills')}")

    # 9. Career Recommendations
    print("\n9. Testing Career Path Recommendations (/api/recommendations)...")
    r = client.get("/api/recommendations", headers=headers)
    assert r.status_code == 200, f"Recommendations failed: {r.text}"
    recs = r.json()
    print(f"Generated {len(recs)} Career Recommendation(s):")
    for rec in recs[:3]:
        print(f"  * Role: {rec.get('role_title')} ({rec.get('match_percentage')}%) | Demand: {rec.get('demand_level')}")

    # 10. AI Text Improvement
    print("\n10. Testing AI Resume Improvement Assistant (/api/resumes/improve-text)...")
    improve_payload = {
        "section": "experience",
        "original_text": "helped with building database tables and wrote python scripts",
        "role_target": "Senior Backend Engineer"
    }
    r = client.post("/api/resumes/improve-text", headers=headers, json=improve_payload)
    assert r.status_code == 200, f"Text improvement failed: {r.text}"
    improved = r.json()
    print(f"Original Text: {improved.get('original_text')}")
    print(f"Improved Text: {improved.get('improved_text')}")

    # 11. Admin Dashboard & Analytics
    print("\n11. Testing Admin Dashboard & Analytics (/api/admin/dashboard & /api/admin/analytics)...")
    r_admin = client.post("/api/auth/login", json={
        "username_or_email": os.environ["ADMIN_EMAIL"],
        "password": os.environ["ADMIN_PASSWORD"],
    })
    assert r_admin.status_code == 200, f"Admin login failed: {r_admin.text}"
    admin_token = r_admin.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    
    r_dash = client.get("/api/admin/dashboard", headers=admin_headers)
    assert r_dash.status_code == 200, f"Admin dashboard failed: {r_dash.text}"
    dash_stats = r_dash.json()
    print(f"Admin Dashboard Stats: Users={dash_stats['total_users']}, Resumes={dash_stats['total_resumes']}, Jobs={dash_stats['total_jobs']}, Avg ATS={dash_stats['average_ats_score']}")

    r_analytics = client.get("/api/admin/analytics", headers=admin_headers)
    assert r_analytics.status_code == 200, f"Admin analytics failed: {r_analytics.text}"
    analytics = r_analytics.json()
    print(f"Admin Analytics: Top Job Skills={analytics.get('top_job_skills')[:5]}")
    print(f"Admin Analytics: Score Distribution={analytics.get('score_distribution')}")

    print("\n=======================================================")
    print("ALL 12 END-TO-END LIVE API VERIFICATION CHECKS PASSED!")
    print("=======================================================\n")

if __name__ == "__main__":
    run_live_verification()
