from typing import List, Dict, Any, Optional
from app.models.resume import ResumeAnalysis


class CareerService:
    """
    Career Path and Skill Gap Analysis Service.
    Maps extracted candidate skills to industry role requirements to recommend suitable career tracks.
    """

    CAREER_ROLES = {
        "Full Stack Developer": {
            "required": ["Python", "JavaScript", "React", "FastAPI", "SQL", "Git", "Docker", "REST API"],
            "salary": "$100,000 - $140,000",
            "demand": "Very High",
            "steps": [
                "Build full-stack end-to-end applications with state management and authentication.",
                "Implement CI/CD deployment pipelines using GitHub Actions and Docker.",
                "Master both relational (PostgreSQL) and NoSQL (Redis/MongoDB) caching layers."
            ],
            "learning": {
                "Docker": "Complete containerization of local apps and multi-stage builds.",
                "FastAPI": "Build async microservices with OAuth2 and SQLAlchemy 2.0.",
                "React": "Master modern hooks, Context API, and state management libraries.",
            }
        },
        "Backend Developer": {
            "required": ["Python", "Java", "FastAPI", "Django", "PostgreSQL", "Redis", "Docker", "Kubernetes", "Microservices"],
            "salary": "$105,000 - $145,000",
            "demand": "High",
            "steps": [
                "Focus on distributed systems, high concurrency, and queue systems (Celery/Kafka).",
                "Design scalable database schemas with indexing and query plan optimization.",
                "Write comprehensive test suites with PyTest or JUnit."
            ],
            "learning": {
                "Redis": "Implement caching layers, session stores, and rate limiting.",
                "Kubernetes": "Deploy clusters, manage pods, and configure ingress controllers.",
                "PostgreSQL": "Master complex joins, indexing strategies, and transaction isolation.",
            }
        },
        "Frontend Developer": {
            "required": ["JavaScript", "TypeScript", "React", "Flutter", "HTML", "CSS", "Tailwind", "Responsive Design"],
            "salary": "$95,000 - $130,000",
            "demand": "High",
            "steps": [
                "Create polished, accessible, Material 3/Apple Human Interface compliant components.",
                "Deep dive into state management (Riverpod/Redux/Zustand).",
                "Optimize frontend web vitals and client-side rendering performance."
            ],
            "learning": {
                "TypeScript": "Convert legacy JS components to strongly typed TypeScript interfaces.",
                "Flutter": "Build cross-platform responsive mobile and web layouts.",
                "Tailwind": "Adopt utility-first modern CSS layouts.",
            }
        },
        "AI/ML Engineer": {
            "required": ["Python", "PyTorch", "TensorFlow", "Scikit-Learn", "Pandas", "NumPy", "NLP", "FastAPI", "Docker"],
            "salary": "$120,000 - $165,000",
            "demand": "Extremely High",
            "steps": [
                "Build and fine-tune transformer models and generative AI pipelines.",
                "Deploy ML models as low-latency microservices with FastAPI and ONNX runtime.",
                "Implement vector search pipelines using Qdrant/Pinecone/Chroma."
            ],
            "learning": {
                "PyTorch": "Train deep learning models and implement custom loss functions.",
                "NLP": "Work with Hugging Face transformers and tokenization pipelines.",
                "FastAPI": "Wrap inference models into production REST endpoints.",
            }
        },
        "Cloud & DevOps Engineer": {
            "required": ["AWS", "Azure", "GCP", "Docker", "Kubernetes", "Terraform", "CI/CD", "Linux", "Bash"],
            "salary": "$115,000 - $155,000",
            "demand": "High",
            "steps": [
                "Automate infrastructure provisioning using Terraform (IaC).",
                "Set up zero-downtime blue/green deployment pipelines.",
                "Implement centralized monitoring and alerting with Prometheus and Grafana."
            ],
            "learning": {
                "Terraform": "Write declarative infrastructure modules for AWS/GCP.",
                "Kubernetes": "Manage multi-container deployments and ingress controllers.",
                "AWS": "Prepare for AWS Certified Solutions Architect Associate.",
            }
        },
        "Data Analyst": {
            "required": ["SQL", "Python", "Pandas", "NumPy", "Tableau", "PowerBI", "Data Visualization", "Statistics"],
            "salary": "$85,000 - $115,000",
            "demand": "Moderate-High",
            "steps": [
                "Perform exploratory data analysis and statistical significance testing.",
                "Build interactive executive dashboards using Tableau and PowerBI.",
                "Write advanced SQL window functions and CTEs."
            ],
            "learning": {
                "SQL": "Master window functions, aggregations, and subqueries.",
                "Pandas": "Clean, merge, and transform complex datasets.",
                "PowerBI": "Design dynamic business KPI dashboards.",
            }
        },
        "Python Developer": {
            "required": ["Python", "FastAPI", "Django", "SQL", "PostgreSQL", "Git", "PyTest", "Docker"],
            "salary": "$95,000 - $135,000",
            "demand": "High",
            "steps": [
                "Build asynchronous REST APIs and background task workers.",
                "Implement ORM mappings with SQLAlchemy 2.0 and Alembic migrations.",
                "Write robust unit and integration tests with PyTest."
            ],
            "learning": {
                "FastAPI": "Develop asynchronous high-throughput REST APIs.",
                "PyTest": "Implement fixture-based automated integration testing.",
                "Docker": "Containerize Python web apps with optimized base images.",
            }
        },
        "Java Developer": {
            "required": ["Java", "Spring Boot", "Hibernate", "SQL", "PostgreSQL", "Maven", "Microservices", "Docker"],
            "salary": "$100,000 - $140,000",
            "demand": "High",
            "steps": [
                "Build enterprise-grade microservices with Spring Boot and Spring Data JPA.",
                "Implement secure authentication using Spring Security and OAuth2.",
                "Deploy containerized Java services to cloud platforms."
            ],
            "learning": {
                "Spring Boot": "Develop microservice architectures with Spring Cloud.",
                "Hibernate": "Optimize ORM queries and database connection pools.",
                "Docker": "Containerize Spring Boot applications.",
            }
        },
    }

    @staticmethod
    def get_career_recommendations(analysis: Optional[ResumeAnalysis]) -> List[Dict[str, Any]]:
        user_skills = set()
        if analysis and analysis.skills:
            for s in analysis.skills:
                skill_name = s["name"] if isinstance(s, dict) else str(s)
                user_skills.add(skill_name.lower())

        recommendations = []
        for role_name, role_data in CareerService.CAREER_ROLES.items():
            req_skills = role_data["required"]
            matched = []
            gaps = []

            for s in req_skills:
                s_lower = s.lower()
                if any(s_lower == u or s_lower in u or u in s_lower for u in user_skills):
                    matched.append(s)
                else:
                    gaps.append(s)

            match_pct = (len(matched) / len(req_skills)) * 100.0 if req_skills else 50.0
            # Base match minimum for display
            if not user_skills:
                match_pct = 40.0

            recommendations.append({
                "role_title": role_name,
                "match_percentage": round(min(98.0, max(20.0, match_pct)), 1),
                "current_skills": matched if user_skills else ["General Technical Background"],
                "required_skills": req_skills,
                "skill_gaps": gaps,
                "next_steps": role_data["steps"],
                "salary_range": role_data["salary"],
                "demand_level": role_data["demand"],
            })

        # Sort descending by match percentage
        recommendations.sort(key=lambda x: x["match_percentage"], reverse=True)
        return recommendations

    @staticmethod
    def analyze_skill_gap(target_role: str, analysis: Optional[ResumeAnalysis]) -> Dict[str, Any]:
        user_skills = set()
        if analysis and analysis.skills:
            for s in analysis.skills:
                skill_name = s["name"] if isinstance(s, dict) else str(s)
                user_skills.add(skill_name.lower())

        role_info = CareerService.CAREER_ROLES.get(
            target_role,
            {
                "required": ["Python", "FastAPI", "SQL", "Git", "Docker", "REST API", "System Design"],
                "salary": "$95,000 - $135,000",
                "demand": "High",
                "steps": [
                    "Complete structured projects in the required tech stack.",
                    "Build a GitHub portfolio with clear documentation and tests.",
                ],
                "learning": {
                    "Docker": "Learn container lifecycle and networking.",
                    "FastAPI": "Build production REST APIs.",
                    "SQL": "Optimize database queries and schema design.",
                }
            }
        )

        req_skills = role_info["required"]
        matched = []
        missing = []

        for s in req_skills:
            s_lower = s.lower()
            if any(s_lower == u or s_lower in u or u in s_lower for u in user_skills):
                matched.append(s)
            else:
                missing.append(s)

        match_pct = (len(matched) / len(req_skills)) * 100.0 if req_skills else 50.0
        match_pct = round(min(98.0, max(15.0, match_pct)), 1)

        # Segment priorities
        high_priority = missing[:2] if missing else []
        medium_priority = missing[2:4] if len(missing) > 2 else []
        low_priority = missing[4:] if len(missing) > 4 else []

        learning_recs = []
        learning_dict = role_info.get("learning", {})
        for skill in missing:
            learning_recs.append({
                "skill": skill,
                "recommendation": learning_dict.get(skill, f"Study official documentation and build a capstone project utilizing {skill}."),
            })

        if not learning_recs:
            learning_recs.append({
                "skill": "Advanced Mastery",
                "recommendation": f"You meet all primary requirements for {target_role}. Focus on advanced architectural patterns.",
            })

        return {
            "target_role": target_role,
            "match_percentage": match_pct,
            "matched_skills": matched,
            "missing_skills": missing,
            "high_priority": high_priority,
            "medium_priority": medium_priority,
            "low_priority": low_priority,
            "learning_recommendations": learning_recs,
        }


career_service = CareerService()
