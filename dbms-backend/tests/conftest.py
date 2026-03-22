"""
Pytest configuration and fixtures for DBMS backend tests
"""
import os
import sys
import pytest

# Set testing environment variable
os.environ['TESTING'] = 'true'

# Add parent directory to Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))


@pytest.fixture(scope='session', autouse=True)
def setup_test_environment():
    """Setup test environment before running tests"""
    # Set environment variables for testing
    os.environ['TESTING'] = 'true'
    os.environ['DB_HOST'] = 'localhost'
    os.environ['DB_PORT'] = '3306'
    os.environ['DB_USER'] = 'test_user'
    os.environ['DB_PASSWORD'] = 'test_password'
    os.environ['DB_NAME'] = 'test_database'
    
    yield
    
    # Cleanup after tests (if needed)
    pass


@pytest.fixture
def mock_db_connection(monkeypatch):
    """Mock database connection for tests that don't need real DB"""
    def mock_get_connection():
        raise Exception("Database not available in test environment")
    
    # This can be used in tests that need to mock DB
    return mock_get_connection
