#!/usr/bin/env python3
"""
Database Cleanup Script
Removes test tables and backup tables, keeping only the real rule-based system tables.
"""

import sys
import os
import logging

# Add app to Python path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.database.connection import DatabaseConnection

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def cleanup_database():
    """Remove test tables and backup tables, keep only real system tables."""
    
    db = DatabaseConnection()
    config = db.config.copy()
    
    import mysql.connector
    with mysql.connector.connect(**config) as conn:
        cursor = conn.cursor()
        
        try:
            # Get all tables
            cursor.execute("SHOW TABLES")
            all_tables = [row[0] for row in cursor.fetchall()]
            
            logger.info(f"📋 Found {len(all_tables)} tables in database")
            for table in all_tables:
                logger.info(f"   - {table}")
            
            # Define tables to keep (real rule-based system tables)
            tables_to_keep = {
                'detected_issues',
                'ai_analysis', 
                'decision_log',
                'healing_actions',
                'admin_reviews',
                'learning_history'
            }
            
            # Identify tables to remove
            tables_to_remove = []
            for table in all_tables:
                if table not in tables_to_keep:
                    tables_to_remove.append(table)
            
            if not tables_to_remove:
                logger.info("✅ No tables to remove - database is already clean")
                return
            
            logger.info(f"\n🗑️  Tables to remove ({len(tables_to_remove)}):")
            for table in tables_to_remove:
                logger.info(f"   - {table}")
            
            logger.info(f"\n✅ Tables to keep ({len(tables_to_keep)}):")
            for table in tables_to_keep:
                logger.info(f"   - {table}")
            
            # Confirm removal
            print(f"\n⚠️  WARNING: This will permanently delete {len(tables_to_remove)} tables!")
            confirm = input("Continue with cleanup? (yes/no): ").strip().lower()
            if confirm != 'yes':
                logger.info("Cleanup cancelled.")
                return
            
            # Disable foreign key checks temporarily
            cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
            
            # Remove tables
            logger.info("\n🗑️  Removing tables...")
            for table in tables_to_remove:
                try:
                    cursor.execute(f"DROP TABLE IF EXISTS {table}")
                    logger.info(f"   ✅ Removed {table}")
                except Exception as e:
                    logger.error(f"   ❌ Failed to remove {table}: {e}")
            
            # Re-enable foreign key checks
            cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
            
            conn.commit()
            
            # Verify cleanup
            cursor.execute("SHOW TABLES")
            remaining_tables = [row[0] for row in cursor.fetchall()]
            
            logger.info(f"\n📊 Cleanup Results:")
            logger.info(f"   Tables before: {len(all_tables)}")
            logger.info(f"   Tables removed: {len(tables_to_remove)}")
            logger.info(f"   Tables remaining: {len(remaining_tables)}")
            
            logger.info(f"\n✅ Remaining tables:")
            for table in remaining_tables:
                logger.info(f"   - {table}")
            
            # Verify all required tables exist
            missing_tables = tables_to_keep - set(remaining_tables)
            if missing_tables:
                logger.warning(f"⚠️  Missing required tables: {missing_tables}")
            else:
                logger.info("✅ All required rule-based system tables present")
            
            logger.info("\n🎉 Database cleanup completed successfully!")
            
        except Exception as e:
            logger.error(f"❌ Database cleanup failed: {e}")
            conn.rollback()
            raise
        finally:
            cursor.close()

def show_table_info():
    """Show information about remaining tables."""
    
    db = DatabaseConnection()
    
    try:
        # Get table information
        tables_info = {}
        required_tables = [
            'detected_issues', 'ai_analysis', 'decision_log',
            'healing_actions', 'admin_reviews', 'learning_history'
        ]
        
        for table in required_tables:
            try:
                query = f"SELECT COUNT(*) as count FROM {table}"
                result = db.execute_read_query(query)
                count = result[0]['count'] if result else 0
                tables_info[table] = count
            except Exception as e:
                tables_info[table] = f"Error: {e}"
        
        logger.info("\n📊 Rule-Based System Tables Status:")
        for table, info in tables_info.items():
            if isinstance(info, int):
                logger.info(f"   ✅ {table}: {info} records")
            else:
                logger.info(f"   ❌ {table}: {info}")
        
        return tables_info
        
    except Exception as e:
        logger.error(f"Error getting table information: {e}")
        return {}

def main():
    print("🧹 DBMS Rule-Based Self-Healing System")
    print("📋 Database Cleanup")
    print("=" * 50)
    print("This will remove test tables and backups, keeping only the real system tables.")
    print()
    
    try:
        # Test database connection
        db = DatabaseConnection()
        if not db.test_connection():
            print("❌ Database connection failed!")
            return False
        
        print("✅ Database connection successful")
        
        # Show current status
        print("\n📊 Current Database Status:")
        show_table_info()
        
        # Perform cleanup
        cleanup_database()
        
        # Show final status
        print("\n📊 Final Database Status:")
        show_table_info()
        
        return True
        
    except Exception as e:
        print(f"❌ Database cleanup failed: {e}")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)