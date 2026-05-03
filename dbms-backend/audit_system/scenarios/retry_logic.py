def run(probe):
    # Create an issue that will fail execution first time
    probe.run_query("INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) VALUES ('DEADLOCK', 'INNODB', 1)")
    issue_id = probe.get_last_issue()[0]['issue_id']
    
    probe.call_procedure("run_ai_analysis", [issue_id])
    probe.call_procedure("make_decision", [issue_id])
    
    # First attempt (should fail if no deadlock actually exists)
    probe.call_procedure("run_execution_worker", ["AUDIT_RETRY_1"])
    
    # Second attempt
    probe.call_procedure("run_execution_worker", ["AUDIT_RETRY_2"])
    
    return issue_id
