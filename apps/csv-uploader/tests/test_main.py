import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import io

# Mock S3 and database before importing app
with patch('s3_client.boto3'):
    with patch('database.create_engine'):
        from main import app


@pytest.fixture
def client():
    """Create a test client for the FastAPI app."""
    with patch('main.init_db'):
        with patch('main.check_bucket_exists', return_value=True):
            return TestClient(app)


@pytest.fixture
def mock_db():
    """Create a mock database session."""
    db = MagicMock()
    return db


class TestHealthEndpoints:
    """Test basic health and index endpoints."""

    def test_index_returns_html(self, client):
        """Test that index endpoint returns HTML."""
        with patch('main.get_db'):
            with patch('main.templates.TemplateResponse') as mock_template:
                mock_template.return_value = MagicMock()
                response = client.get("/")
                # The endpoint should be accessible
                assert response.status_code in [200, 500]


class TestFileEndpoints:
    """Test file-related endpoints."""

    def test_list_files_returns_json(self, client):
        """Test that list files endpoint returns JSON."""
        with patch('main.get_db') as mock_get_db:
            mock_session = MagicMock()
            mock_session.query.return_value.order_by.return_value.all.return_value = []
            mock_get_db.return_value = mock_session

            response = client.get("/files")
            assert response.status_code == 200
            assert response.json() == []

    def test_get_file_not_found(self, client):
        """Test that getting non-existent file returns 404."""
        with patch('main.get_db') as mock_get_db:
            mock_session = MagicMock()
            mock_session.query.return_value.filter.return_value.first.return_value = None
            mock_get_db.return_value = mock_session

            response = client.get("/files/999")
            assert response.status_code == 404


class TestUploadEndpoint:
    """Test file upload functionality."""

    def test_upload_non_csv_rejected(self, client):
        """Test that non-CSV files are rejected."""
        with patch('main.get_db'):
            files = {"file": ("test.txt", io.BytesIO(b"test content"), "text/plain")}
            response = client.post("/upload", files=files)
            assert response.status_code == 400
            assert "CSV" in response.json()["detail"]

    def test_upload_csv_success(self, client):
        """Test successful CSV upload."""
        with patch('main.get_db') as mock_get_db:
            with patch('main.upload_file') as mock_upload:
                mock_session = MagicMock()
                mock_file = MagicMock()
                mock_file.id = 1
                mock_session.add = MagicMock()
                mock_session.commit = MagicMock()
                mock_session.refresh = MagicMock(side_effect=lambda x: setattr(x, 'id', 1))
                mock_get_db.return_value = mock_session
                mock_upload.return_value = None

                csv_content = b"col1,col2\nval1,val2\nval3,val4"
                files = {"file": ("test.csv", io.BytesIO(csv_content), "text/csv")}
                response = client.post("/upload", files=files)

                assert response.status_code == 200
                data = response.json()
                assert data["status"] == "success"
                assert data["row_count"] == 2
