import mysql.connector
import time
from datetime import datetime
import uuid

config = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': 'Tsr@2007',
    'database': 'dbms_self_healing',
    'connection_timeout': 5
}

issue_id = f'bug_test_{int(time.time())}'

try:
    conn = mysql.connector.connect(**config)
    cursor = conn.cursor(dictionary=True)
    
    print(f'Injecting new bug into the database...')
    
    # 1. Inject the anomaly
    cursor.execute('''
        INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at)
        VALUES (%s, %s, %s, %s, NOW())
    ''', ('UNKNOWN_BUG', 'INNODB', 9999.0, 'SECONDS'))
    conn.commit()
    issue_id = cursor.lastrowid
    print(f'Bug injected successfully! Assigned ID: {issue_id}. Waiting 15 seconds for event scheduler...')
    
    # 2. Polling for updates
    for i in range(15):
        time.sleep(1)
        
        # Check analysis
        cursor.execute('SELECT * FROM ai_analysis WHERE issue_id = %s', (issue_id,))
        analysis = cursor.fetchone()
        
        # Check decision
        cursor.execute('SELECT * FROM decision_log WHERE issue_id = %s', (issue_id,))
        decision = cursor.fetchone()
        
        # Check action if decision exists
        action = None
        if decision:
            cursor.execute('SELECT * FROM healing_actions WHERE decision_id = %s', (decision['decision_id'],))
            action = cursor.fetchone()
            
        print(f'Second {i+1}: Analysis: {bool(analysis)} | Decision: {bool(decision)} | Action: {bool(action)}')
        
        if action:
            print("System fixed it automatically!")
            break
            
    print('\n--- FINAL TRACE ---')
    if analysis: print(f'Analysis: {analysis}')
    if decision: print(f'Decision: {decision}')
    if action: print(f'Action: {action}')
    
    cursor.execute('SELECT * FROM debug_log ORDER BY created_at DESC LIMIT 10')
    debug_logs = cursor.fetchall()
    print(f'\n--- DEBUG LOGS ({len(debug_logs)}) ---')
    for log in debug_logs: print(f'{log["step"]} -> {log["message"]}')
    
except Exception as e:
    print(f'Error: {e}')
finally:
    if 'conn' in locals() and conn.is_connected():
        cursor.close()
        conn.close()
