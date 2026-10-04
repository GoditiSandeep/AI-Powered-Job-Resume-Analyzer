import os
import sys
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Add backend directory to sys.path
backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if backend_dir not in sys.path:
    sys.path.insert(0, backend_dir)

# Set test environment
os.environ["ENVIRONMENT"] = "test"
os.environ["DEBUG"] = "False"
os.environ["DATABASE_URL"] = "sqlite:///:memory:"
os.environ["ADMIN_PASSWORD"] = "TestAdminPass2026!"

from app.config.settings import settings
from app.database.base import Base
from app.database.session import get_db
from app.database.seed_data import seed_database
from app.main import app
from app.auth.jwt import create_access_token
from app.auth.security import get_password_hash
from app.models.user import User

# In-memory SQLite engine for fast isolated tests
TEST_DATABASE_URL = "sqlite:///:memory:"
test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


@pytest.fixture(scope="session", autouse=True)
def setup_test_database():
    Base.metadata.create_all(bind=test_engine)
    db = TestingSessionLocal()
    seed_database(db)
    db.close()
    yield
    Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def db_session():
    connection = test_engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)

    yield session

    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def admin_token(db_session):
    admin = db_session.query(User).filter(User.role == "ADMIN").first()
    if not admin:
        admin = User(
            name="Godithi Sandeep",
            email="admin@analyzer.local",
            username="admin",
            hashed_password=get_password_hash("TestAdminPass2026!"),
            role="ADMIN",
            is_active=True,
        )
        db_session.add(admin)
        db_session.commit()
        db_session.refresh(admin)
    token = create_access_token({"sub": str(admin.id), "email": admin.email, "role": "ADMIN"})
    return token


@pytest.fixture
def user_token(db_session):
    user = db_session.query(User).filter(User.email == "testuser@example.com").first()
    if not user:
        user = User(
            name="Test Candidate",
            email="testuser@example.com",
            username="testcandidate",
            hashed_password=get_password_hash("Password123!"),
            role="USER",
            is_active=True,
        )
        db_session.add(user)
        db_session.commit()
        db_session.refresh(user)
    token = create_access_token({"sub": str(user.id), "email": user.email, "role": "USER"})
    return token


@pytest.fixture
def auth_headers(user_token):
    return {"Authorization": f"Bearer {user_token}"}


@pytest.fixture
def admin_headers(admin_token):
    return {"Authorization": f"Bearer {admin_token}"}
