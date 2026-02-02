#!/usr/bin/env python3
"""
Debug API issues step by step.
"""

from dotenv import load_dotenv
from app.database.connection import db
from app.models.schemas import DetectedIssue

def debug_api():
    """Debug the API step by step."""
    
    load_dotenv()
    
    print("=== Debugging API Issues ===")
    
    # Step 1: Test raw query
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
        print("1. Testing raw database query...")
        results = db.execute_read_query(query)
        print(f"✅ Raw query successful! Found {len(results)} issues")
        
        if results:
            print("First result:", results[0])
            
            # Step 2: Test Pydantic model creation
            print("\n2. Testing Pydantic model creation...")
            try:
                first_row = results[0]
                issue = DetectedIssue(
                    issue_id=str(first_row['issue_id']),
                    issue_type=first_row['issue_type'],
                    detection_source=first_row['detection_source'],
                    raw_metric_value=float(first_row['raw_metric_value']) if first_row['raw_metric_value'] is not None else None,
                    detected_at=first_row['detected_at']
                )
                print(f"✅ Pydantic model creation successful!")
                print(f"Issue: {issue}")
                
            except Exception as e:
                print(f"❌ Pydantic model creation failed: {e}")
                print(f"Raw data types: {[(k, type(v)) for k, v in first_row.items()]}")
        
    except Exception as e:
        print(f"❌ Raw query failed: {e}")

if __name__ == "__main__":
    debug_api()