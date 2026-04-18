"""
Database connection management for DBMS self-healing system.
Uses a connection pool for efficient, low-latency access.
"""

import os
import mysql.connector
from mysql.connector import Error, pooling
from typing import Optional, List, Dict, Any
import logging

logger = logging.getLogger(__name__)

class DatabaseConnection:
    """
    Manages a MySQL connection pool for DBMS pipeline data.
    Uses pooling to eliminate per-request connection overhead.
    """

    def __init__(self):
        from dotenv import load_dotenv
        load_dotenv()

        self._pool: Optional[pooling.MySQLConnectionPool] = None
        self.config = {
            'host': os.getenv('DB_HOST', 'localhost'),
            'port': int(os.getenv('DB_PORT', 3306)),
            'user': os.getenv('DB_USER', 'root'),
            'password': os.getenv('DB_PASSWORD', ''),
            'database': os.getenv('DB_NAME'),
            'autocommit': False,
            'use_pure': True,
        }

        debug_config = self.config.copy()
        debug_config['password'] = '*' * len(debug_config['password']) if debug_config['password'] else 'EMPTY'
        logger.info(f"Database config: {debug_config}")
        self._init_pool()

    def _init_pool(self):
        """Initialize connection pool (size=5) so connections are reused."""
        try:
            self._pool = pooling.MySQLConnectionPool(
                pool_name='dbms_pool',
                pool_size=5,
                **self.config
            )
            logger.info("Connection pool initialized (size=5)")
        except Error as e:
            logger.error(f"Failed to create connection pool: {e}")
            self._pool = None

    def _get_conn(self):
        """Get a connection from the pool, falling back to direct connect."""
        if self._pool:
            return self._pool.get_connection()
        return mysql.connector.connect(**self.config)

    def execute_read_query(self, query: str, params: Optional[tuple] = None) -> List[Dict[str, Any]]:
        """
        Execute a read SQL query and return results as list of dicts.
        Only SELECT/SHOW/DESCRIBE/EXPLAIN are permitted.
        """
        query_upper = query.strip().upper()
        allowed_starts = ['SELECT', 'SHOW', 'DESCRIBE', 'EXPLAIN']
        if not any(query_upper.startswith(s) for s in allowed_starts):
            raise ValueError("Only SELECT, SHOW, DESCRIBE, and EXPLAIN queries are allowed")

        dangerous_keywords = ['INSERT', 'UPDATE', 'DELETE', 'DROP', 'CREATE', 'ALTER', 'TRUNCATE']
        for kw in dangerous_keywords:
            if kw in query_upper:
                raise ValueError(f"Query contains forbidden keyword: {kw}")

        conn = self._get_conn()
        try:
            cursor = conn.cursor(dictionary=True)
            cursor.execute(query, params)
            results = cursor.fetchall()
            cursor.close()
            return results
        finally:
            conn.close()  # returns to pool if pooled

    def execute_write_query(self, query: str, params: Optional[tuple] = None) -> int:
        """
        Execute a write SQL query and return rows affected.
        """
        conn = self._get_conn()
        try:
            cursor = conn.cursor()
            cursor.execute(query, params)
            conn.commit()
            rows = cursor.rowcount
            cursor.close()
            return rows
        except Exception as e:
            conn.rollback()
            logger.error(f"Write query failed: {e}")
            raise
        finally:
            conn.close()  # returns to pool if pooled

    def test_connection(self) -> bool:
        """Test database connectivity."""
        try:
            conn = self._get_conn()
            cursor = conn.cursor()
            cursor.execute("SELECT 1")
            cursor.fetchone()
            cursor.close()
            conn.close()
            return True
        except Error:
            return False


# Global database instance
db = DatabaseConnection()