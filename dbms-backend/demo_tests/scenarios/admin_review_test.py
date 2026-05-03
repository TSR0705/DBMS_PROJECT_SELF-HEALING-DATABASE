import time
from ..db_utils import run_query, fetch_one, log_step, insert_and_get_id

def run_admin_review_scenarios():
    print("\n--- HUMAN-IN-THE-LOOP SCENARIOS ---")
    
    # Scenario 1: SECURITY_POLICY_VIOLATION (Real state creation)
    log_step("Scenario 1: Creating real SECURITY_POLICY_VIOLATION (Wildcard User)...")
    try:
        run_query("CREATE USER 'unsecure_demo_user'@'%' IDENTIFIED BY 'Password123!'")
        run_query("GRANT ALL PRIVILEGES ON *.* TO 'unsecure_demo_user'@'%'")
    except:
        pass # User might exist
    
    # Trigger real detection
    log_step("Triggering dynamic detection...")
    issue_id_1 = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit) "
        "SELECT 'SECURITY_POLICY_VIOLATION', 'PERFORMANCE_SCHEMA', COUNT(*), 'ACCOUNTS' "
        "FROM mysql.user WHERE host = '%' AND Super_priv = 'Y'"
    )
    
    run_query(
        "INSERT INTO ai_analysis (issue_id, predicted_issue_class, severity_level, confidence_score, severity_ratio) "
        "VALUES (%s, 'SECURITY', 'CRITICAL', 0.99, 5.0)", (issue_id_1,)
    )
    
    run_query("CALL make_decision(%s)", (issue_id_1,))
    decision_1 = fetch_one("SELECT * FROM decision_log WHERE issue_id = %s", (issue_id_1,))

    # Scenario 2: OPTIMIZATION_SUGGESTION (Real fragmentation creation)
    log_step("Scenario 2: Creating real OPTIMIZATION_SUGGESTION (Table Fragmentation)...")
    # Simulate fragmentation by inserting and deleting many rows in a demo table
    run_query("CREATE TABLE IF NOT EXISTS fragmentation_demo (id INT AUTO_INCREMENT PRIMARY KEY, data TEXT)")
    run_query("INSERT INTO fragmentation_demo (data) SELECT REPEAT('X', 1000) FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t1, (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t2, (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4) t3")
    run_query("DELETE FROM fragmentation_demo WHERE id % 2 = 0")
    
    # In a real system, we'd wait for background stats, but we'll inject the detection based on the real state
    issue_id_2 = insert_and_get_id(
        "INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit) "
        "SELECT 'OPTIMIZATION_SUGGESTION', 'PERFORMANCE_SCHEMA', data_free/1024, 'KB' "
        "FROM information_schema.tables WHERE table_schema = 'dbms_self_healing' AND table_name = 'fragmentation_demo'"
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

    # [PHASE 7] MOVED TO MANUAL: We no longer auto-approve here to allow manual UI demo
    log_step(f"Admin Review required for Decision: {decision_1['decision_id']} (Security)")
    log_step(f"Admin Review required for Decision: {decision_2['decision_id']} (Optimization)")

    # Verify Results are in PENDING state
    time.sleep(1)
    rev1 = fetch_one("SELECT review_status FROM admin_reviews WHERE decision_id = %s", (decision_1['decision_id'],))
    rev2 = fetch_one("SELECT review_status FROM admin_reviews WHERE decision_id = %s", (decision_2['decision_id'],))
    
    return {
        'scenario': 'ADMIN_REVIEWS',
        'status': 'PASS' if (rev1 and rev1['review_status'] == 'PENDING' and rev2 and rev2['review_status'] == 'PENDING') else 'FAIL',
        'details': {
            'Security Policy': 'PENDING_ADMIN_ACTION',
            'Optimization': 'PENDING_ADMIN_ACTION'
        }
    }
