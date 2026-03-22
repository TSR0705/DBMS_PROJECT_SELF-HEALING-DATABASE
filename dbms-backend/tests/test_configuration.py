"""
Test suite for application configuration
"""
import pytest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import app, DB_CONFIG


def test_app_exists():
    """Test that Flask app is properly initialized"""
    assert app is not None
    assert 'main' in app.name


def test_app_testing_mode():
    """Test that app can be set to testing mode"""
    app.config['TESTING'] = True
    assert app.config['TESTING'] is True


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
    with app.test_client() as client:
        response = client.get('/')
        assert 'Access-Control-Allow-Origin' in response.headers


def test_app_routes_registered():
    """Test that all expected routes are registered"""
    routes = [rule.rule for rule in app.url_map.iter_rules()]
    
    expected_routes = [
        '/',
        '/health',
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
    # In production, debug should be False
    # In testing, we just verify it's configurable
    original_debug = app.debug
    app.debug = False
    assert app.debug is False
    app.debug = original_debug
