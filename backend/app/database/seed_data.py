import logging
from sqlalchemy.orm import Session
from app.config.settings import settings
from app.models.user import User
from app.models.job import Job
from app.models.skill import Skill
from app.models.resume import Resume, ResumeAnalysis
from app.auth.security import get_password_hash
from app.ai.service import ai_service

logger = logging.getLogger(__name__)

INITIAL_SKILLS = [
    ("Python", "programming"),
    ("JavaScript", "programming"),
    ("TypeScript", "programming"),
    ("Java", "programming"),
    ("Dart", "programming"),
    ("C++", "programming"),
    ("SQL", "programming"),
    ("FastAPI", "framework"),
    ("Django", "framework"),
    ("Flask", "framework"),
    ("React", "framework"),
    ("Flutter", "framework"),
    ("Next.js", "framework"),
    ("Spring Boot", "framework"),
    ("PostgreSQL", "database"),
    ("MySQL", "database"),
    ("MongoDB", "database"),
    ("Redis", "database"),
    ("SQLite", "database"),
    ("Docker", "cloud"),
    ("Kubernetes", "cloud"),
    ("AWS", "cloud"),
    ("GCP", "cloud"),
    ("Azure", "cloud"),
    ("CI/CD", "cloud"),
    ("Git", "tools"),
    ("GitHub Actions", "tools"),
    ("PyTest", "tools"),
    ("REST API", "architecture"),
    ("Microservices", "architecture"),
    ("Leadership", "soft_skill"),
    ("Problem Solving", "soft_skill"),
    ("Agile/Scrum", "soft_skill"),
]

