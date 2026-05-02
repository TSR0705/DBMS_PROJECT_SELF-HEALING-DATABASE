import time
import threading
import sys
import os

# Adjust path to allow importing from parent directory
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from demo_tests.db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id

def background_query():
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT SLEEP(60) /* PASSIVE_OVERLOAD_DEMO */")
    except Exception:
        pass
    finally:
        cursor.close()
        conn.close()

def run_passive_overload_demo():
    log_step("Starting PASSIVE_OVERLOAD Proof (Autonomous Orchestration)")
    
    # 1. Create a real overload (12 queries)
    log_step("Spawning 12 background queries to trigger overload...")
    for _ in range(12):
        t = threading.Thread(target=background_query, daemon=True)
        t.start()
    
    time.sleep(3)
    
    active_q = fetch_one("SELECT COUNT(*) as c FROM information_schema.processlist WHERE info LIKE '%PASSIVE_OVERLOAD_DEMO%'")
    before_count = active_q['c']
    log_step(f"Current active queries: {before_count}")

    if before_count < 10:
        log_step("Failed to create enough load. Check DB max_connections.", "FAIL")
        return False

    # 2. Inject issue and WAIT
    log_step("Injecting CONNECTION_OVERLOAD issue. Background engine will handle the iterative kill.")
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) "
        "VALUES ('CONNECTION_OVERLOAD', 'INNODB', %s)", (float(before_count),)
    )

    # 3. Watch the background iterative kill loop
    log_step("Waiting for background Event Scheduler to trigger the Iterative Kill Loop...")
    
    for i in range(20):
        time.sleep(1)
        active_q_now = fetch_one("SELECT COUNT(*) as c FROM information_schema.processlist WHERE info LIKE '%PASSIVE_OVERLOAD_DEMO%'")
        count_now = active_q_now['c'] if active_q_now else 0
        
        # Check analysis/decision
        decision = fetch_one("SELECT * FROM decision_log WHERE issue_id = %s", (issue_id,))
        status = "Waiting for Analysis..."
        if decision:
            status = f"Decision: {decision['decision_type']}"

        if count_now < before_count:
            log_step(f"OBSERVED: Background engine is killing queries! (Reduced: {before_count} -> {count_now})", "PASS")
            if count_now <= 5:
                log_step("SUCCESS! Background engine successfully reduced load to safe levels.", "PASS")
                
                # Verify logs
                action = fetch_one(
                    "SELECT ha.* FROM healing_actions ha "
                    "JOIN decision_log dl ON ha.decision_id = dl.decision_id "
                    "WHERE dl.issue_id = %s", (issue_id,)
                )
                if action:
                    log_step(f"Healing Action: {action['action_type']} | Status: {action['execution_status']}", "PASS")
                return True
        
        print(f"  [Wait {i+1}s] {status} | Active: {count_now}")

    log_step("FAIL: Background engine did not respond in time.", "FAIL")
    return False

if __name__ == "__main__":
    run_passive_overload_demo()
