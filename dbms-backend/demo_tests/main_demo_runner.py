import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from demo_tests.db_utils import print_section, Colors
from demo_tests.scenarios.slow_query_test import run_slow_query_test
from demo_tests.scenarios.deadlock_test import run_deadlock_test
from demo_tests.scenarios.overload_test import run_overload_test

def print_result_details(res):
    print("\n  Details:")
    details = res.get('details', {})
    for k, v in details.items():
        print(f"  - {k}: {v}")
    print()

def main():
    print_section("AI-ASSISTED SELF-HEALING DATABASE DEMO")
    
    results = []

    res_sq = run_slow_query_test()
    results.append(res_sq)
    print_result_details(res_sq)

    res_dl = run_deadlock_test()
    results.append(res_dl)
    print_result_details(res_dl)

    res_co = run_overload_test()
    results.append(res_co)
    print_result_details(res_co)

    print_section("FINAL DEMO RESULT")
    for r in results:
        status_color = Colors.GREEN if r['status'] == 'PASS' else Colors.RED
        print(f"{r['scenario']:<20}: {status_color}{r['status']}{Colors.RESET}")
    print("\n")

if __name__ == "__main__":
    main()
