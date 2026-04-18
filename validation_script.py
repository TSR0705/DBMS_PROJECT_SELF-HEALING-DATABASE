import mysql.connector
import time

config = {
    'host': 'localhost',
    'user': 'root',
    'password': 'Tsr@2007',
    'database': 'dbms_self_healing',
}

def run_tests():
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor(dictionary=True)
        
        print("=> Applying Schema & Procedure Updates...")
        import os
        exit_code = os.system('mysql -u root -pTsr@2007 dbms_self_healing < run_validation.sql')
        if exit_code != 0:
            print(f"Failed to apply SQL script. Exit code: {exit_code}")
            return
        
        # Re-initialize connector for testing since schema changed
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor(dictionary=True)
        
        # Clean up existing test data to ensure clean run
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
        cursor.execute("TRUNCATE TABLE healing_actions;")
        cursor.execute("TRUNCATE TABLE decision_log;")
        cursor.execute("TRUNCATE TABLE learning_history;")
        cursor.execute("TRUNCATE TABLE admin_reviews;")
        cursor.execute("TRUNCATE TABLE debug_log;")
        cursor.execute("TRUNCATE TABLE ai_analysis;")
        cursor.execute("TRUNCATE TABLE detected_issues;")
        cursor.execute("UPDATE action_rules SET is_automatic = 0 WHERE issue_type = 'SLOW_QUERY';")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")
        conn.commit()

        print("\n==================================")
        print("====== V A L I D A T I O N ======")
        print("==================================\n")

        # --- PHASE 1 ---
        print("--- PHASE 1: VERIFY EVENT AUTOMATION ---")
        cursor.execute("SHOW VARIABLES LIKE 'event_scheduler'")
        scheduler = cursor.fetchone()
        
        cursor.execute("SELECT EVENT_NAME, STATUS FROM INFORMATION_SCHEMA.EVENTS WHERE EVENT_NAME = 'evt_auto_heal_pipeline' AND EVENT_SCHEMA = 'dbms_self_healing'")
        event = cursor.fetchone()
        
        if scheduler['Value'] == 'ON' and event and event['STATUS'] == 'ENABLED':
            print("PASS: event_scheduler = ON, evt_auto_heal_pipeline = ENABLED\n")
        else:
            print(f"FAIL: scheduler={scheduler}, event={event}\n")
            return

        # --- PHASE 2/3 ---
        # Note: Phase 2 was completed in the SQL file above. Phase 3 verifies it.
        print("--- PHASE 3: VERIFY ADMIN REVIEW INSERTION ---")
        cursor.execute("INSERT INTO detected_issues(issue_type, detection_source, raw_metric_value) VALUES ('SLOW_QUERY', 'INNODB', 999)")
        conn.commit()
        issue_id = cursor.lastrowid
        
        print(f"Injected test issue {issue_id}. Waiting 15 sec for pipeline to process passively...")
        time.sleep(15)
        
        cursor.execute("SELECT * FROM admin_reviews ORDER BY review_id DESC LIMIT 5")
        reviews = cursor.fetchall()
        
        if len(reviews) > 0 and any(r['issue_id'] == issue_id and r['review_status'] == 'PENDING' for r in reviews):
            r = next(r for r in reviews if r['issue_id'] == issue_id)
            print(f"PASS: Found PENDING review logic for Decision #{r['decision_id']}\n")
        else:
            print("FAIL: No PENDING review found. Output:", reviews, "\n")
            return

        # --- PHASE 4 ---
        print("--- PHASE 4: FULL PIPELINE TRACE ---")
        cursor.execute("SELECT * FROM detected_issues WHERE issue_id = %s", (issue_id,))
        detected = cursor.fetchone()
        cursor.execute("SELECT * FROM ai_analysis WHERE issue_id = %s", (issue_id,))
        analysis = cursor.fetchone()
        cursor.execute("SELECT * FROM decision_log WHERE issue_id = %s", (issue_id,))
        decision = cursor.fetchone()
        cursor.execute("SELECT * FROM admin_reviews WHERE issue_id = %s", (issue_id,))
        admin_rev = cursor.fetchone()
        
        if detected and analysis and decision and admin_rev:
            print(f"PASS: Full trace valid for Issue {issue_id}")
            print(f" - Detected: {detected['issue_type']}")
            print(f" - Analysis: {analysis['severity_level']}")
            print(f" - Decision: {decision['decision_type']}")
            print(f" - Admin Rev: {admin_rev['review_status']}\n")
            target_decision_id = decision['decision_id']
        else:
            print("FAIL: Missing pipeline stage. Outputs:", detected, analysis, decision, admin_rev, "\n")
            return

        # --- PHASE 5 ---
        print("--- PHASE 5: ADMIN ACTION EXECUTION (APPROVE) ---")
        cursor.execute("CALL process_admin_review(%s, 'APPROVE')", (target_decision_id,))
        conn.commit()
        
        cursor.execute("SELECT * FROM healing_actions WHERE decision_id = %s", (target_decision_id,))
        healing = cursor.fetchall()
        cursor.execute("SELECT * FROM learning_history WHERE decision_id = %s", (target_decision_id,))
        learning = cursor.fetchall()
        
        if len(healing) > 0 and len(learning) > 0:
            print(f"PASS: process_admin_review() triggered Healing ({len(healing)} row) and Learning ({len(learning)} row).\n")
        else:
            print(f"FAIL: Healing ({len(healing)}) or Learning ({len(learning)}) missing.\n")
            return

        # --- PHASE 6 ---
        print("--- PHASE 6: REJECTION FLOW TEST ---")
        cursor.execute("INSERT INTO detected_issues(issue_type, detection_source, raw_metric_value) VALUES ('SLOW_QUERY', 'INNODB', 888)")
        conn.commit()
        issue_id_reject = cursor.lastrowid
        print("Waiting 15 sec for pipeline to process second issue...")
        time.sleep(15)
        
        cursor.execute("SELECT decision_id FROM decision_log WHERE issue_id = %s", (issue_id_reject,))
        decision_reject_id = cursor.fetchone()['decision_id']
        
        cursor.execute("CALL process_admin_review(%s, 'REJECT')", (decision_reject_id,))
        conn.commit()
        
        cursor.execute("SELECT * FROM healing_actions WHERE decision_id = %s", (decision_reject_id,))
        reject_healing = cursor.fetchall()
        
        if len(reject_healing) == 0:
            print("PASS: Rejection bypassed execution logic flawlessly.\n")
        else:
            print("FAIL: Healing action created despite REJECT.\n")
            return

        # --- PHASE 7 ---
        print("--- PHASE 7: DUPLICATE PROTECTION TEST ---")
        cursor.execute("SELECT decision_id, COUNT(*) as cnt FROM admin_reviews GROUP BY decision_id HAVING cnt > 1")
        dups = cursor.fetchall()
        if len(dups) == 0:
            print("PASS: No duplicate admin_reviews found.\n")
        else:
            print(f"FAIL: Duplicates found: {dups}\n")
            return

        # --- PHASE 8 ---
        print("--- PHASE 8: CONCURRENCY TEST ---")
        print("Injecting 20 records rapidly...")
        for _ in range(20):
            cursor.execute("INSERT INTO detected_issues(issue_type, detection_source, raw_metric_value) VALUES ('SLOW_QUERY', 'INNODB', 777)")
        conn.commit()
        
        print("Waiting 20 seconds...")
        time.sleep(20)
        
        cursor.execute("SELECT COUNT(*) as d_cnt FROM detected_issues WHERE raw_metric_value = 777")
        d_cnt = cursor.fetchone()['d_cnt']
        cursor.execute("SELECT COUNT(*) as r_cnt FROM admin_reviews ar JOIN detected_issues di ON ar.issue_id = di.issue_id WHERE di.raw_metric_value = 777")
        r_cnt = cursor.fetchone()['r_cnt']
        
        if d_cnt == 20 and r_cnt == 20:
            print(f"PASS: {d_cnt} generated matching {r_cnt} correctly processed admin_reviews.\n")
        else:
            print(f"FAIL: Expected 20/20. Got {d_cnt} detected and {r_cnt} reviews.\n")
            return

        # --- PHASE 9 ---
        print("--- PHASE 9: SYSTEM INTEGRITY CHECK ---")
        cursor.execute("SELECT * FROM debug_log ORDER BY created_at DESC LIMIT 20")
        logs = cursor.fetchall()
        errors = [l for l in logs if 'error' in str(l['message']).lower()]
        if len(errors) == 0 and len(logs) > 0:
            print(f"PASS: Trace checked {len(logs)} logs without system errors.\n")
        else:
            print("FAIL:", errors, "\n")
            return

        # --- PHASE 10 ---
        print("--- PHASE 10: AUTONOMY VALIDATION ---")
        cursor.execute("INSERT INTO detected_issues(issue_type, detection_source, raw_metric_value) VALUES ('SLOW_QUERY', 'INNODB', 666)")
        conn.commit()
        auto_id = cursor.lastrowid
        print("Waiting 15 seconds for event_scheduler to implicitly heal...")
        time.sleep(15)
        cursor.execute("SELECT review_status FROM admin_reviews WHERE issue_id = %s", (auto_id,))
        ar_auto = cursor.fetchone()
        
        if ar_auto is not None and ar_auto['review_status'] == 'PENDING':
            print("PASS: System autonomously handled the request using background events unconditionally.\n")
            print("===> FINAL CLASSIFICATION: C) Fully Autonomous + Human Review System")
        else:
            print("FAIL: manual trigger suspected.\n")
            return
            
    except Exception as e:
        print(f"System Error: {e}")
    finally:
        if 'conn' in locals() and conn.is_connected():
            cursor.close()
            conn.close()

if __name__ == '__main__':
    run_tests()
