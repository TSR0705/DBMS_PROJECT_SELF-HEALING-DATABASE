"""
Database connection management for DBMS self-healing system.
Provides read-only access to existing DBMS pipeline tables.
"""

import os
import mysql.connector
from mysql.connector import Error
from typing import Optional, List, Dict, Any
from contextlib import contextmanager
import logging

logger = logging.getLogger(__name__)

class DatabaseConnection:
    """
    Manages MySQL connections for read-only access to DBMS pipeline data.
    Ensures safe, read-only operations with proper connection handling.
    """
    
    def __init__(self):
        # Load environment variables
        from dotenv import load_dotenv
        load_dotenv()
        
        self.config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': int(os.getenv('DB_PORT', 3306)),
            'user': os.getenv('DB_USER', 'root'),
            'password': os.getenv('DB_PASSWORD', ''),
            'database': os.getenv('DB_NAME'),
            'autocommit': False,  # Explicit transaction control
            'use_pure': True,     # Pure Python implementation for safety
        }
        
        # Debug: Print config (without password)
        debug_config = self.config.copy()
        debug_config['password'] = '*' * len(debug_config['password']) if debug_config['password'] else 'EMPTY'
        logger.info(f"Database config: {debug_config}")
        
    @contextmanager
    def get_connection(self):
        """
        Context manager for database connections.
        Ensures proper connection cleanup and error handling.
        """
        connection = None
        try:
            connection = mysql.connector.connect(**self.config)
            if connection.is_connected():
                # Set session to read-only for additional safety
                cursor = connection.cursor()
                cursor.execute("SET SESSION TRANSACTION READ ONLY")
                cursor.close()
                yield connection
            else:
                raise Error("Failed to establish database connection")
                
        except Error as e:
            logger.error(f"Database connection error: {e}")
            raise
        finally:
            if connection and connection.is_connected():
                connection.close()
    
    def execute_read_query(self, query: str, params: Optional[tuple] = None) -> List[Dict[str, Any]]:
        """
        Execute read-only SQL query and return results as list of dictionaries.
        
        Args:
            query: SQL SELECT query (validated to be read-only)
            params: Query parameters for safe parameterization
            
        Returns:
            List of dictionaries representing query results
            
        Raises:
            ValueError: If query contains non-SELECT operations
            Error: Database connection or execution errors
        """
        # Validate query is read-only (basic safety check)
        query_upper = query.strip().upper()
        allowed_starts = ['SELECT', 'SHOW', 'DESCRIBE', 'EXPLAIN']
        
        if not any(query_upper.startswith(start) for start in allowed_starts):
            raise ValueError("Only SELECT, SHOW, DESCRIBE, and EXPLAIN queries are allowed")
        
        # Additional safety: check for dangerous keywords
        dangerous_keywords = ['INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER', 'TRUNCATE']
        for keyword in dangerous_keywords:
            if keyword in query_upper:
                raise ValueError(f"Query contains forbidden keyword: {keyword}")
        
        with self.get_connection() as connection:
            cursor = connection.cursor(dictionary=True)
            try:
                cursor.execute(query, params)
                results = cursor.fetchall()
                return results
            finally:
                cursor.close()
    
    def test_connection(self) -> bool:
        """
        Test database connectivity.
        Returns True if connection successful, False otherwise.
        """
        try:
            with self.get_connection() as connection:
                cursor = connection.cursor()
                cursor.execute("SELECT 1")
                cursor.fetchone()
                cursor.close()
                return True
        except Error:
            return False

# Global database instance
db = DatabaseConnection()