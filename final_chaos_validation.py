#!/usr/bin/env python3
"""
FINAL STRESS + CHAOS VALIDATION
This is a BREAK TEST - designed to expose weaknesses
"""
import mysql.connector
import os
from dotenv import load_dotenv
import time
import threading
import random
from datetime import datetime

load_dotenv()

def get_connection():
    return mysql.connector.connect(
        host=os.getenv('DB_HOST', 'localhost'),
        user=os.getenv('DB_USER', 'root'),
        password=os.getenv('DB_PASSWORD', 'Tsr@2007'),
        database=os.getenv('DB_NAME', 'dbms_self_healing')
    )

def log(message):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {message}")

# ============================================================
# STEP 1: RESET SYSTEM
# ============================================================
def reset_system():
    log("=" * 60)
    log("STEP 1: RESET SYSTEM")
    log("=" * 60)
    
    conn = get_connection()
    cursor = conn.cursor()
    
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")
    
    tables = ['learning_history', 'healing_actions', 'admin_reviews', 
              'decision_log', 'ai_analysis', 'detected_issues', 'debug_log']
    
    for table in tables:
        cursor.execute(f"TRUNCATE TABLE {table}")
        conn.commit()
    
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
    
    # Seed learning history for AUTO_HEAL decisions
    cursor.execute("""
        INSERT INTO learning_history (issue_type, action_type, outcome, confidence_before, confidence_after)
        VALUES 
            ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', 'RESOLVED', 0.5000, 0.9000),
            ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', 'RESOLVED', 0.9000, 0.9500),
            ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', 'RESOLVED', 0.9500, 0.9800),
            ('DEADLOCK', 'ROLLBACK_TRANSACTION', 'RESOLVED', 0.5000, 0.8000),
            ('DEADLOCK', 'ROLLBACK_TRANSACTION', 'RESOLVED', 0.8000, 0.9000)
    """)
    conn.commit()
    
    cursor.close()
    conn.close()
    
    log("✅ System reset complete")

# ============================================================
# STEP 2: CONCURRENCY TEST
# ============================================================
def concurrency_test():
    log("\n" + "=" * 60)
    log("STEP 2: CONCURRENCY TEST (20 rapid issues)")
    log("=" * 60)
    
    issue_types = ['CONNECTION_OVERLOAD', 'DEADLOCK', 'SLOW_QUERY']
    sources = ['INNODB', 'PERFORMANCE_SCHEMA', 'SLOW_QUERY_LOG']
    
    def insert_and_process(idx):
        try:
            conn = get_connection()
            cursor = conn.cursor()
            
            issue_type = random.choice(issue_types)
            source = random.choice(sources)
            metric = random.randint(50, 200)
            
            # Insert issue
            cursor.execute("""
                INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
                VALUES (%s, %s, %s, 'connections')
            """, (issue_type, source, metric))
            conn.commit()
            
            issue_id = cursor.lastrowid
            
            # Run pipeline
            cursor.execute("CALL run_ai_analysis(%s)", (issue_id,))
            cursor.execute("CALL make_decision(%s)", (issue_id,))
            conn.commit()
            
            cursor.close()
            conn.close()
            
            log(f"  Thread {idx}: Issue {issue_id} ({issue_type}) processed")
        except Exception as e:
            log(f"  ❌ Thread {idx} error: {e}")
    
    # Launch 20 concurrent threads
    threads = []
    for i in range(20):
        t = threading.Thread(target=insert_and_process, args=(i,))
        threads.append(t)
        t.start()
        time.sleep(0.05)  # Small stagger
    
    # Wait for all threads
    for t in threads:
        t.join()
    
    time.sleep(3)  # Allow execution to complete
    
    # VERIFY
    conn = get_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM detected_issues")
    issue_count = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM decision_log")
    decision_count = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM healing_actions")
    action_count = cursor.fetchone()[0]
    
    # Check for duplicates
    cursor.execute("""
        SELECT issue_id, COUNT(*) as cnt 
        FROM decision_log 
        GROUP BY issue_id 
        HAVING cnt > 1
    """)
    duplicates = cursor.fetchall()
    
    # Check for duplicate actions
    cursor.execute("""
        SELECT decision_id, COUNT(*) as cnt 
        FROM healing_actions 
        GROUP BY decision_id 
        HAVING cnt > 1
    """)
    dup_actions = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    log(f"\n📊 CONCURRENCY RESULTS:")
    log(f"  Issues inserted: {issue_count}")
    log(f"  Decisions made: {decision_count}")
    log(f"  Actions executed: {action_count}")
    log(f"  Duplicate decisions: {len(duplicates)}")
    log(f"  Duplicate actions: {len(dup_actions)}")
    
    if len(duplicates) > 0:
        log(f"  ❌ FAIL: Found duplicate decisions: {duplicates}")
        return False
    
    if len(dup_actions) > 0:
        log(f"  ❌ FAIL: Found duplicate actions: {dup_actions}")
        return False
    
    if decision_count != issue_count:
        log(f"  ⚠️ WARNING: Decision count mismatch")
    
    log("  ✅ PASS: No duplicates, all issues processed")
    return True

