#!/usr/bin/env python3
"""
Test the issues query directly.
"""

from dotenv import load_dotenv
from app.database.connection import db

def test_issues_query():
    """Test the issues query directly."""
    
    load_dotenv()
    
    query = """
    SELECT 
        issue_id,
        issue_type,
        detection_source,
        raw_metric_value,
        detected_at
    FROM detected_issues 
    WHERE detected_at IS NOT NULL
    ORDER BY detected_at DESC
    LIMIT 100
    """
    
    try:
        print("Testing issues query...")
        results = db.execute_read_query(query)
        print(f"✅ Query successful! Found {len(results)} issues:")
        
        for issue in results:
            print(f"  - {issue['issue_id']}: {issue['issue_type']} from {issue['detection_source']}")
            
    except Exception as e:
        print(f"❌ Query failed: {e}")

if __name__ == "__main__":
    test_issues_query()