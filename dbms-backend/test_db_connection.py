#!/usr/bin/env python3
"""
Database connection test script.
Tests connection and shows available tables.
"""

import os
from dotenv import load_dotenv
from app.database.connection import db

def test_database_connection():
    """Test database connection and show available tables."""
    
    # Load environment variables
    load_dotenv()
    
    print("=== Database Connection Test ===")
    print(f"Host: {os.getenv('DB_HOST')}")
    print(f"Port: {os.getenv('DB_PORT')}")
    print(f"Database: {os.getenv('DB_NAME')}")
    print(f"User: {os.getenv('DB_USER')}")
    print(f"Password: {'*' * len(os.getenv('DB_PASSWORD', '')) if os.getenv('DB_PASSWORD') else 'NOT SET'}")
    print()
    
    # Test basic connection
    try:
        print("Testing database connection...")
        is_connected = db.test_connection()
        
        if is_connected:
            print("✅ Database connection successful!")
            
            # Show available tables
            print("\n=== Available Tables ===")
            try:
                tables = db.execute_read_query("SHOW TABLES")
                if tables:
                    for table in tables:
                        table_name = list(table.values())[0]
                        print(f"📋 {table_name}")
                        
                        # Show table structure
                        try:
                            columns = db.execute_read_query(f"DESCRIBE {table_name}")
                            print(f"   Columns: {', '.join([col['Field'] for col in columns])}")
                        except Exception as e:
                            print(f"   Error describing table: {e}")
                        print()
                else:
                    print("No tables found in database")
                    
            except Exception as e:
                print(f"❌ Error listing tables: {e}")
                
        else:
            print("❌ Database connection failed!")
            
    except Exception as e:
        print(f"❌ Connection error: {e}")
        print("\nPlease check your database credentials in .env file:")
        print("- DB_HOST")
        print("- DB_PORT") 
        print("- DB_NAME")
        print("- DB_USER")
        print("- DB_PASSWORD")

if __name__ == "__main__":
    test_database_connection()