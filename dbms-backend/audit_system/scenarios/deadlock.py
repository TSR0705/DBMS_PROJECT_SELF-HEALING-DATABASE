def run(probe):
    try:
        # Real state creation (Locking)
        probe.run_query("CREATE TABLE IF NOT EXISTS audit_test (id INT PRIMARY KEY, val INT) ENGINE=InnoDB")
        probe.run_query("REPLACE INTO audit_test VALUES (1, 10), (2, 20)")
        
        # Inject deadlock issue directly - the engine will then validate it
        probe.run_query("INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) VALUES ('DEADLOCK', 'INNODB', 1)")
        issue_id = probe.get_last_issue()[0]['issue_id']

        probe.call_procedure("run_ai_analysis", [issue_id])
        probe.call_procedure("make_decision", [issue_id])
        probe.call_procedure("run_execution_worker", ["AUDIT_ENGINE"])
        probe.call_procedure("run_verification_worker")
        
        return issue_id
    except Exception as e:
        raise e