INITIAL_JOBS = [
    {
        "title": "Junior Software Developer",
        "company": "NextGen Technologies",
        "location": "Bangalore, India (Hybrid)",
        "salary": "₹6,00,000 - ₹9,00,000",
        "employment_type": "Full-time",
        "experience": "0-2 years",
        "description": "We are seeking a proactive Junior Software Developer to join our core engineering team. You will write clean, testable code, participate in code reviews, and build RESTful API services and interactive user interfaces.",
        "responsibilities": [
            "Develop robust backend API endpoints and user-facing features.",
            "Write unit tests and ensure clean code quality standards.",
            "Collaborate with senior developers, QA, and product managers.",
            "Debug issues and optimize application performance."
        ],
        "required_skills": ["Python", "JavaScript", "SQL", "Git", "REST API"],
        "preferred_skills": ["FastAPI", "React", "Docker", "PostgreSQL"],
    },
    {
        "title": "Full Stack Developer",
        "company": "CloudSphere Innovations",
        "location": "Hyderabad, India (Remote)",
        "salary": "₹12,00,000 - ₹18,00,000",
        "employment_type": "Full-time",
        "experience": "2-4 years",
        "description": "Looking for an experienced Full Stack Developer to build and scale modern cloud-native web applications. You will be responsible for end-to-end feature delivery, from database schema design to responsive frontend interfaces.",
        "responsibilities": [
            "Architect and develop scalable web applications and microservices.",
            "Build responsive, modern UI components with React or Flutter.",
            "Design PostgreSQL relational databases and write optimized SQL queries.",
            "Deploy containerized workloads using Docker and GitHub Actions CI/CD."
        ],
        "required_skills": ["Python", "FastAPI", "React", "PostgreSQL", "Docker", "Git"],
        "preferred_skills": ["TypeScript", "Redis", "AWS", "CI/CD"],
    },
    {
        "title": "Backend Developer",
        "company": "Apex Financial Systems",
        "location": "Mumbai, India (On-site)",
        "salary": "₹14,00,000 - ₹20,00,000",
        "employment_type": "Full-time",
        "experience": "3-5 years",
        "description": "Join our mission-critical fintech infrastructure team to engineer high-concurrency, low-latency transaction processing microservices with enterprise-grade reliability and security.",
        "responsibilities": [
            "Design and maintain distributed backend microservices.",
            "Implement secure OAuth2/JWT authentication and role-based access control.",
            "Optimize PostgreSQL and Redis database performance and query plans.",
            "Conduct automated performance, load, and security testing."
        ],
        "required_skills": ["Python", "FastAPI", "PostgreSQL", "Redis", "Docker", "Microservices"],
        "preferred_skills": ["Kubernetes", "AWS", "Kafka", "PyTest"],
    },
    {
        "title": "Frontend Developer",
        "company": "PixelCraft Studio",
        "location": "Bangalore, India (Hybrid)",
        "salary": "₹10,00,000 - ₹15,00,000",
        "employment_type": "Full-time",
        "experience": "2-4 years",
        "description": "Create pixel-perfect, intuitive, and responsive user experiences for our global SaaS platform. You will implement modern design systems, clean animations, and state management architectures.",
        "responsibilities": [
            "Build responsive client-facing applications using Flutter and React.",
            "Collaborate closely with UI/UX designers to implement Material 3 design systems.",
            "Integrate RESTful and WebSocket APIs for real-time dashboard data.",
            "Ensure cross-browser and cross-device performance optimization."
        ],
        "required_skills": ["JavaScript", "TypeScript", "React", "HTML", "CSS", "Responsive Design"],
        "preferred_skills": ["Flutter", "Tailwind", "Next.js", "Figma"],
    },
    {
        "title": "Python Developer",
        "company": "DataVibe Analytics",
        "location": "Pune, India (Remote)",
        "salary": "₹11,00,000 - ₹16,00,000",
        "employment_type": "Full-time",
        "experience": "2-4 years",
        "description": "Develop data ingestion pipelines, async REST APIs, and automated processing services in Python. You will work on high-throughput backend services and algorithmic data transformations.",
        "responsibilities": [
            "Develop asynchronous REST APIs using FastAPI and Pydantic.",
            "Write robust ETL scripts and database data cleaning pipelines.",
            "Implement automated testing suites with PyTest and achieve >90% coverage.",
            "Maintain Dockerized environments for reproducible local and cloud deployment."
        ],
        "required_skills": ["Python", "FastAPI", "SQL", "PostgreSQL", "Git", "PyTest"],
        "preferred_skills": ["Docker", "Pandas", "Celery", "Redis"],
    },
    {
        "title": "Java Developer",
        "company": "Enterprise Tech Solutions",
        "location": "Chennai, India (Hybrid)",
        "salary": "₹11,00,000 - ₹17,00,000",
        "employment_type": "Full-time",
        "experience": "3-5 years",
        "description": "Looking for a seasoned Java Developer to design and develop enterprise microservices with Spring Boot, JPA/Hibernate, and scalable relational databases.",
        "responsibilities": [
            "Develop enterprise-scale backend services using Spring Boot and Java.",
            "Integrate relational databases with Hibernate/JPA and ensure data consistency.",
            "Write comprehensive JUnit test cases and maintain build automation with Maven.",
            "Participate in sprint planning, code reviews, and architecture discussions."
        ],
        "required_skills": ["Java", "Spring Boot", "SQL", "PostgreSQL", "Git", "Microservices"],
        "preferred_skills": ["Docker", "AWS", "Hibernate", "Maven"],
    },
    {
        "title": "Data Analyst",
        "company": "InsightIQ Labs",
        "location": "Gurgaon, India (Hybrid)",
        "salary": "₹8,00,000 - ₹12,00,000",
        "employment_type": "Full-time",
        "experience": "1-3 years",
        "description": "Transform complex business datasets into clear actionable insights and interactive executive dashboards. You will work with SQL, Python, and data visualization tools.",
        "responsibilities": [
            "Query, aggregate, and analyze large transactional datasets using SQL.",
            "Build interactive dashboards and visualizations with Tableau / PowerBI.",
            "Clean and preprocess structured datasets using Python and Pandas.",
            "Present analytical findings and KPI reports to business stakeholders."
        ],
        "required_skills": ["SQL", "Python", "Pandas", "Data Visualization"],
        "preferred_skills": ["Tableau", "PowerBI", "PostgreSQL", "Statistics"],
    },
    {
        "title": "AI/ML Engineer",
        "company": "NeuralMind Systems",
        "location": "Bangalore, India (Remote)",
        "salary": "₹16,00,000 - ₹25,00,000",
        "employment_type": "Full-time",
        "experience": "2-5 years",
        "description": "Design and deploy machine learning models, LLM pipelines, and NLP systems into low-latency production APIs. You will work on cutting-edge intelligent automation solutions.",
        "responsibilities": [
            "Develop, train, and evaluate NLP and deep learning models with PyTorch.",
            "Deploy inference microservices using FastAPI and Docker.",
            "Build Retrieval-Augmented Generation (RAG) pipelines and embeddings search.",
            "Monitor model performance, latency, and drift in production."
        ],
        "required_skills": ["Python", "PyTorch", "NLP", "FastAPI", "Docker", "Git"],
        "preferred_skills": ["TensorFlow", "Scikit-Learn", "PostgreSQL", "AWS"],
    },
    {
        "title": "Cloud & DevOps Engineer",
        "company": "ScaleOps Cloud",
        "location": "Hyderabad, India (Remote)",
        "salary": "₹15,00,000 - ₹22,00,000",
        "employment_type": "Full-time",
        "experience": "3-5 years",
        "description": "Automate cloud infrastructure provisioning, maintain high-availability Kubernetes clusters, and build robust zero-downtime CI/CD deployment pipelines.",
        "responsibilities": [
            "Manage AWS/GCP cloud resources using Terraform Infrastructure as Code (IaC).",
            "Maintain containerized workloads with Kubernetes and Docker.",
            "Build and optimize GitHub Actions and GitLab CI/CD workflows.",
            "Configure monitoring, log aggregation, and alerting with Prometheus and Grafana."
        ],
        "required_skills": ["AWS", "Docker", "Kubernetes", "CI/CD", "Linux", "Git"],
        "preferred_skills": ["Terraform", "GCP", "GitHub Actions", "Python"],
    },
    {
        "title": "React Developer",
        "company": "AppForge Digital",
        "location": "Kochi, India (Remote)",
        "salary": "₹9,00,000 - ₹14,00,000",
        "employment_type": "Full-time",
        "experience": "2-4 years",
        "description": "Build high-speed, modern web interfaces with React, TypeScript, and modern CSS frameworks. You will work closely with product teams to deliver intuitive user workflows.",
        "responsibilities": [
            "Develop responsive web applications with React.js and TypeScript.",
            "Manage application state with Redux Toolkit or React Query.",
            "Optimize frontend asset delivery, bundle size, and render performance.",
            "Write component unit tests with Jest and React Testing Library."
        ],
        "required_skills": ["JavaScript", "TypeScript", "React", "HTML", "CSS", "Git"],
        "preferred_skills": ["Next.js", "Tailwind", "REST API", "Jest"],
    },
]

