import mysql.connector
import time

config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'Tsr@2007',
    'database': 'dbms_self_healing',
}

def test_auto_fix():
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor(dictionary=True)
        
        print("=> Injecting AUTO-FIX candidate: DEADLOCK anomaly...")
        cursor.execute('''
            INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at)
            VALUES (%s, %s, %s, %s, NOW())
        ''', ('DEADLOCK', 'INNODB', 999.0, 'COUNT'))
        conn.commit()
        issue_id = cursor.lastrowid
        print(f"Issue injected with ID: {issue_id}. Monitoring for automatic healing...")

        # Wait for pipeline
        for i in range(1, 21):
            time.sleep(1)
            cursor.execute("SELECT * FROM healing_actions ha JOIN decision_log dl ON ha.decision_id = dl.decision_id WHERE dl.issue_id = %s", (issue_id,))
            action = cursor.fetchone()
            if action:
                print(f"\n[SUCCESS] Auto-fix detected at second {i}!")
                print(f"Action: {action['action_type']}")
                print(f"Mode: {action['execution_mode']}")
                print(f"Status: {action['execution_status']}")
                return
            else:
                print(f".", end="", flush=True)

        print("\n[TIMEOUT] System did not auto-fix within 20 seconds. Check event_scheduler or action_rules.")

    except Exception as e:
        print(f"\nError: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    test_auto_fix()
