import time
import threading

def run(probe):
    # Setup: Run a long sleep query in background
    def run_sleep():
        probe.run_query("SELECT SLEEP(15)")
    
    t = threading.Thread(target=run_sleep)
    t.start()
    time.sleep(2)

    probe.run_query("CALL detect_slow_queries()")
    issue = probe.get_last_issue()[0]
    
    probe.call_procedure("run_ai_analysis", [issue['issue_id']])
    probe.call_procedure("make_decision", [issue['issue_id']])
    probe.call_procedure("run_execution_worker", ["AUDIT_ENGINE"])
    probe.call_procedure("run_verification_worker")
    
    return issue['issue_id']
