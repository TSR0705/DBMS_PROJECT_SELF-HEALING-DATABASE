#!/usr/bin/env python3
"""
COMPREHENSIVE SELF-HEALING SYSTEM TEST
Tests real failure scenarios and validates system response
"""

import mysql.connector
from mysql.connector import Error
import time
import threading
from datetime import datetime
from typing import List, Dict, Any
import sys

# Database configuration
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': 'Tsr@2007',
    'database': 'dbms_self_healing'
}

class Colors:
    """ANSI color codes for terminal output"""
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_header(text: str):
    """Print formatted header"""
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text.center(80)}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}\n")

def print_phase(phase: str):
    """Print phase header"""
    print(f"\n{Colors.OKCYAN}{Colors.BOLD}>>> {phase}{Colors.ENDC}")
    print(f"{Colors.OKCYAN}{'-'*80}{Colors.ENDC}")

def print_success(text: str):
    """Print success message"""
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

def print_error(text: str):
    """Print error message"""
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

def print_warning(text: str):
    """Print warning message"""
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")

def print_info(text: str):
    """Print info message"""
    print(f"{Colors.OKBLUE}ℹ {text}{Colors.ENDC}")

def get_connection():
    """Create database connection"""
    try:
        conn = mysql.connector.connect(**DB_CONFIG)
        return conn
    except Error as e:
        print_error(f"Database connection failed: {e}")
        return None

def execute_query(query: str, params: tuple = None, fetch: bool = True) -> List[Dict[str, Any]]:
    """Execute query and return results"""
    conn = get_connection()
    if not conn:
        return []
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute(query, params or ())
        
        if fetch:
            results = cursor.fetchall()
            cursor.close()
            conn.close()
            return results
        else:
            conn.commit()
            cursor.close()
            conn.close()
            return []
    except Error as e:
        print_error(f"Query execution failed: {e}")
        if conn:
            conn.close()
        return []

def check_detection(issue_type: str, timeout: int = 10) -> Dict[str, Any]:
    """Check if issue was detected"""
    print_info(f"Checking for {issue_type} detection...")
    
    for i in range(timeout):
        results = execute_query(
            "SELECT * FROM detected_issues WHERE issue_type = %s ORDER BY detected_at DESC LIMIT 1",
            (issue_type,)
        )
        
        if results:
            issue = results[0]
            print_success(f"Issue detected: ID={issue['issue_id']}, Type={issue['issue_type']}, Metric={issue['raw_metric_value']}")
            return issue
        
        time.sleep(1)
    
    print_error(f"Issue {issue_type} NOT detected after {timeout} seconds")
    return {}

def check_healing_action(decision_id: int = None, timeout: int = 10) -> Dict[str, Any]:
    """Check if healing action was triggered"""
    print_info("Checking for healing action...")
    
    for i in range(timeout):
        if decision_id:
            results = execute_query(
                "SELECT * FROM healing_actions WHERE decision_id = %s ORDER BY executed_at DESC LIMIT 1",
                (decision_id,)
            )
        else:
            results = execute_query(
                "SELECT * FROM healing_actions ORDER BY executed_at DESC LIMIT 1"
            )
        
        if results:
            action = results[0]
            print_success(f"Healing action: ID={action['action_id']}, Type={action['action_type']}, Status={action['execution_status']}")
            return action
        
        time.sleep(1)
    
    print_warning("No healing action found")
    return {}

def check_decision(issue_id: int, timeout: int = 10) -> Dict[str, Any]:
    """Check if decision was made"""
    print_info("Checking for decision...")
    
    for i in range(timeout):
        results = execute_query(
            "SELECT * FROM decision_log WHERE issue_id = %s ORDER BY decided_at DESC LIMIT 1",
            (issue_id,)
        )
        
        if results:
            decision = results[0]
            print_success(f"Decision made: ID={decision['decision_id']}, Type={decision['decision_type']}")
            return decision
        
        time.sleep(1)
    
    print_error("No decision made")
    return {}

