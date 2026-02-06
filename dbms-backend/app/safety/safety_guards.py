"""
DBMS Safety Guards
Mandatory safety mechanisms to prevent dangerous operations.

This module implements hard safety guards that prevent any unsafe
database operations, ensuring academic and production safety.
"""

import logging
import re
from typing import List, Dict, Any, Optional
from enum import Enum

logger = logging.getLogger(__name__)

class SafetyViolationType(Enum):
    """Types of safety violations that can be detected."""
    DANGEROUS_SQL = "DANGEROUS_SQL"
    UNSAFE_ACTION = "UNSAFE_ACTION"
    DIRECT_EXECUTION = "DIRECT_EXECUTION"
    OS_COMMAND = "OS_COMMAND"
    CONNECTION_KILL = "CONNECTION_KILL"
    UNAUTHORIZED_WRITE = "UNAUTHORIZED_WRITE"

class SafetyViolation(Exception):
    """Exception raised when a safety violation is detected."""
    
    def __init__(self, violation_type: SafetyViolationType, message: str, context: Dict[str, Any] = None):
        self.violation_type = violation_type
        self.message = message
        self.context = context or {}
        super().__init__(f"SAFETY VIOLATION [{violation_type.value}]: {message}")

class SafetyGuards:
    """
    Comprehensive safety guard system for DBMS self-healing.
    
    Implements multiple layers of protection against dangerous operations:
    1. SQL injection and dangerous query prevention
    2. Action execution safety validation
    3. Connection and process protection
    4. OS command prevention
    5. Unauthorized write operation detection
    """
    
    # Dangerous SQL keywords that should never be executed directly
    DANGEROUS_SQL_KEYWORDS = [
        'DROP', 'DELETE', 'TRUNCATE', 'ALTER', 'CREATE',
        'KILL', 'SHUTDOWN', 'RESTART', 'FLUSH', 'RESET',
        'GRANT', 'REVOKE', 'SET GLOBAL', 'SET SESSION',
        'LOAD DATA', 'SELECT INTO OUTFILE', 'LOAD_FILE'
    ]
    
    # Dangerous action types that require special handling
    DANGEROUS_ACTIONS = [
        'KILL_CONNECTION', 'ROLLBACK_TRANSACTION', 'RETRY_OPERATION',
        'RESTART_SERVICE', 'FLUSH_TABLES', 'RESET_SLAVE'
    ]
    
    # OS commands that should never be executed
    DANGEROUS_OS_COMMANDS = [
        'rm', 'del', 'format', 'fdisk', 'mkfs', 'dd',
        'kill', 'killall', 'pkill', 'shutdown', 'reboot',
        'systemctl', 'service', 'net stop', 'net start'
    ]
    
    @classmethod
    def validate_sql_query(cls, query: str, allowed_operations: List[str] = None) -> None:
        """
        Validate that a SQL query is safe to execute.
        
        Args:
            query: SQL query to validate
            allowed_operations: List of allowed SQL operations (default: SELECT only)
            
        Raises:
            SafetyViolation: If query contains dangerous operations
        """
        if not query or not isinstance(query, str):
            raise SafetyViolation(
                SafetyViolationType.DANGEROUS_SQL,
                "Invalid or empty SQL query",
                {'query': query}
            )
        
        query_upper = query.strip().upper()
        allowed_operations = allowed_operations or ['SELECT', 'SHOW', 'DESCRIBE', 'EXPLAIN']
        
        # Check if query starts with allowed operation
        if not any(query_upper.startswith(op) for op in allowed_operations):
            raise SafetyViolation(
                SafetyViolationType.DANGEROUS_SQL,
                f"Query must start with one of: {', '.join(allowed_operations)}",
                {'query': query[:100], 'allowed_operations': allowed_operations}
            )
        
        # Check for dangerous keywords
        for keyword in cls.DANGEROUS_SQL_KEYWORDS:
            if keyword in query_upper:
                raise SafetyViolation(
                    SafetyViolationType.DANGEROUS_SQL,
                    f"Query contains dangerous keyword: {keyword}",
                    {'query': query[:100], 'dangerous_keyword': keyword}
                )
        
        # Check for SQL injection patterns
        injection_patterns = [
            r";\s*(DROP|DELETE|TRUNCATE|ALTER)",
            r"UNION\s+SELECT",
            r"--\s*$",
            r"/\*.*\*/",
            r"'\s*OR\s*'",
            r"'\s*AND\s*'"
        ]
        
        for pattern in injection_patterns:
            if re.search(pattern, query_upper):
                raise SafetyViolation(
                    SafetyViolationType.DANGEROUS_SQL,
                    f"Query contains potential SQL injection pattern",
                    {'query': query[:100], 'pattern': pattern}
                )
        
        logger.debug(f"SQL query validated as safe: {query[:50]}...")
    
    @classmethod
    def validate_healing_action(cls, action_type: str, execution_mode: str, context: Dict[str, Any] = None) -> None:
        """
        Validate that a healing action is safe to execute.
        
        Args:
            action_type: Type of healing action
            execution_mode: Mode of execution (must be SIMULATED for dangerous actions)
            context: Additional context for validation
            
        Raises:
            SafetyViolation: If action is unsafe
        """
        context = context or {}
        
        # All dangerous actions must be simulated
        if action_type in cls.DANGEROUS_ACTIONS:
            if execution_mode != 'SIMULATED':
                raise SafetyViolation(
                    SafetyViolationType.UNSAFE_ACTION,
                    f"Dangerous action '{action_type}' must be SIMULATED, got '{execution_mode}'",
                    {'action_type': action_type, 'execution_mode': execution_mode, 'context': context}
                )
        
        # Specific action validations
        if action_type == 'KILL_CONNECTION':
            if execution_mode != 'SIMULATED':
                raise SafetyViolation(
                    SafetyViolationType.CONNECTION_KILL,
                    "Connection termination must be simulated only",
                    {'action_type': action_type, 'execution_mode': execution_mode}
                )
        
        elif action_type == 'ROLLBACK_TRANSACTION':
            if execution_mode not in ['SIMULATED', 'MANUAL']:
                raise SafetyViolation(
                    SafetyViolationType.UNSAFE_ACTION,
                    "Transaction rollback must be simulated or manual only",
                    {'action_type': action_type, 'execution_mode': execution_mode}
                )
        
        logger.debug(f"Healing action validated as safe: {action_type} ({execution_mode})")
    
    @classmethod
    def validate_database_write(cls, operation: str, table: str, context: Dict[str, Any] = None) -> None:
        """
        Validate that a database write operation is authorized.
        
        Args:
            operation: Type of write operation (INSERT, UPDATE, DELETE)
            table: Target table name
            context: Additional context for validation
            
        Raises:
            SafetyViolation: If write operation is unauthorized
        """
        context = context or {}
        
        # Define authorized write operations
        authorized_writes = {
            'decision_log': ['INSERT'],
            'healing_actions': ['INSERT'],
            'admin_reviews': ['INSERT', 'UPDATE'],
            'learning_history': ['INSERT']
        }
        
        # Check if table allows writes
        if table not in authorized_writes:
            raise SafetyViolation(
                SafetyViolationType.UNAUTHORIZED_WRITE,
                f"Write operations not authorized for table: {table}",
                {'operation': operation, 'table': table, 'context': context}
            )
        
        # Check if operation is allowed for this table
        if operation not in authorized_writes[table]:
            raise SafetyViolation(
                SafetyViolationType.UNAUTHORIZED_WRITE,
                f"Operation '{operation}' not authorized for table '{table}'",
                {'operation': operation, 'table': table, 'authorized': authorized_writes[table]}
            )
        
        # Never allow writes to detected_issues (read-only)
        if table == 'detected_issues':
            raise SafetyViolation(
                SafetyViolationType.UNAUTHORIZED_WRITE,
                "Write operations forbidden on detected_issues table",
                {'operation': operation, 'table': table}
            )
        
        logger.debug(f"Database write validated as authorized: {operation} on {table}")
    
    @classmethod
    def validate_os_command(cls, command: str, context: Dict[str, Any] = None) -> None:
        """
        Validate that an OS command is safe (should always fail - no OS commands allowed).
        
        Args:
            command: OS command to validate
            context: Additional context
            
        Raises:
            SafetyViolation: Always - OS commands are never allowed
        """
        raise SafetyViolation(
            SafetyViolationType.OS_COMMAND,
            f"OS command execution is strictly forbidden: {command}",
            {'command': command, 'context': context or {}}
        )
    
    @classmethod
    def validate_direct_execution(cls, operation: str, context: Dict[str, Any] = None) -> None:
        """
        Validate that direct database execution is not attempted.
        
        Args:
            operation: Type of direct execution
            context: Additional context
            
        Raises:
            SafetyViolation: If direct execution is attempted
        """
        forbidden_operations = [
            'DIRECT_ROLLBACK', 'DIRECT_KILL', 'DIRECT_RESTART',
            'DIRECT_FLUSH', 'DIRECT_RESET', 'DIRECT_SHUTDOWN'
        ]
        
        if operation in forbidden_operations:
            raise SafetyViolation(
                SafetyViolationType.DIRECT_EXECUTION,
                f"Direct execution forbidden: {operation}",
                {'operation': operation, 'context': context or {}}
            )
        
        logger.debug(f"Direct execution check passed: {operation}")
    
    @classmethod
    def create_safety_report(cls) -> Dict[str, Any]:
        """
        Create a comprehensive safety report showing all active guards.
        
        Returns:
            Dictionary containing safety configuration and status
        """
        return {
            'timestamp': logger.handlers[0].formatter.formatTime(logger.makeRecord(
                'safety', logging.INFO, __file__, 0, '', (), None
            )) if logger.handlers else 'unknown',
            'safety_guards_active': True,
            'dangerous_sql_keywords': len(cls.DANGEROUS_SQL_KEYWORDS),
            'dangerous_actions': len(cls.DANGEROUS_ACTIONS),
            'dangerous_os_commands': len(cls.DANGEROUS_OS_COMMANDS),
            'protection_levels': {
                'sql_injection_protection': True,
                'dangerous_keyword_blocking': True,
                'action_execution_validation': True,
                'os_command_blocking': True,
                'unauthorized_write_prevention': True,
                'direct_execution_prevention': True
            },
            'authorized_operations': {
                'sql_read_operations': ['SELECT', 'SHOW', 'DESCRIBE', 'EXPLAIN'],
                'authorized_write_tables': ['decision_log', 'healing_actions', 'admin_reviews', 'learning_history'],
                'forbidden_write_tables': ['detected_issues', 'ai_analysis'],
                'simulation_only_actions': cls.DANGEROUS_ACTIONS
            },
            'safety_guarantees': [
                'No direct database mutations on detected_issues',
                'All dangerous actions are simulated only',
                'No OS command execution allowed',
                'SQL injection protection active',
                'Unauthorized write operations blocked',
                'Connection termination simulated only'
            ]
        }

