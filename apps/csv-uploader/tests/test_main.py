import io
import sys
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Mock boto3 and botocore before any imports that use them
mock_boto3 = MagicMock()
mock_botocore = MagicMock()
mock_botocore_exceptions = MagicMock()
sys.modules["boto3"] = mock_boto3
sys.modules["botocore"] = mock_botocore
sys.modules["botocore.exceptions"] = mock_botocore_exceptions

# Create test database engine
TEST_DATABASE_URL = "sqlite:///:memory:"
test_engine = create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)


def get_test_db():
    """Get test database session."""
    db = TestSessionLocal()
    try:
        yield db
    finally:
        db.close()


@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    # Patch database before importing main
    with patch("database.engine", test_engine):
        with patch("database.SessionLocal", TestSessionLocal):
            from database import Base, get_db
            from main import app

            # Create tables for this test
            Base.metadata.create_all(bind=test_engine)

            # Override the get_db dependency
            app.dependency_overrides[get_db] = get_test_db

            with patch("main.init_db"):
                with patch("main.check_bucket_exists", return_value=True):
                    yield TestClient(app)

            # Clean up
            app.dependency_overrides.clear()
            Base.metadata.drop_all(bind=test_engine)


class TestHealthEndpoints:
    """Test basic health and index endpoints."""

    def test_index_returns_html(self, client):
        """Test that index endpoint returns HTML."""
        response = client.get("/")
        assert response.status_code == 200


class TestFileEndpoints:
    """Test file-related endpoints."""

    def test_list_files_returns_json(self, client):
        """Test that list files endpoint returns JSON."""
        response = client.get("/files")
        assert response.status_code == 200
        assert response.json() == []

    def test_get_file_not_found(self, client):
        """Test that getting non-existent file returns 404."""
        response = client.get("/files/999")
        assert response.status_code == 404


class TestUploadEndpoint:
    """Test file upload functionality."""

    def test_upload_non_csv_rejected(self, client):
        """Test that non-CSV files are rejected."""
        files = {"file": ("test.txt", io.BytesIO(b"test content"), "text/plain")}
        response = client.post("/upload", files=files)
        assert response.status_code == 400
        assert "CSV" in response.json()["detail"]

    def test_upload_csv_success(self, client):
        """Test successful CSV upload."""
        with patch("main.upload_file") as mock_upload:
            mock_upload.return_value = None

            csv_content = b"col1,col2\nval1,val2\nval3,val4"
            files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
            response = client.post("/upload", files=files)

            assert response.status_code == 200
            data = response.json()
            assert data["status"] == "success"
            assert data["row_count"] == 2
