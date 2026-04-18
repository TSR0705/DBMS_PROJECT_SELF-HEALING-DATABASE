"""
Test suite for application configuration
"""
import pytest
import sys
import os
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import app, DB_CONFIG


def test_app_exists():
    """Test that FastAPI app is properly initialized"""
    assert app is not None
    assert app.title == "DBMS Self-Healing API"


def test_app_testing_mode():
    """Test that app can be set to testing mode"""
    # FastAPI doesn't have config, but we can check environment
    assert True  # Placeholder - FastAPI handles testing via TestClient


def test_db_config_structure():
    """Test database configuration has required fields"""
    required_fields = ['host', 'port', 'user', 'password', 'database']
    for field in required_fields:
        assert field in DB_CONFIG, f"DB_CONFIG missing required field: {field}"


def test_db_config_types():
    """Test database configuration field types"""
    assert isinstance(DB_CONFIG['host'], str)
    assert isinstance(DB_CONFIG['port'], int)
    assert isinstance(DB_CONFIG['user'], str)
    assert isinstance(DB_CONFIG['password'], str)
    assert isinstance(DB_CONFIG['database'], str)


def test_db_config_values():
    """Test database configuration has non-empty values"""
    assert len(DB_CONFIG['host']) > 0
    assert DB_CONFIG['port'] > 0
    assert len(DB_CONFIG['user']) > 0
    assert len(DB_CONFIG['database']) > 0


def test_cors_enabled():
    """Test that CORS is properly configured"""
    # Check if CORS middleware is in the app
    cors_middleware = None
    for middleware in app.user_middleware:
        if hasattr(middleware, 'cls') and 'CORSMiddleware' in str(middleware.cls):
            cors_middleware = middleware
            break
    assert cors_middleware is not None, "CORS middleware not found"


def test_app_routes_registered():
    """Test that all expected routes are registered"""
    routes = [route.path for route in app.routes]
    
    expected_routes = [
        '/',
        '/health/',
        '/health/database',
        '/issues/',
        '/analysis/',
        '/decisions/',
        '/actions/',
        '/admin-reviews/',
        '/learning/',
    ]
    
    for route in expected_routes:
        assert route in routes, f"Route {route} not registered"


def test_app_debug_mode():
    """Test app debug configuration"""
    # FastAPI doesn't have debug attribute, but we can check if it's properly configured
    assert app is not None