class SafetyDecorator:
    """
    Decorator class for adding safety validation to functions.
    """
    
    @staticmethod
    def validate_sql(allowed_operations: List[str] = None):
        """
        Decorator to validate SQL queries in function arguments.
        
        Args:
            allowed_operations: List of allowed SQL operations
        """
        def decorator(func):
            def wrapper(*args, **kwargs):
                # Look for 'query' parameter
                if 'query' in kwargs:
                    SafetyGuards.validate_sql_query(kwargs['query'], allowed_operations)
                elif len(args) > 0 and isinstance(args[0], str):
                    SafetyGuards.validate_sql_query(args[0], allowed_operations)
                
                return func(*args, **kwargs)
            return wrapper
        return decorator
    
    @staticmethod
    def validate_action(func):
        """
        Decorator to validate healing actions in function arguments.
        """
        def wrapper(*args, **kwargs):
            if 'action_type' in kwargs and 'execution_mode' in kwargs:
                SafetyGuards.validate_healing_action(
                    kwargs['action_type'], 
                    kwargs['execution_mode'],
                    kwargs.get('context', {})
                )
            
            return func(*args, **kwargs)
        return wrapper
    
    @staticmethod
    def prevent_os_commands(func):
        """
        Decorator to prevent any OS command execution.
        """
        def wrapper(*args, **kwargs):
            # Check for common OS command parameters
            dangerous_params = ['command', 'cmd', 'shell_command', 'os_command']
            for param in dangerous_params:
                if param in kwargs:
                    SafetyGuards.validate_os_command(kwargs[param])
            
            return func(*args, **kwargs)
        return wrapper

