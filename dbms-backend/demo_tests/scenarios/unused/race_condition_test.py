import time
import threading
from ..db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id

def run_race_condition_test():
    log_step("Starting RACE_CONDITION Timing Test")
    
    # 1. Start a slow query
    def slow_task():
        try:
            conn = get_connection()
            cursor = conn.cursor()
            try:
                cursor.execute("SELECT SLEEP(10)")
            except Exception:
                pass # Expected when connection is lost due to KILL
            finally:
                cursor.close()
                conn.close()
        except Exception:
            pass

    t = threading.Thread(target=slow_task)
    t.daemon = True
    t.start()
    time.sleep(2) # Give it time to start
    
    # 2. Inject issue
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) "
        "VALUES ('SLOW_QUERY', 'SLOW_QUERY_LOG', 10.0)"
    )
    log_step(f"Injected SLOW_QUERY (ID: {issue_id})")

    # 3. MANUALLY kill it before the engine does
    # This simulates the DBA fixing it or the query finishing
    pid_row = fetch_one("SELECT id FROM information_schema.processlist WHERE info LIKE 'SELECT SLEEP(10)%'")
    if pid_row:
        run_query(f"KILL {pid_row['id']}")
        log_step(f"RACE: Manually terminated PID {pid_row['id']} before engine acts")

    # 4. Trigger engine
    run_query("CALL run_ai_analysis(%s)", (issue_id,))
    run_query("CALL make_decision(%s)", (issue_id,))
    
    # 5. Check action
    decision = fetch_one("SELECT decision_type, decision_reason FROM decision_log WHERE issue_id = %s", (issue_id,))
    if decision:
        if decision['decision_type'] == 'ADMIN_REVIEW' and 'clean' in decision['decision_reason'].lower():
            log_step("PASS: System identified resolved issue (Clean State) -> Safely skipped AUTO_HEAL", "PASS")
            return True
        
        # Fallback check for healing action if it somehow proceeded
        action = fetch_one("SELECT * FROM healing_actions WHERE decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = %s)", (issue_id,))
        if action and action['execution_status'] == 'SKIPPED':
            log_step("PASS: System identified stale issue and aborted execution", "PASS")
            return True
            
        log_step(f"FAIL: Unexpected decision: {decision['decision_type']} - {decision['decision_reason']}", "FAIL")
    return False
