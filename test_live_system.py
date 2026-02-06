#!/usr/bin/env python3
"""
Live System Test
Tests all API endpoints and verifies the system is working correctly.
"""

import requests
import json
from datetime import datetime

BASE_URL = "http://localhost:8002"

def test_endpoint(name, url):
    """Test a single endpoint."""
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            count = len(data) if isinstance(data, list) else (data.get('Count', 'N/A') if isinstance(data, dict) else 'N/A')
            print(f"✅ {name}: OK (Status: {response.status_code}, Records: {count})")
            return True, data
        else:
            print(f"❌ {name}: FAILED (Status: {response.status_code})")
            return False, None
    except Exception as e:
        print(f"❌ {name}: ERROR - {str(e)}")
        return False, None

def main():
    print("🧪 Live System Test")
    print("=" * 60)
    print(f"Testing backend at: {BASE_URL}")
    print(f"Test started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    endpoints = [
        ("Root", f"{BASE_URL}/"),
        ("Health Check", f"{BASE_URL}/health"),
        ("Database Health", f"{BASE_URL}/health/database"),
        ("Detected Issues", f"{BASE_URL}/issues/"),
        ("AI Analysis", f"{BASE_URL}/analysis/"),
        ("Decision Log", f"{BASE_URL}/decisions/"),
        ("Healing Actions", f"{BASE_URL}/actions/"),
        ("Admin Reviews", f"{BASE_URL}/admin-reviews/"),
        ("Learning History", f"{BASE_URL}/learning/"),
    ]
    
    results = []
    passed = 0
    failed = 0
    
    print("📋 Testing Endpoints:")
    print("-" * 60)
    
    for name, url in endpoints:
        success, data = test_endpoint(name, url)
        results.append((name, success, data))
        if success:
            passed += 1
        else:
            failed += 1
    
    print()
    print("=" * 60)
    print("📊 Test Summary:")
    print(f"   Total Endpoints: {len(endpoints)}")
    print(f"   Passed: {passed}")
    print(f"   Failed: {failed}")
    print(f"   Success Rate: {(passed/len(endpoints)*100):.1f}%")
    print()
    
    # Show database stats
    for name, success, data in results:
        if name == "Database Health" and success and data:
            print("📊 Database Statistics:")
            stats = data.get('database_stats', {})
            for key, value in stats.items():
                print(f"   {key}: {value}")
            print()
            break
    
    # Show sample data
    print("📋 Sample Data from Detected Issues:")
    for name, success, data in results:
        if name == "Detected Issues" and success and data:
            issues = data if isinstance(data, list) else data.get('value', [])
            for i, issue in enumerate(issues[:3], 1):
                print(f"   {i}. {issue.get('issue_type')} - {issue.get('detection_source')}")
                print(f"      Detected: {issue.get('detected_at')}")
            print()
            break
    
    print("📋 Sample Data from Decisions:")
    for name, success, data in results:
        if name == "Decision Log" and success and data:
            decisions = data if isinstance(data, list) else data.get('value', [])
            for i, decision in enumerate(decisions[:3], 1):
                print(f"   {i}. {decision.get('decision_type')} - Confidence: {decision.get('confidence_at_decision')}")
                print(f"      Reason: {decision.get('decision_reason')[:80]}...")
            print()
            break
    
    print("📋 Sample Data from Healing Actions:")
    for name, success, data in results:
        if name == "Healing Actions" and success and data:
            actions = data if isinstance(data, list) else data.get('value', [])
            for i, action in enumerate(actions[:3], 1):
                print(f"   {i}. {action.get('action_type')} - Mode: {action.get('execution_mode')}")
                print(f"      Status: {action.get('execution_status')}, Executed: {action.get('executed_at')}")
            print()
            break
    
    if passed == len(endpoints):
        print("🎉 All tests passed! System is fully operational.")
        return True
    else:
        print(f"⚠️  {failed} test(s) failed. Please review the errors above.")
        return False

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
