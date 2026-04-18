"""
Test suite for FastAPI endpoints
Tests basic functionality without requiring database connection
"""
import pytest
import sys
import os

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_root_endpoint():
    """Test the root endpoint returns API information"""
    response = client.get('/')
    assert response.status_code == 200
    data = response.json()
    assert 'name' in data
    assert 'version' in data
    assert data['name'] == 'DBMS Self-Healing API'

def test_health_endpoint_structure():
    """Test health endpoint returns proper structure (may fail without DB)"""
    response = client.get('/health')
    assert response.status_code in [200, 503]
    data = response.json()
    assert 'status' in data
    assert 'database_connected' in data
    assert 'timestamp' in data

def test_cors_headers():
    """Test CORS headers are properly set via preflight/OPTIONS or GET handling depends on origin. Instead we test root origin headers."""
    response = client.get('/', headers={'Origin': 'http://localhost:3000'})
    assert 'access-control-allow-origin' in response.headers

def test_invalid_endpoint():
    """Test that invalid endpoints return 404"""
    response = client.get('/invalid-endpoint-that-does-not-exist')
    assert response.status_code == 404

def test_api_endpoints_exist():
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
        # Accept 200 (success) or 500 (DB error config) but not 404 (missing endpoint)
        assert response.status_code != 404, f"Endpoint {endpoint} should exist"

def test_content_type_json():
    """Test that API returns JSON content type"""
    response = client.get('/')
    assert 'application/json' in response.headers.get('content-type', '')

def test_api_version_format():
    """Test API version follows semantic versioning"""
    response = client.get('/')
    data = response.json()
    version = data.get('version', '')
    # Check version format (e.g., "1.0.0")
    assert len(version.split('.')) >= 2, "Version should follow semantic versioning"
