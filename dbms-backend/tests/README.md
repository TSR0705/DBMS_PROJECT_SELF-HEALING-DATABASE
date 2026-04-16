# Backend Test Suite

This directory contains the test suite for the DBMS Self-Healing Backend API.

## Test Structure

- `conftest.py` - Pytest configuration and shared fixtures
- `test_api_endpoints.py` - Tests for API endpoint functionality
- `test_configuration.py` - Tests for application configuration
- `test_data_processing.py` - Tests for data processing functions

## Running Tests

### Run all tests
```bash
python -m pytest tests/ -v
```

### Run with coverage
```bash
python -m pytest tests/ --cov=app --cov-report=html
```

### Run specific test file
```bash
python -m pytest tests/test_api_endpoints.py -v
```

### Run specific test
```bash
python -m pytest tests/test_api_endpoints.py::test_root_endpoint -v
```

## Test Coverage

The test suite includes:
- **21 tests** covering core functionality
- API endpoint validation
- Configuration validation
- Data processing and serialization
- CORS and security headers
- Error handling

## CI/CD Integration

These tests run automatically in the GitHub Actions CI pipeline on every push and pull request.

## Requirements

Test dependencies are listed in `requirements.txt`:
- pytest==7.4.3
- pytest-cov==4.1.0
- flake8==6.1.0

## Notes

- Tests are designed to work without a database connection in CI environments
- The `TESTING` environment variable is automatically set during test runs
- Database-dependent tests gracefully handle connection failures
