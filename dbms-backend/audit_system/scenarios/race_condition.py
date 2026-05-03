import time
import threading

def run(probe):
    probe.run_query("INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value) VALUES ('SLOW_QUERY', 'PERFORMANCE_SCHEMA', 100)")
    issue_id = probe.get_last_issue()[0]['issue_id']
    
    probe.call_procedure("run_ai_analysis", [issue_id])
    probe.call_procedure("make_decision", [issue_id])
    
    # Try to execute from two "workers" simultaneously
    def worker_a(): probe.call_procedure("run_execution_worker", ["WORKER_A"])
    def worker_b(): probe.call_procedure("run_execution_worker", ["WORKER_B"])
    
    t1 = threading.Thread(target=worker_a)
    t2 = threading.Thread(target=worker_b)
    
    t1.start(); t2.start()
    t1.join(); t2.join()
    
    return issue_id