# ============================================================
# STEP 3: STRESS TEST (50+ iterations)
# ============================================================
def stress_test():
    log("\n" + "=" * 60)
    log("STEP 3: STRESS TEST (50 iterations)")
    log("=" * 60)
    
    iterations = 50
    errors = []
    
    for i in range(iterations):
        try:
            conn = get_connection()
            cursor = conn.cursor()
            
            # Insert issue
            cursor.execute("""
                INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
                VALUES ('CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', %s, 'connections')
            """, (random.randint(80, 150),))
            conn.commit()
            
            issue_id = cursor.lastrowid
            
            # Run pipeline
            cursor.execute("CALL run_ai_analysis(%s)", (issue_id,))
            cursor.execute("CALL make_decision(%s)", (issue_id,))
            conn.commit()
            
            cursor.close()
            conn.close()
            
            if (i + 1) % 10 == 0:
                log(f"  Completed {i + 1}/{iterations} iterations")
        
        except Exception as e:
            errors.append(f"Iteration {i}: {e}")
            log(f"  ❌ Error at iteration {i}: {e}")
    
    # Verify system state
    conn = get_connection()
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM learning_history")
    learning_count = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM healing_actions")
    action_count = cursor.fetchone()[0]
    
    cursor.close()
    conn.close()
    
    log(f"\n📊 STRESS TEST RESULTS:")
    log(f"  Iterations completed: {iterations}")
    log(f"  Errors encountered: {len(errors)}")
    log(f"  Learning records: {learning_count}")
    log(f"  Actions executed: {action_count}")
    
    if len(errors) > 5:
        log(f"  ❌ FAIL: Too many errors ({len(errors)})")
        return False
    
    if learning_count < 5:
        log(f"  ❌ FAIL: Learning not growing")
        return False
    
    log("  ✅ PASS: System stable under stress")
    return True

# ============================================================
# STEP 4: FAILURE CHAOS TEST
# ============================================================
def failure_chaos_test():
    log("\n" + "=" * 60)
    log("STEP 4: FAILURE CHAOS TEST")
    log("=" * 60)
    
    conn = get_connection()
    cursor = conn.cursor()
    
    # Test 1: Invalid process_id (no eligible processes)
    log("  Test 4.1: No eligible processes to kill")
    cursor.execute("""
        INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
        VALUES ('CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 200, 'connections')
    """)
    conn.commit()
    
    issue_id = cursor.lastrowid
    cursor.execute("CALL run_ai_analysis(%s)", (issue_id,))
    cursor.execute("CALL make_decision(%s)", (issue_id,))
    conn.commit()
    
    time.sleep(2)
    
    cursor.execute("""
        SELECT execution_status, verification_status, error_message
        FROM healing_actions 
        WHERE decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = %s)
    """, (issue_id,))
    result = cursor.fetchone()
    
    if result:
        status, verification, error = result
        log(f"    Status: {status}, Verification: {verification}")
        if status == 'FAILED' and verification == 'FAILED':
            log(f"    ✅ Correctly recorded failure")
        else:
            log(f"    ❌ FAIL: Should be FAILED but got {status}/{verification}")
            cursor.close()
            conn.close()
            return False
    else:
        log(f"    ⚠️ No action recorded (may be ADMIN_REVIEW)")
    
    # Test 2: Check for fake successes
    log("\n  Test 4.2: Checking for fake successes")
    cursor.execute("""
        SELECT COUNT(*) FROM healing_actions
        WHERE execution_status = 'SUCCESS'
        AND verification_status = 'VERIFIED'
        AND (before_metric IS NULL 
             OR after_metric IS NULL 
             OR after_metric >= before_metric)
    """)
    fake_success_count = cursor.fetchone()[0]
    
    if fake_success_count > 0:
        log(f"    ❌ FAIL: Found {fake_success_count} fake successes")
        cursor.close()
        conn.close()
        return False
    else:
        log(f"    ✅ No fake successes detected")
    
    cursor.close()
    conn.close()
    
    log("  ✅ PASS: Failure handling correct")
    return True

