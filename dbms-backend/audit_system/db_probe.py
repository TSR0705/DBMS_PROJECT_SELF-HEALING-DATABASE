import mysql.connector
import os
import time
from datetime import datetime

class DBProbe:
    def __init__(self):
        self.config = {
            'host': os.getenv('DB_HOST', '127.0.0.1'),
            'user': os.getenv('DB_USER', 'root'),
            'password': os.getenv('DB_PASSWORD', 'Tsr@2007'),
            'database': os.getenv('DB_NAME', 'dbms_self_healing'),
            'autocommit': True
        }

    def get_connection(self):
        return mysql.connector.connect(**self.config)

    def run_query(self, sql, params=None):
        conn = self.get_connection()
        cursor = conn.cursor(dictionary=True, buffered=True)
        try:
            cursor.execute(sql, params or ())
            res = None
            if cursor.with_rows:
                res = cursor.fetchall()
            
            # Consuming any extra result sets (multi-statement or procedure side effects)
            try:
                while cursor.nextset():
                    pass
            except: pass
                
            return res
        finally:
            cursor.close()
            conn.close()

    def call_procedure(self, proc_name, params=None):
        conn = self.get_connection()
        cursor = conn.cursor(buffered=True)
        try:
            cursor.callproc(proc_name, params or [])
            # Consume all result sets to prevent "Unread result found"
            for result in cursor.stored_results():
                result.fetchall()
            conn.commit()
        finally:
            cursor.close()
            conn.close()

    def get_last_issue(self):
        return self.run_query("SELECT * FROM detected_issues ORDER BY issue_id DESC LIMIT 1")

    def get_last_decision(self, issue_id):
        return self.run_query("SELECT * FROM decision_log WHERE issue_id = %s", (issue_id,))

    def get_last_action(self, decision_id):
        return self.run_query("SELECT * FROM healing_actions WHERE decision_id = %s", (decision_id,))

    def get_system_metrics(self):
        return self.run_query("SELECT * FROM system_metrics ORDER BY metric_id DESC LIMIT 1")

    def clear_state(self):
        """Clears all issue related tables for a clean audit run."""
        tables = [
            'learning_history', 'healing_actions', 'admin_reviews', 
            'decision_log', 'ai_analysis', 'detected_issues', 'debug_log'
        ]
        self.run_query("SET FOREIGN_KEY_CHECKS = 0")
        for table in tables:
            self.run_query(f"TRUNCATE TABLE {table}")
        self.run_query("SET FOREIGN_KEY_CHECKS = 1")