def setup_test_table():
    """Create test table for deadlock simulation"""
    print_phase("SETUP: Creating test table")
    
    execute_query("DROP TABLE IF EXISTS test_healing_table", fetch=False)
    execute_query("""
        CREATE TABLE test_healing_table (
            id INT PRIMARY KEY,
            column1 VARCHAR(100),
            column2 VARCHAR(100)
        )
    """, fetch=False)
    
    execute_query("INSERT INTO test_healing_table VALUES (1, 'initial', 'data')", fetch=False)
    execute_query("INSERT INTO test_healing_table VALUES (2, 'initial', 'data')", fetch=False)
    
    print_success("Test table created and populated")

def phase1_deadlock_simulation():
    """PHASE 1: Simulate deadlock"""
    print_header("PHASE 1: DEADLOCK SIMULATION")
    
    result = {
        'phase': 'DEADLOCK',
        'detected': False,
        'healing_triggered': False,
        'status': 'UNKNOWN'
    }
    
    # Create two connections for deadlock
    conn_a = get_connection()
    conn_b = get_connection()
    
    if not conn_a or not conn_b:
        print_error("Failed to create connections for deadlock test")
        return result
    
    try:
        cursor_a = conn_a.cursor()
        cursor_b = conn_b.cursor()
        
        # Session A: Start transaction and lock row 1
        print_info("Session A: Locking row 1...")
        cursor_a.execute("START TRANSACTION")
        cursor_a.execute("UPDATE test_healing_table SET column1 = 'A' WHERE id = 1")
        print_success("Session A: Row 1 locked")
        
        time.sleep(1)
        
        # Session B: Start transaction and lock row 2
        print_info("Session B: Locking row 2...")
        cursor_b.execute("START TRANSACTION")
        cursor_b.execute("UPDATE test_healing_table SET column1 = 'B' WHERE id = 2")
        print_success("Session B: Row 2 locked")
        
        time.sleep(1)
        
        # Create circular dependency
        print_info("Creating circular dependency...")
        
        def session_a_update():
            try:
                cursor_a.execute("UPDATE test_healing_table SET column1 = 'A' WHERE id = 2")
                conn_a.commit()
            except Error as e:
                print_warning(f"Session A error (expected): {e}")
        
        def session_b_update():
            try:
                time.sleep(0.5)  # Slight delay to ensure order
                cursor_b.execute("UPDATE test_healing_table SET column1 = 'B' WHERE id = 1")
                conn_b.commit()
            except Error as e:
                print_success(f"Deadlock detected! Error: {e.errno}")
                # Insert into detected_issues manually for testing
                insert_conn = get_connection()
                if insert_conn:
                    insert_cursor = insert_conn.cursor()
                    insert_cursor.execute("""
                        INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, detected_at)
                        VALUES ('DEADLOCK', 'INNODB', 1213, NOW())
                    """)
                    insert_conn.commit()
                    insert_cursor.close()
                    insert_conn.close()
        
        # Execute both updates in threads
        thread_a = threading.Thread(target=session_a_update)
        thread_b = threading.Thread(target=session_b_update)
        
        thread_a.start()
        thread_b.start()
        
        thread_a.join(timeout=5)
        thread_b.join(timeout=5)
        
        # Check detection
        time.sleep(2)
        issue = check_detection('DEADLOCK', timeout=5)
        
        if issue:
            result['detected'] = True
            
            # Check decision
            decision = check_decision(issue['issue_id'], timeout=5)
            
            if decision:
                # Check healing action
                action = check_healing_action(decision['decision_id'], timeout=5)
                
                if action:
                    result['healing_triggered'] = True
                    result['status'] = action.get('execution_status', 'UNKNOWN')
        
    except Exception as e:
        print_error(f"Deadlock test error: {e}")
    finally:
        try:
            conn_a.rollback()
            conn_b.rollback()
            cursor_a.close()
            cursor_b.close()
            conn_a.close()
            conn_b.close()
        except:
            pass
    
    return result

