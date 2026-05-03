import time
import threading
from ..db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id, trigger_self_healing

def overload_query():
    try:
        conn = get_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT SLEEP(60) /* OVERLOAD_DEMO */")
    except Exception:
        pass

def run_overload_test():
    result = {
        "scenario": "OVERLOAD",
        "status": "FAIL",
        "details": {}
    }
    log_step("Starting CONNECTION_OVERLOAD Demo Test", "INFO")

    target_conns = 12
    log_step(f"Spawning {target_conns} parallel SLEEP queries...", "INFO")
    threads = []
    for _ in range(target_conns):
        t = threading.Thread(target=overload_query, daemon=True)
        t.start()
        threads.append(t)
    
    time.sleep(3)

    active_q = fetch_one("SELECT COUNT(*) as c FROM information_schema.processlist WHERE command = 'Query' AND info LIKE '%OVERLOAD_DEMO%'")
    before_count = active_q['c'] if active_q else 0
    if before_count < 5:
        log_step(f"Failed to generate enough load. Only {before_count} active.", "FAIL")
        return result
    log_step(f"Confirmed overload condition: {before_count} active queries.", "PASS")

    log_step("Injecting CONNECTION_OVERLOAD issue...", "INFO")
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit) VALUES (%s, %s, %s, %s)",
        ("CONNECTION_OVERLOAD", "INNODB", float(before_count), "CONNS")
    )

    trigger_self_healing(issue_id)

    active_q_after = fetch_one("SELECT COUNT(*) as c FROM information_schema.processlist WHERE command = 'Query' AND info LIKE '%OVERLOAD_DEMO%'")
    after_count = active_q_after['c'] if active_q_after else 0
    
    if after_count == 0:
        log_step("All queries killed. Expected selective targeting.", "FAIL")
    elif after_count >= before_count:
        log_step("No queries killed. Engine failed to respond.", "FAIL")
    else:
        log_step(f"Iterative kill successful. Active reduced from {before_count} to {after_count}.", "PASS")

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
            "verification": action_log['verification_status'],
            "before": before_count,
            "after": after_count
        }
        if 0 < after_count < before_count and action_log['action_type'] == 'KILL_CONNECTION':
            result["status"] = "PASS"
    else:
        log_step("No healing action found in database.", "FAIL")

    return result