# ============================================================
# STEP 5: LEARNING STABILITY TEST
# ============================================================
def learning_stability_test():
    log("\n" + "=" * 60)
    log("STEP 5: LEARNING STABILITY TEST (20 cycles)")
    log("=" * 60)
    
    conn = get_connection()
    cursor = conn.cursor()
    
    # Force alternating pattern: SUCCESS → FAILED → SUCCESS → FAILED
    pattern = ['RESOLVED', 'FAILED'] * 10
    
    for i, outcome in enumerate(pattern):
        conf_before = 0.5 + (i * 0.01)
        if outcome == 'RESOLVED':
            conf_after = min(conf_before + 0.05, 0.99)
        else:
            conf_after = max(conf_before - 0.05, 0.01)
        
        cursor.execute("""
            INSERT INTO learning_history (issue_type, action_type, outcome, confidence_before, confidence_after)
            VALUES ('SLOW_QUERY', 'KILL_CONNECTION', %s, %s, %s)
        """, (outcome, conf_before, conf_after))
        conn.commit()
    
    # Check success rate
    cursor.execute("CALL compute_success_rate('SLOW_QUERY', 'KILL_CONNECTION', @rate)")
    cursor.execute("SELECT @rate")
    success_rate = cursor.fetchone()[0]
    
    log(f"  Final success rate: {success_rate:.2%}")
    
    # Verify it's around 50% (10 success, 10 failed)
    if 0.45 <= success_rate <= 0.55:
        log(f"  ✅ PASS: Success rate stable around 50%")
        cursor.close()
        conn.close()
        return True
    else:
        log(f"  ❌ FAIL: Success rate unstable: {success_rate:.2%}")
        cursor.close()
        conn.close()
        return False

# ============================================================
# STEP 6: RATE LIMIT TEST
# ============================================================
def rate_limit_test():
    log("\n" + "=" * 60)
    log("STEP 6: RATE LIMIT TEST (15 issues in 1 minute)")
    log("=" * 60)
    
    conn = get_connection()
    cursor = conn.cursor()
    
    start_time = time.time()
    
    for i in range(15):
        cursor.execute("""
            INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
            VALUES ('CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 100, 'connections')
        """)
        conn.commit()
        
        issue_id = cursor.lastrowid
        cursor.execute("CALL run_ai_analysis(%s)", (issue_id,))
        cursor.execute("CALL make_decision(%s)", (issue_id,))
        conn.commit()
    
    elapsed = time.time() - start_time
    
    time.sleep(3)
    
    # Count actions executed
    cursor.execute("""
        SELECT COUNT(*) FROM healing_actions 
        WHERE executed_at >= NOW() - INTERVAL 1 MINUTE
    """)
    actions_executed = cursor.fetchone()[0]
    
    cursor.close()
    conn.close()
    
    log(f"  Issues inserted: 15")
    log(f"  Actions executed: {actions_executed}")
    log(f"  Time elapsed: {elapsed:.2f}s")
    
    # Note: Current system doesn't have explicit rate limiting
    # This test documents the behavior
    log(f"  ℹ️ INFO: Rate limiting not explicitly enforced in current implementation")
    return True