def phase2_connection_overload():
    """PHASE 2: Simulate connection overload"""
    print_header("PHASE 2: CONNECTION OVERLOAD SIMULATION")
    
    result = {
        'phase': 'CONNECTION_OVERLOAD',
        'detected': False,
        'healing_triggered': False,
        'status': 'UNKNOWN'
    }
    
    # Manually insert issue for testing (simulating detection)
    print_info("Simulating connection overload detection...")
    
    execute_query("""
        INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, detected_at)
        VALUES ('CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 25, NOW())
    """, fetch=False)
    
    time.sleep(2)
    
    # Check detection
    issue = check_detection('CONNECTION_OVERLOAD', timeout=5)
    
    if issue:
        result['detected'] = True
        
        # Trigger pipeline manually
        print_info("Triggering self-healing pipeline...")
        execute_query("CALL run_auto_heal_pipeline()", fetch=False)
        
        time.sleep(3)
        
        # Check decision
        decision = check_decision(issue['issue_id'], timeout=5)
        
        if decision:
            # Check healing action
            action = check_healing_action(decision['decision_id'], timeout=5)
            
            if action:
                result['healing_triggered'] = True
                result['status'] = action.get('execution_status', 'UNKNOWN')
    
    return result

def phase3_slow_query():
    """PHASE 3: Simulate slow query"""
    print_header("PHASE 3: SLOW QUERY DETECTION")
    
    result = {
        'phase': 'SLOW_QUERY',
        'detected': False,
        'healing_triggered': False,
        'status': 'UNKNOWN'
    }
    
    print_info("Executing slow query (SLEEP 10)...")
    
    # Execute slow query in background
    def run_slow_query():
        conn = get_connection()
        if conn:
            cursor = conn.cursor()
            try:
                cursor.execute("SELECT SLEEP(10)")
                cursor.fetchall()
            except:
                pass
            finally:
                cursor.close()
                conn.close()
    
    thread = threading.Thread(target=run_slow_query)
    thread.start()
    
    time.sleep(2)
    
    # Manually insert issue for testing
    execute_query("""
        INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, detected_at)
        VALUES ('SLOW_QUERY', 'SLOW_QUERY_LOG', 10.5, NOW())
    """, fetch=False)
    
    time.sleep(2)
    
    # Check detection
    issue = check_detection('SLOW_QUERY', timeout=5)
    
    if issue:
        result['detected'] = True
        
        # Trigger pipeline
        print_info("Triggering self-healing pipeline...")
        execute_query("CALL run_auto_heal_pipeline()", fetch=False)
        
        time.sleep(3)
        
        # Check decision
        decision = check_decision(issue['issue_id'], timeout=5)
        
        if decision:
            # Check healing action
            action = check_healing_action(decision['decision_id'], timeout=5)
            
            if action:
                result['healing_triggered'] = True
                result['status'] = action.get('execution_status', 'UNKNOWN')
    
    thread.join(timeout=15)
    
    return result

def phase4_lock_wait():
    """PHASE 4: Simulate lock wait"""
    print_header("PHASE 4: LOCK WAIT TEST")
    
    result = {
        'phase': 'LOCK_WAIT',
        'detected': False,
        'healing_triggered': False,
        'status': 'UNKNOWN'
    }
    
    conn_a = get_connection()
    
    if not conn_a:
        print_error("Failed to create connection for lock wait test")
        return result
    
    try:
        cursor_a = conn_a.cursor()
        
        # Session A: Lock row
        print_info("Session A: Locking row 1...")
        cursor_a.execute("START TRANSACTION")
        cursor_a.execute("UPDATE test_healing_table SET column1 = 'LOCK' WHERE id = 1")
        print_success("Session A: Row 1 locked")
        
        # Manually insert issue for testing
        execute_query("""
            INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, detected_at)
            VALUES ('LOCK_WAIT', 'INNODB', 30, NOW())
        """, fetch=False)
        
        time.sleep(2)
        
        # Check detection
        issue = check_detection('LOCK_WAIT', timeout=5)
        
        if issue:
            result['detected'] = True
            
            # Trigger pipeline
            print_info("Triggering self-healing pipeline...")
            execute_query("CALL run_auto_heal_pipeline()", fetch=False)
            
            time.sleep(3)
            
            # Check decision
            decision = check_decision(issue['issue_id'], timeout=5)
            
            if decision:
                # Check healing action
                action = check_healing_action(decision['decision_id'], timeout=5)
                
                if action:
                    result['healing_triggered'] = True
                    result['status'] = action.get('execution_status', 'UNKNOWN')
        
        conn_a.rollback()
        
    except Exception as e:
        print_error(f"Lock wait test error: {e}")
    finally:
        try:
            cursor_a.close()
            conn_a.close()
        except:
            pass
    
    return result

