import time
import threading
from ..db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id, trigger_self_healing

def hold_idle_tx():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("START TRANSACTION")
        cursor.execute("UPDATE demo_deadlock_test SET val = 999 WHERE id = 1")
        # Just stay idle without committing or sleeping inside the query
        time.sleep(60)
        conn.rollback()
    except Exception:
        pass

def run_idle_transaction_test():
    result = {
        "scenario": "IDLE_TRANSACTION",
        "status": "FAIL",
        "details": {}
    }
    log_step("Starting IDLE_TRANSACTION Demo Test", "INFO")

    log_step("Spawning TX that will become IDLE...", "INFO")
    t = threading.Thread(target=hold_idle_tx, daemon=True)
    t.start()
    time.sleep(5)

    # Confirm connection exists
    q_check = fetch_one("SELECT id FROM information_schema.processlist WHERE command = 'Sleep' AND time >= 4")
    if not q_check:
        log_step("Failed to find idle transaction connection.", "FAIL")
        return result
    pid = q_check['id']
    log_step(f"Confirmed idle connection (PID: {pid})", "PASS")

    log_step("Injecting IDLE_TRANSACTION issue...", "INFO")
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit) VALUES (%s, %s, %s, %s)",
        ("IDLE_TRANSACTION", "INNODB", 3.0, "SECONDS")
    )

    trigger_self_healing(issue_id)

    q_check_after = fetch_one("SELECT id FROM information_schema.processlist WHERE id = %s", (pid,))
    if q_check_after:
        log_step("Idle connection still exists. Engine failed to kill it.", "FAIL")
    else:
        log_step("Idle connection successfully terminated.", "PASS")

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
