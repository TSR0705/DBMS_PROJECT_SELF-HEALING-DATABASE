"""
Database connection management for DBMS self-healing system.
Uses a connection pool for efficient, low-latency access.
"""

import os
import mysql.connector
from mysql.connector import Error, pooling
from typing import Optional, List, Dict, Any
import logging
from ..safety.safety_guards import SafetyGuards

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

        self.pool_size = int(os.getenv('DB_POOL_SIZE', 10))
        debug_config = self.config.copy()
        debug_config['password'] = '*' * len(debug_config['password']) if debug_config['password'] else 'EMPTY'
        logger.info(f"Database config: {debug_config} (Pool size: {self.pool_size})")
        self._init_pool()

    def _init_pool(self):
        """Initialize connection pool so connections are reused."""
        try:
            self._pool = pooling.MySQLConnectionPool(
                pool_name='dbms_pool',
                pool_size=self.pool_size,
                **self.config
            )
            logger.info(f"Connection pool initialized (size={self.pool_size})")
        except Error as e:
            logger.error(f"Failed to create connection pool: {e}")
            self._pool = None

    def get_connection(self):
        """
        Public method to get a connection from the pool.
        Supports usage as a context manager: 'with db.get_connection() as conn:'
        """
        if not self._pool:
            self._init_pool()
            
        try:
            conn = self._pool.get_connection()
            return conn
        except Exception as e:
            logger.warning(f"Pool exhausted or failed, falling back to direct connection: {e}")
            return mysql.connector.connect(**self.config)

    def _get_conn(self):
        """Internal helper for backward compatibility."""
        return self.get_connection()

    def execute_read_query(self, query: str, params: Optional[tuple] = None) -> List[Dict[str, Any]]:
        """
        Execute a read SQL query and return results as list of dicts.
        Only SELECT/SHOW/DESCRIBE/EXPLAIN are permitted.
        """
        # Centralized safety check
        SafetyGuards.validate_sql_query(query, allowed_operations=['SELECT', 'SHOW', 'DESCRIBE', 'EXPLAIN'])

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
        # Centralized safety check for writes
        SafetyGuards.validate_sql_query(query, allowed_operations=['INSERT', 'UPDATE'])
        
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

    def get_pool_status(self) -> Dict[str, Any]:
        """Get current status of the connection pool."""
        if not self._pool:
            return {'status': 'inactive', 'pool_size': self.pool_size}
            
        try:
            # pooling.MySQLConnectionPool doesn't give easy way to see 'active' connections
            # but we can report the size and that it's initialized
            return {
                'status': 'active',
                'pool_name': self._pool.pool_name,
                'pool_size': self.pool_size
            }
        except Exception as e:
            return {'status': 'error', 'error': str(e)}

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