# Global safety validation function
def enforce_safety_check(operation_type: str, **kwargs) -> None:
    """
    Global safety check function that can be called from anywhere.
    
    Args:
        operation_type: Type of operation to validate
        **kwargs: Operation-specific parameters
        
    Raises:
        SafetyViolation: If operation is unsafe
    """
    if operation_type == 'sql_query':
        SafetyGuards.validate_sql_query(
            kwargs.get('query', ''),
            kwargs.get('allowed_operations')
        )
    
    elif operation_type == 'healing_action':
        SafetyGuards.validate_healing_action(
            kwargs.get('action_type', ''),
            kwargs.get('execution_mode', ''),
            kwargs.get('context', {})
        )
    
    elif operation_type == 'database_write':
        SafetyGuards.validate_database_write(
            kwargs.get('operation', ''),
            kwargs.get('table', ''),
            kwargs.get('context', {})
        )
    
    elif operation_type == 'os_command':
        SafetyGuards.validate_os_command(
            kwargs.get('command', ''),
            kwargs.get('context', {})
        )
    
    elif operation_type == 'direct_execution':
        SafetyGuards.validate_direct_execution(
            kwargs.get('operation', ''),
            kwargs.get('context', {})
        )
    
    else:
        logger.warning(f"Unknown safety check operation type: {operation_type}")

# Initialize safety guards on module import
logger.info("DBMS Safety Guards initialized - All dangerous operations blocked")
logger.info(f"Protected against {len(SafetyGuards.DANGEROUS_SQL_KEYWORDS)} dangerous SQL keywords")
logger.info(f"Protected against {len(SafetyGuards.DANGEROUS_ACTIONS)} dangerous actions")
logger.info(f"Protected against {len(SafetyGuards.DANGEROUS_OS_COMMANDS)} dangerous OS commands")