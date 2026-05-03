import time
from ..db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id

def run_false_positive_test():
    log_step("Starting FALSE_POSITIVE Safety Test")
    
    # Wait for any previous deadlock residues to clear
    time.sleep(2)
    
    # 1. Insert a GHOST issue that is guaranteed to fail real-time validation
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) "
        "VALUES ('GHOST_ANOMALY', 'INNODB', 0.0)"
    )
    
    log_step(f"Injected GHOST DEADLOCK (ID: {issue_id})")
    
    # 2. Trigger analysis and decision
    run_query("CALL run_ai_analysis(%s)", (issue_id,))
    run_query("CALL make_decision(%s)", (issue_id,))
    
    # 3. Decision should be ADMIN_REVIEW because validate_issue_state returns FALSE
    decision = fetch_one("SELECT * FROM decision_log WHERE issue_id = %s", (issue_id,))
    
    if decision and decision['decision_type'] == 'ADMIN_REVIEW':
        log_step(f"PASS: System detected false positive -> Refused AUTO_HEAL", "PASS")
        
        # If we try to force execution on a false positive, it should skip
        run_query("CALL execute_healing_action_v2(%s)", (decision['decision_id'],))
        action = fetch_one("SELECT * FROM healing_actions WHERE decision_id = %s", (decision['decision_id'],))
        
        if action and action['execution_status'] == 'SKIPPED':
            log_step("PASS: Execution safely SKIPPED (Real-time validation check)", "PASS")
            return True
        else:
            log_step(f"FAIL: Execution status was {action['execution_status'] if action else 'None'}", "FAIL")
            return False
    else:
        log_step("FAIL: System did not categorize as ADMIN_REVIEW/False Positive", "FAIL")
        return False