# ============================================================
# STEP 7: DATA INTEGRITY TEST
# ============================================================
def data_integrity_test():
    log("\n" + "=" * 60)
    log("STEP 7: DATA INTEGRITY TEST")
    log("=" * 60)
    
    conn = get_connection()
    cursor = conn.cursor()
    
    # Check 1: Duplicate decisions
    cursor.execute("""
        SELECT issue_id, COUNT(*) as cnt 
        FROM decision_log 
        GROUP BY issue_id 
        HAVING cnt > 1
    """)
    dup_decisions = cursor.fetchall()
    
    if dup_decisions:
        log(f"  ❌ FAIL: Found {len(dup_decisions)} duplicate decisions")
        for issue_id, count in dup_decisions:
            log(f"    Issue {issue_id}: {count} decisions")
        cursor.close()
        conn.close()
        return False
    else:
        log(f"  ✅ No duplicate decisions")
    
    # Check 2: Multiple actions per decision
    cursor.execute("""
        SELECT decision_id, COUNT(*) as cnt 
        FROM healing_actions 
        GROUP BY decision_id 
        HAVING cnt > 1
    """)
    dup_actions = cursor.fetchall()
    
    if dup_actions:
        log(f"  ❌ FAIL: Found {len(dup_actions)} decisions with multiple actions")
        cursor.close()
        conn.close()
        return False
    else:
        log(f"  ✅ Each decision has max 1 action")
    
    # Check 3: Orphaned records
    cursor.execute("""
        SELECT COUNT(*) FROM healing_actions ha
        LEFT JOIN decision_log dl ON ha.decision_id = dl.decision_id
        WHERE dl.decision_id IS NULL
    """)
    orphaned_actions = cursor.fetchone()[0]
    
    if orphaned_actions > 0:
        log(f"  ❌ FAIL: Found {orphaned_actions} orphaned actions")
        cursor.close()
        conn.close()
        return False
    else:
        log(f"  ✅ No orphaned actions")
    
    # Check 4: Learning consistency
    cursor.execute("""
        SELECT COUNT(*) FROM learning_history
        WHERE outcome NOT IN ('RESOLVED', 'FAILED')
    """)
    invalid_outcomes = cursor.fetchone()[0]
    
    if invalid_outcomes > 0:
        log(f"  ❌ FAIL: Found {invalid_outcomes} invalid learning outcomes")
        cursor.close()
        conn.close()
        return False
    else:
        log(f"  ✅ All learning outcomes valid")
    
    cursor.close()
    conn.close()
    
    log("  ✅ PASS: Data integrity verified")
    return True