DEMO_RESUME_TEXT = """
GODITHI KIRAN SRI SAI SANDEEP
Email: sandeep.goditi@demo.example.com | Phone: +91 98765 43210 | Location: Visakhapatnam, Andhra Pradesh, India
LinkedIn: linkedin.com/in/godithisandeep | GitHub: github.com/GoditiSandeep | Portfolio: sandeep-dev.site

PROFESSIONAL SUMMARY
Passionate and results-driven Software Engineer with strong expertise in Python, FastAPI, Flutter, and Full-Stack Application Development. Proven ability to architect scalable RESTful microservices, design relational databases, and build responsive cross-platform user interfaces. Experienced with Docker containerization, CI/CD pipelines, and AI-driven automation systems.

EDUCATION
Bachelor of Technology in Computer Science & Engineering
Engineering Institute of Technology, Visakhapatnam
Graduation Year: 2024 | CGPA: 8.8 / 10.0

TECHNICAL SKILLS
- Programming Languages: Python, Dart, JavaScript, SQL, C++
- Frameworks & Libraries: FastAPI, Flutter, React, Django, Pydantic, SQLAlchemy
- Databases: PostgreSQL, SQLite, Redis, MongoDB
- Cloud & DevOps: Docker, Git, GitHub Actions, AWS (S3, EC2), Linux
- Core Competencies: REST API Design, Microservices, System Architecture, Agile/Scrum, Problem Solving

KEY PROJECTS
AI Powered Job & Resume Analyzer
- Architected an end-to-end full-stack career platform utilizing FastAPI, Flutter Material 3, and PostgreSQL.
- Implemented real-time ATS compatibility scoring, skill gap identification, and dynamic job matching algorithms.
- Integrated dual-mode AI analysis featuring OpenAI-compatible LLM orchestration with an offline deterministic rule-based NLP fallback engine.
- Containerized the full application stack using Docker Compose, reducing local deployment onboarding time by 50%.

Full Stack Task Management & Analytics Portal
- Engineered a responsive web application using React, Python FastAPI, and PostgreSQL with JWT-based role authentication.
- Optimized database indexing and query latency, achieving a 40% reduction in average API response time.
- Designed automated CI/CD workflows using GitHub Actions for continuous linting, unit testing, and deployment.

INTERNSHIP & EXPERIENCE
Software Engineering Intern | CloudTech Solutions
Duration: June 2023 - December 2023 | Location: Hyderabad, India
- Collaborated in an Agile engineering team to build scalable REST API microservices handling 50,000+ daily requests.
- Developed automated PyTest test suites, increasing backend code test coverage from 65% to 92%.
- Streamlined database migrations and ORM models using SQLAlchemy and Alembic.

CERTIFICATIONS
- AWS Certified Cloud Practitioner - Amazon Web Services
- Python for Data Science and Machine Learning - Coursera
- Full-Stack Web Development Specialization - Meta

ACHIEVEMENTS & AWARDS
- 1st Place Winner, National University Hackathon 2023 (Smart Automation Track).
- Solved 400+ algorithmic data structures and algorithms challenges across LeetCode and HackerRank.
- Open-source contributor to multiple developer productivity repositories.
"""


