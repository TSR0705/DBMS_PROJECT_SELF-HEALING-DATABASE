import sys
import os
import time

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from demo_tests.db_utils import print_section, Colors, reset_system_state
from demo_tests.scenarios.slow_query_test import run_slow_query_test
from demo_tests.scenarios.deadlock_test import run_deadlock_test
from demo_tests.scenarios.overload_test import run_overload_test
from demo_tests.scenarios.admin_review_test import run_admin_review_scenarios

def print_result_details(res):
    print(f"\n  Details for {res['scenario']}:")
    details = res.get('details', {})
    for k, v in details.items():
        print(f"  - {k}: {v}")
    print()

def main():
    # [Step 0] Global Sync
    print_section("AI-ASSISTED SELF-HEALING DATABASE DEMO")
    results = []

    # [Category 1] AUTONOMOUS HEALING
    print(f"\n{Colors.CYAN}{Colors.BOLD}1. AUTONOMOUS HEALING SCENARIOS (Zero-Touch){Colors.RESET}")
    
    res_sq = run_slow_query_test()
    results.append(res_sq)
    print_result_details(res_sq)

    res_dl = run_deadlock_test()
    results.append(res_dl)
    print_result_details(res_dl)

    res_co = run_overload_test()
    results.append(res_co)
    print_result_details(res_co)

    # [Category 2] HUMAN-IN-THE-LOOP
    print(f"\n{Colors.CYAN}{Colors.BOLD}2. HUMAN-IN-THE-LOOP SCENARIOS (Admin Oversight){Colors.RESET}")
    
    res_ar = run_admin_review_scenarios()
    results.append(res_ar)
    print_result_details(res_ar)

    # [Final Summary]
    print_section("FINAL DEMO SUMMARY")
    for r in results:
        status_color = Colors.GREEN if r['status'] == 'PASS' else Colors.RED
        print(f"{r['scenario']:<25}: {status_color}{r['status']}{Colors.RESET}")
    
    print(f"\n{Colors.YELLOW}Note: Throttling, Idle Transactions, and Stale Issue Abort scenarios are currently inactive for this demo.{Colors.RESET}")
    print("\n")

if __name__ == "__main__":
    main()
