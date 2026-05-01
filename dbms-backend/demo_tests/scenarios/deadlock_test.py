import time
import threading
from ..db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id

def setup_test_table():
    run_query("CREATE TABLE IF NOT EXISTS demo_deadlock_test (id INT PRIMARY KEY, val INT)")
    run_query("INSERT IGNORE INTO demo_deadlock_test (id, val) VALUES (1, 100)")

def hold_lock():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("START TRANSACTION")
        cursor.execute("UPDATE demo_deadlock_test SET val = val + 1 WHERE id = 1")
        cursor.execute("SELECT SLEEP(60)")
        conn.commit()
    except Exception:
        pass

def wait_for_lock():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("START TRANSACTION")
        cursor.execute("UPDATE demo_deadlock_test SET val = val + 1 WHERE id = 1")
        conn.commit()
    except Exception:
        pass

def run_deadlock_test():
    result = {
        "scenario": "DEADLOCK",
        "status": "FAIL",
        "details": {}
    }
    log_step("Starting DEADLOCK Demo Test", "INFO")

    setup_test_table()

    log_step("Spawning TX1 (locking row)...", "INFO")
    t1 = threading.Thread(target=hold_lock, daemon=True)
    t1.start()
    time.sleep(2)

    log_step("Spawning TX2 (waiting for row)...", "INFO")
    t2 = threading.Thread(target=wait_for_lock, daemon=True)
    t2.start()
    time.sleep(2)

    lock_check = fetch_one("SELECT * FROM sys.innodb_lock_waits")
    if not lock_check:
        log_step("Failed to generate InnoDB lock wait.", "FAIL")
        return result
    log_step(f"Confirmed active lock wait (Blocking TRX: {lock_check['blocking_trx_id']})", "PASS")

    log_step("Injecting DEADLOCK issue into detection pipeline...", "INFO")
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit) VALUES (%s, %s, %s, %s)",
        ("DEADLOCK", "INNODB", 1.0, "LOCKS")
    )

    log_step("Waiting 3 seconds for sub-second engine to process...", "WARN")
    time.sleep(3)

    lock_check_after = fetch_one("SELECT * FROM sys.innodb_lock_waits")
    if lock_check_after:
        log_step("Lock wait still exists. Engine failed to resolve.", "FAIL")
    else:
        log_step("Lock wait cleared successfully.", "PASS")

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
        if not lock_check_after and action_log['execution_status'] == 'SUCCESS' and action_log['action_type'] == 'ROLLBACK_TRANSACTION':
            result["status"] = "PASS"
    else:
        log_step("No healing action found in database.", "FAIL")

    return result
