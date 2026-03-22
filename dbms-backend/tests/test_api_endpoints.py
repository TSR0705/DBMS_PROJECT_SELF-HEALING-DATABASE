"""
Test suite for Flask API endpoints
Tests basic functionality without requiring database connection
"""
import pytest
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import app


@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


def test_root_endpoint(client):
    """Test the root endpoint returns API information"""
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert 'name' in data
    assert 'version' in data
    assert data['name'] == 'DBMS Self-Healing API'


def test_health_endpoint_structure(client):
    """Test health endpoint returns proper structure (may fail without DB)"""
    response = client.get('/health')
    # Accept both 200 (DB connected) and 500 (DB not connected in CI)
    assert response.status_code in [200, 500]
    data = response.get_json()
    assert 'status' in data
    assert 'database_connected' in data
    assert 'timestamp' in data


def test_cors_headers(client):
    """Test CORS headers are properly set"""
    response = client.get('/')
    assert 'Access-Control-Allow-Origin' in response.headers


def test_invalid_endpoint(client):
    """Test that invalid endpoints return 404"""
    response = client.get('/invalid-endpoint-that-does-not-exist')
    assert response.status_code == 404


def test_api_endpoints_exist(client):
    """Test that all expected API endpoints exist (structure test)"""
    endpoints = [
        '/issues/',
        '/analysis/',
        '/decisions/',
        '/actions/',
        '/admin-reviews/',
        '/learning/',
    ]
    
    for endpoint in endpoints:
        response = client.get(endpoint)
        # Accept 200 (success) or 500 (DB error in CI) but not 404 (missing endpoint)
        assert response.status_code != 404, f"Endpoint {endpoint} should exist"


def test_content_type_json(client):
    """Test that API returns JSON content type"""
    response = client.get('/')
    assert response.content_type == 'application/json'


def test_api_version_format(client):
    """Test API version follows semantic versioning"""
    response = client.get('/')
    data = response.get_json()
    version = data.get('version', '')
    # Check version format (e.g., "1.0.0")
    assert len(version.split('.')) >= 2, "Version should follow semantic versioning"
