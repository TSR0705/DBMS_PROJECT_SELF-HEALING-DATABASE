"""
Test suite for data processing functions
"""
import pytest
import sys
import os
from datetime import datetime

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import serialize_datetime, process_results


def test_serialize_datetime():
    """Test datetime serialization to ISO format"""
    test_datetime = datetime(2026, 3, 22, 10, 30, 45)
    result = serialize_datetime(test_datetime)
    assert isinstance(result, str)
    assert 'T' in result  # ISO format includes T separator
    assert result.startswith('2026-03-22')


def test_serialize_non_datetime():
    """Test that non-datetime objects are returned unchanged"""
    test_string = "test_value"
    result = serialize_datetime(test_string)
    assert result == test_string
    
    test_int = 42
    result = serialize_datetime(test_int)
    assert result == test_int


def test_process_results_empty():
    """Test processing empty results"""
    results = []
    processed = process_results(results)
    assert processed == []
    assert isinstance(processed, list)


def test_process_results_with_datetime():
    """Test processing results containing datetime objects"""
    test_datetime = datetime(2026, 3, 22, 10, 30, 45)
    results = [
        {
            'id': 1,
            'name': 'test',
            'created_at': test_datetime
        }
    ]
    
    processed = process_results(results)
    assert len(processed) == 1
    assert processed[0]['id'] == 1
    assert processed[0]['name'] == 'test'
    assert isinstance(processed[0]['created_at'], str)
    assert 'T' in processed[0]['created_at']


def test_process_results_multiple_records():
    """Test processing multiple records"""
    results = [
        {'id': 1, 'value': 'first'},
        {'id': 2, 'value': 'second'},
        {'id': 3, 'value': 'third'}
    ]
    
    processed = process_results(results)
    assert len(processed) == 3
    assert processed[0]['id'] == 1
    assert processed[1]['id'] == 2
    assert processed[2]['id'] == 3


def test_process_results_mixed_types():
    """Test processing results with mixed data types"""
    test_datetime = datetime(2026, 3, 22)
    results = [
        {
            'string_field': 'text',
            'int_field': 123,
            'float_field': 45.67,
            'datetime_field': test_datetime,
            'none_field': None
        }
    ]
    
    processed = process_results(results)
    assert processed[0]['string_field'] == 'text'
    assert processed[0]['int_field'] == 123
    assert processed[0]['float_field'] == 45.67
    assert isinstance(processed[0]['datetime_field'], str)
    assert processed[0]['none_field'] is None
