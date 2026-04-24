#!/usr/bin/env python3
import mysql.connector
import os
from dotenv import load_dotenv
import time
import threading

load_dotenv()

def create_long_running_query():
    """Create a long-running query in a separate connection"""
    try:
        conn = mysql.connector.connect(
            host=os.getenv('DB_HOST', 'localhost'),
            user=os.getenv('DB_USER', 'root'),
            password=os.getenv('DB_PASSWORD', 'Tsr@2007'),
            database=os.getenv('DB_NAME', 'dbms_self_healing')
        )
        cursor = conn.cursor()
        print("🔄 Starting long-running query (SLEEP 30)...")
        cursor.execute("SELECT SLEEP(30)")
        cursor.fetchall()
        cursor.close()
        conn.close()
        print("✅ Long-running query completed")
    except Exception as e:
        print(f"⚠️ Long-running query interrupted: {e}")

def test_real_kill_connection():
    """Test the real execution system with an actual long-running query"""
    
    # Start long-running query in background
    query_thread = threading.Thread(target=create_long_running_query)
    query_thread.daemon = True
    query_thread.start()
    
    # Wait for query to start
    time.sleep(3)
    
    # Connect to main database
    conn = mysql.connector.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        user=os.getenv('DB_USER', 'root'),
        password=os.getenv('DB_PASSWORD', 'Tsr@2007'),
        database=os.getenv('DB_NAME', 'dbms_self_healing')
    )
    cursor = conn.cursor()
    
    print("🧪 REAL EXECUTION TEST")
    print("=" * 50)
    
    # Check current long-running processes
    cursor.execute("""
        SELECT id, user, command, time, info 
        FROM information_schema.processlist 
        WHERE command != 'Sleep' AND time > 2
        ORDER BY time DESC
    """)
    processes = cursor.fetchall()
    print(f"📊 Long-running processes before: {len(processes)}")
    for proc in processes:
        print(f"   Process {proc[0]}: {proc[1]} - {proc[2]} - {proc[3]}s - {proc[4]}")
    
    # Clear previous test data
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
    cursor.execute("TRUNCATE TABLE healing_actions")
    cursor.execute("TRUNCATE TABLE decision_log")
    cursor.execute("TRUNCATE TABLE ai_analysis")
    cursor.execute("TRUNCATE TABLE detected_issues")
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
    conn.commit()
    
    # Insert test issue with high severity
    cursor.execute("""
        INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
        VALUES ('CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 150, 'connections')
    """)
    conn.commit()
    
    issue_id = cursor.lastrowid
    print(f"📝 Created test issue_id: {issue_id}")
    
    # Trigger the pipeline
    print("🚀 Triggering AI analysis...")
    cursor.execute("CALL run_ai_analysis(%s)", (issue_id,))
    
    print("🧠 Making decision...")
    cursor.execute("CALL make_decision(%s)", (issue_id,))
    conn.commit()
    
    # Check decision
    cursor.execute("""
        SELECT decision_type, decision_reason, confidence_at_decision
        FROM decision_log WHERE issue_id = %s
    """, (issue_id,))
    decision = cursor.fetchone()
    print(f"⚖️ Decision: {decision}")
    
    # Wait for execution to complete
    time.sleep(5)
    
    # Check execution results
    cursor.execute("""
        SELECT action_type, execution_status, verification_status, process_id,
               before_metric, after_metric, error_message
        FROM healing_actions 
        WHERE decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = %s)
    """, (issue_id,))
    action = cursor.fetchone()
    print(f"⚡ Action: {action}")
    
    # Check current processes after execution
    cursor.execute("""
        SELECT id, user, command, time, info 
        FROM information_schema.processlist 
        WHERE command != 'Sleep' AND time > 2
        ORDER BY time DESC
    """)
    processes_after = cursor.fetchall()
    print(f"📊 Long-running processes after: {len(processes_after)}")
    for proc in processes_after:
        print(f"   Process {proc[0]}: {proc[1]} - {proc[2]} - {proc[3]}s - {proc[4]}")
    
    # Validation
    print("\n🔍 VALIDATION RESULTS:")
    
    if decision and decision[0] == 'AUTO_HEAL':
        print("✅ DECISION: AUTO_HEAL chosen correctly")
    else:
        print("❌ DECISION: Expected AUTO_HEAL")
    
    if action:
        if action[1] == 'SUCCESS' and action[2] == 'VERIFIED':
            print("✅ EXECUTION: Successfully executed and verified")
            print(f"   📈 Metric improvement: {action[4]} → {action[5]}")
        elif action[1] == 'FAILED':
            print(f"⚠️ EXECUTION: Failed - {action[6]}")
        else:
            print(f"❓ EXECUTION: Unclear status - {action}")
    else:
        print("❌ EXECUTION: No action recorded")
    
    if len(processes_after) < len(processes):
        print("✅ REAL IMPACT: Long-running process was actually killed")
    else:
        print("⚠️ REAL IMPACT: No processes were killed")
    
    # Check learning
    cursor.execute("""
        SELECT issue_type, action_type, outcome, confidence_before, confidence_after
        FROM learning_history 
        WHERE issue_type = 'CONNECTION_OVERLOAD'
        ORDER BY learning_id DESC LIMIT 1
    """)
    learning = cursor.fetchone()
    if learning:
        print(f"🧠 LEARNING: {learning}")
        if learning[2] == 'RESOLVED' and action and action[2] == 'VERIFIED':
            print("✅ LEARNING: Correctly recorded verified success")
        elif learning[2] == 'FAILED' and action and action[2] == 'FAILED':
            print("✅ LEARNING: Correctly recorded verified failure")
        else:
            print("❌ LEARNING: Mismatch between execution and learning")
    
    print("\n🎯 REAL EXECUTION TEST COMPLETE!")
    
    cursor.close()
    conn.close()
    
    # Wait for background thread to finish
    query_thread.join(timeout=5)

if __name__ == "__main__":
    test_real_kill_connection()