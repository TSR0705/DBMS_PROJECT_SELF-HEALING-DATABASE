import time

def run(probe):
    # Inject an issue but make sure the system state is CLEAN when validation runs
    probe.run_query("INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) VALUES ('SLOW_QUERY', 'PERFORMANCE_SCHEMA', 99)")
    issue_id = probe.get_last_issue()[0]['issue_id']
    
    # We don't create the slow query state, so validation should return FALSE
    probe.call_procedure("run_ai_analysis", [issue_id])
    probe.call_procedure("make_decision", [issue_id])
    probe.call_procedure("run_execution_worker", ["AUDIT_ENGINE"])
    
    return issue_id
