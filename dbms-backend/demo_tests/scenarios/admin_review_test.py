import time
from ..db_utils import get_connection, run_query, fetch_one, log_step, insert_and_get_id

def run_admin_review_test():
    log_step("Starting ADMIN_REVIEW Intelligence Test")
    
    # 1. Insert an unknown issue that should trigger admin review
    # We use a low raw_metric_value to lower priority
    issue_id = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit) "
        "VALUES ('UNKNOWN_ANOMALY', 'PERFORMANCE_SCHEMA', 0.01, 'score')"
    )
    
    log_step(f"Injected UNKNOWN_ANOMALY (ID: {issue_id})")
    
    # 2. Trigger analysis and decision
    run_query("CALL run_ai_analysis(%s)", (issue_id,))
    run_query("CALL make_decision(%s)", (issue_id,))
    
    # 3. Verify it went to ADMIN_REVIEW
    decision = fetch_one("SELECT * FROM decision_log WHERE issue_id = %s", (issue_id,))
    
    if decision and decision['decision_type'] == 'ADMIN_REVIEW':
        log_step(f"PASS: System identified ambiguous issue -> ADMIN_REVIEW (Priority: {float(decision['confidence_at_decision']):.2f})", "PASS")
    else:
        log_step(f"FAIL: Decision was {decision['decision_type'] if decision else 'None'}", "FAIL")
        return False

    # 4. Approve the review manually
    decision_id = decision['decision_id']
    run_query(
        "UPDATE admin_reviews SET review_status = 'APPROVED', admin_action = 'EXECUTE' "
        "WHERE decision_id = %s", (decision_id,)
    )
    log_step("Admin manually APPROVED the action")
    
    # 5. Execute the approved action
    run_query("CALL execute_healing_action_v2(%s)", (decision_id,))
    
    # 6. Verify execution recorded
    action = fetch_one("SELECT * FROM healing_actions WHERE decision_id = %s", (decision_id,))
    if action and action['executed_by'] == 'ADMIN':
        log_step("PASS: Execution captured as ADMIN-triggered", "PASS")
        return True
    else:
        log_step("FAIL: Action not recorded correctly", "FAIL")
        return False
