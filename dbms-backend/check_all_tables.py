#!/usr/bin/env python3
"""
Check data in all database tables.
"""

import os
from dotenv import load_dotenv
from app.database.connection import db

def check_all_tables():
    """Check data in all tables."""
    
    load_dotenv()
    
    tables = [
        'detected_issues',
        'ai_analysis', 
        'decision_log',
        'healing_actions',
        'admin_reviews',
        'learning_history'
    ]
    
    for table in tables:
        print(f"\n=== {table.upper()} ===")
        try:
            # Get count
            count_result = db.execute_read_query(f"SELECT COUNT(*) as count FROM {table}")
            count = count_result[0]['count'] if count_result else 0
            print(f"Total records: {count}")
            
            if count > 0:
                # Get sample data
                sample_data = db.execute_read_query(f"SELECT * FROM {table} LIMIT 3")
                print("Sample data:")
                for i, row in enumerate(sample_data, 1):
                    print(f"  {i}. {dict(row)}")
            else:
                print("No data found")
                
        except Exception as e:
            print(f"Error querying {table}: {e}")

if __name__ == "__main__":
    check_all_tables()