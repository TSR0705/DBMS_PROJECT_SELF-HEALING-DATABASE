import time

def run(probe):
    # Trigger a policy violation which is routed to ADMIN_REVIEW
    probe.run_query("INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) VALUES ('SECURITY_POLICY_VIOLATION', 'PERFORMANCE_SCHEMA', 1)")
    issue_id = probe.get_last_issue()[0]['issue_id']
    
    probe.call_procedure("run_ai_analysis", [issue_id])
    probe.call_procedure("make_decision", [issue_id])
    
    decision = probe.get_last_decision(issue_id)[0]
    if decision['decision_type'] == 'ADMIN_REVIEW':
        print(f"[*] ADMIN_REVIEW required for Issue {issue_id}. Waiting in PENDING state.")
    
    return issue_id
