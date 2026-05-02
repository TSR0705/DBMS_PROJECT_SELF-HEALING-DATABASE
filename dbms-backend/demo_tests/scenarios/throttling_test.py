import time
from ..db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id

def run_throttling_test():
    log_step("Starting THROTTLING Adaptive Test")
    
    # 1. Inject first issue
    id1 = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) "
        "VALUES ('DEADLOCK', 'INNODB', 1.0)"
    )
    run_query("CALL run_ai_analysis(%s)", (id1,))
    run_query("CALL make_decision(%s)", (id1,))
    log_step(f"First issue processed (ID: {id1})")
    
    # 2. Immediately inject identical issue
    id2 = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) "
        "VALUES ('DEADLOCK', 'INNODB', 1.0)"
    )
    log_step(f"Second identical issue injected (ID: {id2})")
    
    # 3. Process second issue
    run_query("CALL run_ai_analysis(%s)", (id2,))
    run_query("CALL make_decision(%s)", (id2,))
    
    # 4. Verify decision is THROTTLED
    decision = fetch_one("SELECT * FROM decision_log WHERE issue_id = %s", (id2,))
    
    if decision and decision['decision_type'] == 'THROTTLED':
        log_step("PASS: System throttled redundant healing attempt", "PASS")
        return True
    else:
        log_step(f"FAIL: Decision was {decision['decision_type'] if decision else 'None'}", "FAIL")
        return False
