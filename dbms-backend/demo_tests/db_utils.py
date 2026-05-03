import mysql.connector
import os
import time
from datetime import datetime

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    BOLD = '\033[1m'
    RESET = '\033[0m'

def get_connection():
    return mysql.connector.connect(
        host=os.getenv('DB_HOST', '127.0.0.1'),
        user=os.getenv('DB_USER', 'root'),
        password=os.getenv('DB_PASSWORD', 'Tsr@2007'),
        database=os.getenv('DB_NAME', 'dbms_self_healing'),
        autocommit=True
    )

def run_query(sql, params=None):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, params or ())
        conn.commit()
    finally:
        cursor.close()
        conn.close()

def insert_and_get_id(sql, params=None):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, params or ())
        conn.commit()
        return cursor.lastrowid
    finally:
        cursor.close()
        conn.close()

def fetch_one(sql, params=None):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(sql, params or ())
        rows = cursor.fetchall()
        return rows[0] if rows else None
    finally:
        cursor.close()
        conn.close()

def fetch_all(sql, params=None):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(sql, params or ())
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()

def print_section(title):
    print(f"\n{Colors.CYAN}{'='*60}")
    print(f" {title} ")
    print(f"{'='*60}{Colors.RESET}\n")

def reset_system_state():
    """Kill all non-system connections and clear all issue-related tables for a clean demo."""
    log_step("Resetting system state (killing all non-system connections)...", "INFO")
    
    # 1. Kill connections
    connections = fetch_all("SELECT id FROM information_schema.processlist WHERE id != CONNECTION_ID() AND user NOT IN ('system user', 'event_scheduler')")
    for conn in connections:
        try:
            run_query(f"KILL {conn['id']}")
        except:
            pass
            
    # 2. Truncate tables (order is important due to FKs)
    log_step("Clearing all monitoring and decision history...", "INFO")
    tables = [
        'failure_log', 'execution_context', 'execution_queue', 
        'healing_actions', 'admin_reviews', 'decision_log', 
        'ai_analysis', 'detected_issues', 'debug_log'
    ]
    run_query("SET FOREIGN_KEY_CHECKS = 0")
    for table in tables:
        try:
            run_query(f"TRUNCATE TABLE {table}")
        except:
            pass
    run_query("SET FOREIGN_KEY_CHECKS = 1")
    log_step("System reset complete.", "PASS")

def trigger_self_healing(issue_id):
    """Manually trigger the full self-healing pipeline for a specific issue."""
    log_step(f"Manually triggering healing pipeline for issue {issue_id}...", "INFO")
    run_query("CALL run_ai_analysis(%s)", (issue_id,))
    run_query("CALL make_decision(%s)", (issue_id,))
    run_query("CALL run_execution_worker(%s)", ("DEMO_WORKER",))
    run_query("CALL run_verification_worker()")
    # Give it a moment for sync procedures (especially 2s verification sleep) to finalize state
    time.sleep(4)

def log_step(msg, status="INFO"):
    timestamp = datetime.now().strftime("%H:%M:%S")
    if status == "PASS":
        print(f"[{timestamp}] {Colors.GREEN}[PASS] {msg}{Colors.RESET}")
    elif status == "FAIL":
        print(f"[{timestamp}] {Colors.RED}[FAIL] {msg}{Colors.RESET}")
    elif status == "WARN":
        print(f"[{timestamp}] {Colors.YELLOW}[WARN] {msg}{Colors.RESET}")
    else:
        print(f"[{timestamp}] [INFO] {msg}")