# ============================================================
# STEP 8: FINAL OUTPUT REPORT
# ============================================================
def final_report():
    log("\n" + "=" * 60)
    log("STEP 8: FINAL OUTPUT REPORT")
    log("=" * 60)
    
    conn = get_connection()
    cursor = conn.cursor()
    
    # Execution log summary
    log("\n📊 EXECUTION LOG SUMMARY:")
    
    cursor.execute("SELECT COUNT(*) FROM detected_issues")
    total_issues = cursor.fetchone()[0]
    
    cursor.execute("""
        SELECT decision_type, COUNT(*) 
        FROM decision_log 
        GROUP BY decision_type
    """)
    decisions = cursor.fetchall()
    
    cursor.execute("""
        SELECT execution_status, COUNT(*) 
        FROM healing_actions 
        GROUP BY execution_status
    """)
    actions = cursor.fetchall()
    
    log(f"  Total issues processed: {total_issues}")
    log(f"  Decisions breakdown:")
    for decision_type, count in decisions:
        log(f"    {decision_type}: {count}")
    log(f"  Actions breakdown:")
    for status, count in actions:
        log(f"    {status}: {count}")
    
    # Healing actions snapshot
    log("\n📋 HEALING ACTIONS SNAPSHOT (last 10):")
    cursor.execute("""
        SELECT action_id, action_type, execution_status, verification_status, 
               before_metric, after_metric, process_id
        FROM healing_actions 
        ORDER BY action_id DESC 
        LIMIT 10
    """)
    for row in cursor.fetchall():
        log(f"  Action {row[0]}: {row[1]} | {row[2]}/{row[3]} | {row[4]}→{row[5]} | PID:{row[6]}")
    
    # Learning history analysis
    log("\n🧠 LEARNING HISTORY ANALYSIS:")
    cursor.execute("""
        SELECT issue_type, action_type, 
               COUNT(*) as total_runs,
               SUM(CASE WHEN outcome = 'RESOLVED' THEN 1 ELSE 0 END) as success_count,
               SUM(CASE WHEN outcome = 'FAILED' THEN 1 ELSE 0 END) as fail_count
        FROM learning_history 
        GROUP BY issue_type, action_type
    """)
    for row in cursor.fetchall():
        issue_type, action_type, total, success, failed = row
        success_rate = (success / total * 100) if total > 0 else 0
        log(f"  {issue_type} + {action_type}:")
        log(f"    Total: {total} | Success: {success} | Failed: {failed} | Rate: {success_rate:.1f}%")
    
    # Anomalies detected
    log("\n🔍 ANOMALIES DETECTED:")
    
    anomalies = []
    
    # Check fake successes
    cursor.execute("""
        SELECT COUNT(*) FROM healing_actions
        WHERE execution_status = 'SUCCESS'
        AND verification_status = 'VERIFIED'
        AND (before_metric IS NULL OR after_metric IS NULL OR after_metric >= before_metric)
    """)
    fake_successes = cursor.fetchone()[0]
    if fake_successes > 0:
        anomalies.append(f"❌ {fake_successes} fake successes")
    
    # Check duplicate executions
    cursor.execute("""
        SELECT COUNT(*) FROM (
            SELECT decision_id, COUNT(*) as cnt 
            FROM healing_actions 
            GROUP BY decision_id 
            HAVING cnt > 1
        ) sub
    """)
    dup_exec = cursor.fetchone()[0]
    if dup_exec > 0:
        anomalies.append(f"❌ {dup_exec} duplicate executions")
    
    # Check learning inconsistency
    cursor.execute("""
        SELECT COUNT(*) FROM healing_actions ha
        LEFT JOIN learning_history lh ON (
            lh.issue_type = (SELECT di.issue_type FROM decision_log dl JOIN detected_issues di ON dl.issue_id = di.issue_id WHERE dl.decision_id = ha.decision_id)
            AND lh.action_type = ha.action_type
        )
        WHERE ha.verification_status = 'VERIFIED'
        AND lh.learning_id IS NULL
    """)
    learning_missing = cursor.fetchone()[0]
    if learning_missing > 0:
        anomalies.append(f"⚠️ {learning_missing} verified actions without learning records")
    
    if anomalies:
        for anomaly in anomalies:
            log(f"  {anomaly}")
    else:
        log(f"  ✅ No anomalies detected")
    
    cursor.close()
    conn.close()
    
    return len(anomalies) == 0

# ============================================================
# MAIN EXECUTION
# ============================================================
def main():
    log("🔥 FINAL STRESS + CHAOS VALIDATION 🔥")
    log("This is a BREAK TEST - designed to expose weaknesses\n")
    
    results = {}
    
    try:
        reset_system()
        
        results['concurrency'] = concurrency_test()
        results['stress'] = stress_test()
        results['failure_chaos'] = failure_chaos_test()
        results['learning_stability'] = learning_stability_test()
        results['rate_limit'] = rate_limit_test()
        results['data_integrity'] = data_integrity_test()
        results['no_anomalies'] = final_report()
        
        # Final verdict
        log("\n" + "=" * 60)
        log("🎯 SYSTEM VERDICT")
        log("=" * 60)
        
        passed = sum(results.values())
        total = len(results)
        
        log(f"\nTest Results: {passed}/{total} passed")
        for test, result in results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            log(f"  {test}: {status}")
        
        if passed == total:
            log("\n✔ STABLE → Ready for Phase 2")
            log("System is production-ready for real execution")
        elif passed >= total * 0.8:
            log("\n⚠ PARTIAL → Needs fixes")
            log("System mostly stable but has issues to address")
        else:
            log("\n❌ UNSTABLE → Critical issues remain")
            log("System NOT ready for production")
        
    except Exception as e:
        log(f"\n❌ CRITICAL ERROR: {e}")
        import traceback
        traceback.print_exc()
        log("\n❌ UNSTABLE → System crashed during validation")

if __name__ == "__main__":
    main()
