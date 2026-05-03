import time
from ..db_utils import run_query, fetch_one, log_step, insert_and_get_id

def run_admin_review_scenarios():
    print("\n--- HUMAN-IN-THE-LOOP SCENARIOS ---")
    
    # Scenario 1: Security Policy Violation
    log_step("Scenario 1: SECURITY_POLICY_VIOLATION detected")
    issue_id_1 = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit) "
        "VALUES ('SECURITY_POLICY_VIOLATION', 'PERFORMANCE_SCHEMA', 1.0, 'ALERT')"
    )
    
    # We must manually insert an AI analysis record for it to be processed
    run_query(
        "INSERT INTO ai_analysis (issue_id, predicted_issue_class, severity_level, confidence_score, severity_ratio) "
        "VALUES (%s, 'SECURITY', 'HIGH', 0.95, 2.5)", (issue_id_1,)
    )
    
    run_query("CALL make_decision(%s)", (issue_id_1,))
    
    decision_1 = fetch_one("SELECT * FROM decision_log WHERE issue_id = %s", (issue_id_1,))
    if decision_1 and decision_1['decision_type'] == 'ADMIN_REVIEW':
        log_step(f"PASS: System requested ADMIN_REVIEW for Security Violation (ID: {issue_id_1})", "PASS")
    else:
        log_step("FAIL: System did not request review for security policy", "FAIL")

    # Scenario 2: Optimization Suggestion
    log_step("Scenario 2: OPTIMIZATION_SUGGESTION detected")
    issue_id_2 = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit) "
        "VALUES ('OPTIMIZATION_SUGGESTION', 'PERFORMANCE_SCHEMA', 85.0, 'PERCENT')"
    )
    
    run_query(
        "INSERT INTO ai_analysis (issue_id, predicted_issue_class, severity_level, confidence_score, severity_ratio) "
        "VALUES (%s, 'PERFORMANCE', 'MEDIUM', 0.88, 1.2)", (issue_id_2,)
    )
    
    run_query("CALL make_decision(%s)", (issue_id_2,))
    
    # Give time for triggers/procedures to finalize
    time.sleep(1)
    
    decision_2 = fetch_one("SELECT * FROM decision_log WHERE issue_id = %s", (issue_id_2,))
    if decision_2 and decision_2['decision_type'] == 'ADMIN_REVIEW':
        log_step(f"PASS: System requested ADMIN_REVIEW for Optimization (ID: {issue_id_2})", "PASS")
    else:
        log_step("FAIL: System did not request review for optimization suggestion", "FAIL")

    return {
        'scenario': 'ADMIN_REVIEWS',
        'status': 'PASS' if decision_1 and decision_2 else 'FAIL',
        'details': {
            'Security Policy': 'PENDING_REVIEW',
            'Optimization': 'PENDING_REVIEW'
        }
    }