def seed_database(db: Session):
    """Seed initial skills, jobs, admin user, demo user, and demo resume fixture."""
    logger.info("Starting database seeding...")

    # 1. Seed Skills
    for skill_name, category in INITIAL_SKILLS:
        existing_skill = db.query(Skill).filter(Skill.name == skill_name).first()
        if not existing_skill:
            skill_obj = Skill(name=skill_name, category=category)
            db.add(skill_obj)
    db.commit()

    # 2. Seed Admin User
    admin_email = settings.ADMIN_EMAIL
    admin_user = db.query(User).filter(User.email == admin_email).first()
    if not admin_user:
        logger.info(f"Creating Admin user: {settings.ADMIN_USERNAME} ({admin_email})")
        admin_user = User(
            name=settings.ADMIN_USERNAME,
            email=admin_email,
            username="admin",
            hashed_password=get_password_hash(settings.ADMIN_PASSWORD),
            role="ADMIN",
            is_active=True,
            title="System Administrator & Project Owner",
            location="Visakhapatnam, India",
            bio="Lead Developer and Project Owner of AI Powered Job & Resume Analyzer.",
        )
        db.add(admin_user)
        db.commit()
        db.refresh(admin_user)

    # 3. Seed Demo Candidate User
    demo_email = "demo@analyzer.local"
    demo_user = db.query(User).filter(User.email == demo_email).first()
    if not demo_user:
        logger.info(f"Creating Demo user: Alex Morgan ({demo_email})")
        demo_user = User(
            name="Alex Morgan",
            email=demo_email,
            username="alex_demo",
            hashed_password=get_password_hash("DemoUser123!"),
            role="USER",
            is_active=True,
            title="Full Stack Software Engineer",
            location="Bangalore, India",
            bio="Passionate full stack developer building AI-powered developer tools.",
        )
        db.add(demo_user)
        db.commit()
        db.refresh(demo_user)

    # 4. Seed Jobs
    for job_data in INITIAL_JOBS:
        existing_job = db.query(Job).filter(Job.title == job_data["title"], Job.company == job_data["company"]).first()
        if not existing_job:
            job_obj = Job(
                title=job_data["title"],
                company=job_data["company"],
                location=job_data["location"],
                salary=job_data["salary"],
                employment_type=job_data["employment_type"],
                experience=job_data["experience"],
                description=job_data["description"],
                responsibilities=job_data["responsibilities"],
                required_skills=job_data["required_skills"],
                preferred_skills=job_data["preferred_skills"],
                is_active=True,
            )
            db.add(job_obj)
    db.commit()

    # 5. Seed Demo Resume for Admin/Demo user if none exists
    target_user = admin_user or demo_user
    if target_user:
        existing_resume = db.query(Resume).filter(Resume.user_id == target_user.id).first()
        if not existing_resume:
            logger.info("Creating demo resume fixture and initial AI analysis...")
            resume_obj = Resume(
                user_id=target_user.id,
                file_name="Godithi_Kiran_Sri_Sai_Sandeep_Resume_DEMO.txt",
                file_type="txt",
                file_path="./uploads/demo_resume.txt",
                file_size_bytes=len(DEMO_RESUME_TEXT.encode("utf-8")),
                extracted_text=DEMO_RESUME_TEXT.strip(),
            )
            db.add(resume_obj)
            db.commit()
            db.refresh(resume_obj)

            # Perform initial analysis
            analysis_data = ai_service.analyze(DEMO_RESUME_TEXT.strip())
            analysis_obj = ResumeAnalysis(
                resume_id=resume_obj.id,
                overall_score=analysis_data.get("overall_score", 92.0),
                ats_score=analysis_data.get("ats_score", 95.0),
                analysis_mode=analysis_data.get("analysis_mode", "deterministic_fallback"),
                contact_info=analysis_data.get("contact_info", {}),
                summary_analysis=analysis_data.get("summary_analysis", {}),
                skills=analysis_data.get("skills", []),
                education=analysis_data.get("education", []),
                experience=analysis_data.get("experience", []),
                projects=analysis_data.get("projects", []),
                certifications=analysis_data.get("certifications", []),
                achievements=analysis_data.get("achievements", []),
                section_scores=analysis_data.get("section_scores", {}),
                strengths=analysis_data.get("strengths", []),
                weaknesses=analysis_data.get("weaknesses", []),
                detected_keywords=analysis_data.get("detected_keywords", []),
                missing_keywords=analysis_data.get("missing_keywords", []),
                industry_keywords=analysis_data.get("industry_keywords", []),
                content_feedback=analysis_data.get("content_feedback", {}),
                ats_feedback=analysis_data.get("ats_feedback", {}),
                recommendations=analysis_data.get("recommendations", []),
                improvements=analysis_data.get("improvements", []),
            )
            db.add(analysis_obj)
            db.commit()

    logger.info("Database seeding completed successfully.")
