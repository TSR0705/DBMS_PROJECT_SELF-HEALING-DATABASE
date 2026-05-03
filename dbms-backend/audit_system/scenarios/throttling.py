def run(probe):
    # Inject multiple issues rapidly
    for _ in range(5):
        probe.run_query("INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) VALUES ('SLOW_QUERY', 'PERFORMANCE_SCHEMA', 10)")
        issue_id = probe.get_last_issue()[0]['issue_id']
        probe.call_procedure("run_ai_analysis", [issue_id])
        probe.call_procedure("make_decision", [issue_id])
        
    return issue_id # Return last one
