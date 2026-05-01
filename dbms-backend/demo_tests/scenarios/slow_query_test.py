import time
import threading
from ..db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id

def background_slow_query():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT SLEEP(60) /* DEMO_SLOW_QUERY */")
    except Exception:
        pass

def run_slow_query_test():
    result = {
        "scenario": "SLOW_QUERY",
        "status": "FAIL",
        "details": {}
    }
    log_step("Starting SLOW_QUERY Demo Test", "INFO")

    log_step("Spawning background SLEEP(60) query...", "INFO")
    t = threading.Thread(target=background_slow_query, daemon=True)
    t.start()

    log_step("Waiting 20 seconds for query to mature...", "WARN")
    time.sleep(20)

    q_check = fetch_one("SELECT id FROM information_schema.processlist WHERE info LIKE '%DEMO_SLOW_QUERY%'")
    if not q_check:
        log_step("Failed to find sleep query in processlist.", "FAIL")
        return result
    pid = q_check['id']
    log_step(f"Confirmed background query running (PID: {pid})", "PASS")

    log_step("Injecting SLOW_QUERY issue into detection pipeline...", "INFO")
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit) VALUES (%s, %s, %s, %s)",
        ("SLOW_QUERY", "PERFORMANCE_SCHEMA", 20.0, "SECONDS")
    )

    log_step("Waiting 3 seconds for self-healing engine to process...", "WARN")
    time.sleep(3)

    q_check_after = fetch_one("SELECT id FROM information_schema.processlist WHERE id = %s", (pid,))
    if q_check_after:
        log_step("Query is still running. Engine failed to kill it.", "FAIL")
    else:
        log_step("Query successfully terminated by engine.", "PASS")

    action_log = fetch_one(
        "SELECT ha.action_type, ha.execution_status, ha.verification_status, dl.decision_type "
        "FROM healing_actions ha "
        "JOIN decision_log dl ON ha.decision_id = dl.decision_id "
        "WHERE dl.issue_id = %s ORDER BY ha.action_id DESC LIMIT 1",
        (issue_id,)
    )

    if action_log:
        log_step(f"Found healing action: {action_log['action_type']} ({action_log['execution_status']})", "PASS")
        result["details"] = {
            "decision": action_log['decision_type'],
            "action": action_log['action_type'],
            "execution": action_log['execution_status'],
            "verification": action_log['verification_status']
        }
        if not q_check_after and action_log['execution_status'] == 'SUCCESS':
            result["status"] = "PASS"
    else:
        log_step("No healing action found in database.", "FAIL")

    return result
