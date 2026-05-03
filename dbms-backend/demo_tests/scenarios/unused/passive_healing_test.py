import time
import threading
import sys
import os

# Adjust path to allow importing from parent directory
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from demo_tests.db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id

def background_slow_query():
    conn = get_connection()
    cursor = conn.cursor()
    try:
        # Use a very obvious comment for tracking
        cursor.execute("SELECT SLEEP(60) /* PASSIVE_DEMO_QUERY */")
    except Exception:
        pass
    finally:
        cursor.close()
        conn.close()

def run_passive_demo():
    log_step("Starting PASSIVE_HEALING Proof (Autonomous Mode)")
    
    # 1. Create a real problem
    t = threading.Thread(target=background_slow_query, daemon=True)
    t.start()
    log_step("Waiting 12 seconds for query to mature (threshold is 10s)...", "WARN")
    time.sleep(12)
    
    q = fetch_one("SELECT id FROM information_schema.processlist WHERE info LIKE '%PASSIVE_DEMO_QUERY%'")
    if not q:
        log_step("Failed to start background query. Ensure DB is accessible.", "FAIL")
        return False
        
    pid = q['id']
    log_step(f"Real slow query running at PID: {pid}")

    # 2. Inject issue and STOP. We do NOT call any procedures from Python.
    log_step("Injecting issue into DB. We will NOT call any fix procedures from this script.")
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) "
        "VALUES ('SLOW_QUERY', 'PERFORMANCE_SCHEMA', 30.0)"
    )
    log_step(f"Issue injected (ID: {issue_id}). Stepping back to observe...")

    # 3. Wait for the 1-second Event Scheduler to find it
    log_step("Waiting for the background MySQL Event Scheduler to pick up the task...")
    
    found_fix = False
    for i in range(15):
        time.sleep(1)
        # Check if query is still there
        q_check = fetch_one("SELECT id FROM information_schema.processlist WHERE id = %s", (pid,))
        
        # Check if analysis has started
        analysis = fetch_one("SELECT * FROM ai_analysis WHERE issue_id = %s", (issue_id,))
        status_msg = "Waiting..."
        if analysis:
            status_msg = f"Analysis Found (Confidence: {float(analysis['confidence_score']):.2f})"
            
        if not q_check:
            print(f"\n[{time.strftime('%H:%M:%S')}] {status_msg}")
            log_step(f"SUCCESS! Background engine detected and killed PID {pid} automatically.", "PASS")
            
            # Final verification of logs
            action = fetch_one(
                "SELECT ha.* FROM healing_actions ha "
                "JOIN decision_log dl ON ha.decision_id = dl.decision_id "
                "WHERE dl.issue_id = %s", (issue_id,)
            )
            if action:
                log_step(f"Healing Action recorded: {action['action_type']} (Status: {action['execution_status']})", "PASS")
                log_step(f"Executed by: {action['executed_by']} (Orchestrated by Event Scheduler)", "PASS")
            found_fix = True
            break
        else:
            print(f"  [Wait {i+1}s] {status_msg} | PID {pid} still active...")

    if not found_fix:
        log_step("FAIL: Background engine did not respond in time. Ensure 'event_scheduler' is ON.", "FAIL")
        return False
    return True

if __name__ == "__main__":
    run_passive_demo()
