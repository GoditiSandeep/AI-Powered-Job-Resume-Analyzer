import logging
from app.database.base import Base
from app.database.session import engine, SessionLocal
from app.database.seed_data import seed_database
# Import all models so Base knows about all tables
import app.models

logger = logging.getLogger(__name__)


def init_db():
    """Create all database tables and seed with initial data."""
    logger.info("Initializing database tables...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    init_db()
