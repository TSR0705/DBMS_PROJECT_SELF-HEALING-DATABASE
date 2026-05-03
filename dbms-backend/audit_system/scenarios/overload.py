import time
import threading

def run(probe):
    threads = []
    for _ in range(12):
        t = threading.Thread(target=lambda: probe.run_query("SELECT SLEEP(5)"))
        t.start()
        threads.append(t)
    
    time.sleep(1)
    probe.run_query("CALL detect_connection_overload()")
    issue = probe.get_last_issue()[0]
    
    probe.call_procedure("run_ai_analysis", [issue['issue_id']])
    probe.call_procedure("make_decision", [issue['issue_id']])
    probe.call_procedure("run_execution_worker", ["AUDIT_ENGINE"])
    probe.call_procedure("run_verification_worker")
    
    return issue['issue_id']