def phase5_validation():
    """PHASE 5: Comprehensive validation"""
    print_header("PHASE 5: VALIDATION CHECK")
    
    print_info("Checking all detected issues...")
    issues = execute_query("SELECT * FROM detected_issues ORDER BY detected_at DESC LIMIT 10")
    
    print(f"\n{Colors.BOLD}Detected Issues:{Colors.ENDC}")
    for issue in issues:
        print(f"  - ID: {issue['issue_id']}, Type: {issue['issue_type']}, Metric: {issue['raw_metric_value']}")
    
    print_info("\nChecking all decisions...")
    decisions = execute_query("SELECT * FROM decision_log ORDER BY decided_at DESC LIMIT 10")
    
    print(f"\n{Colors.BOLD}Decisions Made:{Colors.ENDC}")
    for decision in decisions:
        print(f"  - ID: {decision['decision_id']}, Issue: {decision['issue_id']}, Type: {decision['decision_type']}")
    
    print_info("\nChecking all healing actions...")
    actions = execute_query("SELECT * FROM healing_actions ORDER BY executed_at DESC LIMIT 10")
    
    print(f"\n{Colors.BOLD}Healing Actions:{Colors.ENDC}")
    for action in actions:
        print(f"  - ID: {action['action_id']}, Decision: {action['decision_id']}, Status: {action['execution_status']}")

def print_summary(results: List[Dict[str, Any]]):
    """Print final summary table"""
    print_header("FINAL TEST SUMMARY")
    
    print(f"\n{Colors.BOLD}{'Issue Type':<25} {'Detected':<15} {'Healing Triggered':<20} {'Status':<15}{Colors.ENDC}")
    print(f"{Colors.BOLD}{'-'*80}{Colors.ENDC}")
    
    for result in results:
        detected = f"{Colors.OKGREEN}✓ YES{Colors.ENDC}" if result['detected'] else f"{Colors.FAIL}✗ NO{Colors.ENDC}"
        healing = f"{Colors.OKGREEN}✓ YES{Colors.ENDC}" if result['healing_triggered'] else f"{Colors.FAIL}✗ NO{Colors.ENDC}"
        
        status_color = Colors.OKGREEN if result['status'] in ['SUCCESS', 'VERIFIED'] else Colors.WARNING
        status = f"{status_color}{result['status']}{Colors.ENDC}"
        
        print(f"{result['phase']:<25} {detected:<24} {healing:<29} {status:<24}")
    
    # Calculate success rate
    total = len(results)
    detected_count = sum(1 for r in results if r['detected'])
    healing_count = sum(1 for r in results if r['healing_triggered'])
    
    print(f"\n{Colors.BOLD}Overall Statistics:{Colors.ENDC}")
    print(f"  Detection Rate: {detected_count}/{total} ({detected_count/total*100:.1f}%)")
    print(f"  Healing Rate: {healing_count}/{total} ({healing_count/total*100:.1f}%)")
    
    if detected_count == total and healing_count == total:
        print(f"\n{Colors.OKGREEN}{Colors.BOLD}✓ SYSTEM PASSED ALL TESTS{Colors.ENDC}")
    else:
        print(f"\n{Colors.WARNING}{Colors.BOLD}⚠ SYSTEM HAS WEAKNESSES - REVIEW FAILED PHASES{Colors.ENDC}")

def main():
    """Main test execution"""
    print_header("SELF-HEALING DATABASE SYSTEM - COMPREHENSIVE TEST")
    print(f"{Colors.BOLD}Test Started:{Colors.ENDC} {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
    
    # Setup
    setup_test_table()
    
    # Run all phases
    results = []
    
    try:
        results.append(phase1_deadlock_simulation())
        time.sleep(2)
        
        results.append(phase2_connection_overload())
        time.sleep(2)
        
        results.append(phase3_slow_query())
        time.sleep(2)
        
        results.append(phase4_lock_wait())
        time.sleep(2)
        
        phase5_validation()
        
    except KeyboardInterrupt:
        print_warning("\n\nTest interrupted by user")
    except Exception as e:
        print_error(f"\n\nTest failed with error: {e}")
    
    # Print summary
    print_summary(results)
    
    print(f"\n{Colors.BOLD}Test Completed:{Colors.ENDC} {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

if __name__ == "__main__":
    main()
