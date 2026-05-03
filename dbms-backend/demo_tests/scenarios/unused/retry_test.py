import time
from ..db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id

def run_retry_test():
    log_step("Starting RETRY_LOGIC Resilience Test")
    
    # 1. Insert a SLOW_QUERY
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) "
        "VALUES ('SLOW_QUERY', 'SLOW_QUERY_LOG', 15.0)"
    )
    
    # 2. Force it to AUTO_HEAL
    run_query("CALL run_ai_analysis(%s)", (issue_id,))
    run_query("CALL make_decision(%s)", (issue_id,))
    
    decision = fetch_one("SELECT decision_id FROM decision_log WHERE issue_id = %s", (issue_id,))
    decision_id = decision['decision_id']
    
    # 3. Call execution engine multiple times to simulate retries
    log_step("Simulating multi-stage recovery attempts...")
    run_query("CALL execute_healing_action_v2(%s)", (decision_id,))
    run_query("CALL execute_healing_action_v2(%s)", (decision_id,))
    
    # 4. Check retry count
    action = fetch_one(
        "SELECT MAX(retry_count) as total_retries FROM healing_actions WHERE decision_id = %s", 
        (decision_id,)
    )
    
    if action and action['total_retries'] >= 1:
        log_step(f"PASS: Retry count tracked correctly (Count: {action['total_retries']})", "PASS")
        return True
    else:
        log_step(f"FAIL: Retry count was {action['total_retries'] if action else 'None'}", "FAIL")
        return False
