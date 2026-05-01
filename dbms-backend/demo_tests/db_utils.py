import mysql.connector
import os
from datetime import datetime

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    CYAN = '\033[96m'
    RESET = '\033[0m'

def get_connection():
    return mysql.connector.connect(
        host=os.getenv('DB_HOST', '127.0.0.1'),
        user=os.getenv('DB_USER', 'root'),
        password=os.getenv('DB_PASSWORD', 'Tsr@2007'),
        database=os.getenv('DB_NAME', 'dbms_self_healing'),
        autocommit=True
    )

def run_query(sql, params=None):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, params or ())
        conn.commit()
    finally:
        cursor.close()
        conn.close()

def insert_and_get_id(sql, params=None):
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute(sql, params or ())
        conn.commit()
        return cursor.lastrowid
    finally:
        cursor.close()
        conn.close()

def fetch_one(sql, params=None):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(sql, params or ())
        rows = cursor.fetchall()
        return rows[0] if rows else None
    finally:
        cursor.close()
        conn.close()

def fetch_all(sql, params=None):
    conn = get_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute(sql, params or ())
        return cursor.fetchall()
    finally:
        cursor.close()
        conn.close()

def print_section(title):
    print(f"\n{Colors.CYAN}{'='*60}")
    print(f" {title} ")
    print(f"{'='*60}{Colors.RESET}\n")

def log_step(msg, status="INFO"):
    timestamp = datetime.now().strftime("%H:%M:%S")
    if status == "PASS":
        print(f"[{timestamp}] {Colors.GREEN}[PASS] {msg}{Colors.RESET}")
    elif status == "FAIL":
        print(f"[{timestamp}] {Colors.RED}[FAIL] {msg}{Colors.RESET}")
    elif status == "WARN":
        print(f"[{timestamp}] {Colors.YELLOW}[WARN] {msg}{Colors.RESET}")
    else:
        print(f"[{timestamp}] [INFO] {msg}")
