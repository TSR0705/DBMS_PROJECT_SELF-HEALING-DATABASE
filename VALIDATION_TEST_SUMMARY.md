# SLOW_QUERY Validation Test Summary

## 🎯 Objective
Perform a FULL VALIDATION TEST of the SLOW_QUERY handling after fixing the overly restrictive validation logic.

---

## 📋 Test Suite Overview

### Test 1: Single Slow Query (SHOULD BE KILLED)
**Scenario:** Run `SELECT SLEEP(60)` for 20+ seconds  
**Expected Outcome:**
- ✅ Query detected in processlist
- ✅ `detected_issues` entry created
- ✅ `decision_type` = `AUTO_HEAL` (not ADMIN_REVIEW)
- ✅ `execution_queue` entry created
- ✅ Query is KILLED
- ✅ `execution_status` = `SUCCESS`
- ✅ `verification_status` = `VERIFIED`

**Validates:** Single slow queries now trigger automatic healing

---

### Test 2: Short Query (SHOULD NOT BE KILLED)
**Scenario:** Run `SELECT SLEEP(5)` (below effective threshold)  
**Expected Outcome:**
- ✅ Query runs but doesn't meet threshold
- ✅ Validation returns FALSE (query too short)
- ✅ `decision_type` = `ADMIN_REVIEW` OR action = `SKIPPED_STALE_ISSUE`
- ✅ Query NOT killed

**Validates:** Threshold logic prevents false positives (50% of 10.5 = 5.25s, or minimum 15s)

---

### Test 3: Multiple Slow Queries (TARGET HIGHEST TIME)
**Scenario:** Run 3 concurrent `SELECT SLEEP(60)` queries with staggered start times  
**Expected Outcome:**
- ✅ All 3 queries detected in processlist
- ✅ System validates issue exists (count >= 1)
- ✅ Execution engine targets query with HIGHEST time
- ✅ One query is killed (the longest-running one)
- ✅ `execution_status` = `SUCCESS`

**Validates:** System correctly prioritizes longest-running query

---

### Test 4: Validation Trace (DEBUG LOGS)
**Scenario:** Check `debug_log` table for validation entries  
**Expected Outcome:**
- ✅ Debug logs contain `slow_query_validation` entries
- ✅ Logs show "Active slow queries: X"
- ✅ Logs show "threshold: Y"
- ✅ Query counts match actual processlist

**Validates:** Debug logging provides visibility into validation decisions

---

### Test 5: Pipeline Flow Check
**Scenario:** Verify complete pipeline execution  
**Expected Outcome:**
- ✅ `execution_queue` entries exist with status progression
- ✅ `execution_context` entries show worker assignment
- ✅ `healing_actions` entries show execution results
- ✅ Flow: `PENDING` → `PROCESSING` → `SUCCESS` → `VERIFIED`

**Validates:** End-to-end pipeline integrity

---

## 🔧 How to Run Tests

### Quick Start (Windows)
```bash
cd dbms-backend/scratch
quick_test.bat
```

### Quick Start (Linux/Mac)
```bash
cd dbms-backend/scratch
chmod +x quick_test.sh
./quick_test.sh
```

### Manual Run
```bash
cd dbms-backend
python scratch/validate_slow_query_fix.py
```

---

## 📊 Expected Output Format

```
================================================================================
TEST 1: SINGLE SLOW QUERY (SHOULD BE KILLED)
================================================================================

[TEST] Starting test...
ℹ Waiting for query to appear in processlist...
✓ Query found in processlist: time=5s
ℹ Inserting detected_issues entry...
Issue ID: 123
ℹ Running auto-heal pipeline...
Decision Type: AUTO_HEAL
Decision Reason: AUTO_HEAL authorized: Phase 7 Smart Priority (0.85)
Queue Status: PROCESSING
Action Type: KILL_CONNECTION
Execution Status: SUCCESS
Verification Status: VERIFIED
✓ TEST 1 PASSED: Query killed and verified

================================================================================
TEST SUMMARY
================================================================================

PASS - TEST 1: Single Slow Query
      issue_id: 123
      decision_type: AUTO_HEAL
      execution_status: SUCCESS
      verification_status: VERIFIED

PASS - TEST 2: Short Query
      issue_id: 124
      decision_type: ADMIN_REVIEW

PASS - TEST 3: Multiple Slow Queries
      issue_id: 125
      query_count: 3
      execution_status: SUCCESS

PASS - TEST 4: Validation Trace
      log_count: 5

PASS - TEST 5: Pipeline Flow
      queue_count: 3
      action_count: 3

Results: 5/5 tests passed

🎉 ALL TESTS PASSED! SLOW_QUERY handling is working correctly.
```

---

## 🔍 What Each Test Validates

| Test | Validates | Key Condition |
|------|-----------|---------------|
| **Test 1** | Single slow query auto-healing | `v_active_queries >= 1` → `AUTO_HEAL` |
| **Test 2** | Threshold filtering | `time >= GREATEST(15, threshold * 0.5)` |
| **Test 3** | Query prioritization | Execution targets `ORDER BY time DESC` |
| **Test 4** | Debug visibility | Debug logs inserted correctly |
| **Test 5** | Pipeline integrity | Complete flow from detection to verification |

---

## 🐛 Troubleshooting

### Problem: "No queries found in processlist"
**Cause:** Query completed before validation  
**Solution:** Increase SLEEP duration or reduce wait time in test

### Problem: "Decision type is ADMIN_REVIEW"
**Cause:** Validation procedure not reloaded  
**Solution:** 
```bash
mysql -u root -p dbms_self_healing < app/database/sql/step2_engine/00_validation_library.sql
```

### Problem: "Table debug_log doesn't exist"
**Cause:** Missing debug_log table  
**Solution:**
```sql
CREATE TABLE IF NOT EXISTS debug_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    step VARCHAR(50),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Problem: "SKIPPED_STALE_ISSUE"
**Cause:** Query completed before execution  
**Solution:** This is expected for Test 2 (short query), but not Test 1. Check timing.

---

## ✅ Success Criteria

**All 5 tests must PASS:**
1. ✅ Single slow query → AUTO_HEAL → KILLED → VERIFIED
2. ✅ Short query → ADMIN_REVIEW or SKIPPED
3. ✅ Multiple queries → Highest time targeted
4. ✅ Debug logs → Show validation data
5. ✅ Pipeline flow → QUEUED → PROCESSING → SUCCESS → VERIFIED

---

## 📈 Before vs After Fix

### Before Fix (BROKEN)
```
Single SLOW_QUERY detected
  ↓
validate_issue_state() checks:
  - v_active_queries >= 1 ✅ (1 query found)
  - v_lock_waits > 10 ❌ (only 2 connections)
  - v_active_queries > 3 ❌ (only 1 query)
  ↓
p_issue_exists = FALSE
  ↓
decision_type = ADMIN_REVIEW
  ↓
No execution_queue entry
  ↓
Manual intervention required ❌
```

### After Fix (WORKING)
```
Single SLOW_QUERY detected
  ↓
validate_issue_state() checks:
  - v_active_queries >= 1 ✅ (1 query found)
  ↓
p_issue_exists = TRUE
  ↓
decision_type = AUTO_HEAL
  ↓
execution_queue entry created
  ↓
execute_healing_action_v2() runs
  ↓
Query KILLED
  ↓
Verification: SUCCESS ✅
```

---

## 📝 Test Data Cleanup

The test script automatically cleans up test data before and after runs:
- `detected_issues` with `detection_source = 'VALIDATION_TEST'`
- Related `ai_analysis`, `decision_log`, `execution_queue`, `healing_actions`
- `debug_log` entries for `slow_query_validation`

Manual cleanup (if needed):
```sql
DELETE FROM healing_actions WHERE decision_id IN (
    SELECT decision_id FROM decision_log WHERE issue_id IN (
        SELECT issue_id FROM detected_issues WHERE detection_source = 'VALIDATION_TEST'
    )
);
DELETE FROM execution_queue WHERE decision_id IN (
    SELECT decision_id FROM decision_log WHERE issue_id IN (
        SELECT issue_id FROM detected_issues WHERE detection_source = 'VALIDATION_TEST'
    )
);
DELETE FROM decision_log WHERE issue_id IN (
    SELECT issue_id FROM detected_issues WHERE detection_source = 'VALIDATION_TEST'
);
DELETE FROM ai_analysis WHERE issue_id IN (
    SELECT issue_id FROM detected_issues WHERE detection_source = 'VALIDATION_TEST'
);
DELETE FROM detected_issues WHERE detection_source = 'VALIDATION_TEST';
```

---

## 🎓 Key Learnings

1. **Root Cause:** Nested AND condition required both query existence AND system pressure
2. **Fix:** Simplified to single existence check with improved threshold logic
3. **Threshold:** Uses `GREATEST(15, threshold * 0.5)` to balance sensitivity and false positives
4. **Debug Logging:** Added visibility into validation decisions
5. **Safety Filters:** Excludes system users and null queries

---

## 📞 Support

If tests fail:
1. Check `RUN_VALIDATION_TESTS.md` for detailed instructions
2. Review `SLOW_QUERY_VALIDATION_FIX.md` for technical details
3. Verify procedure reload: `SHOW CREATE PROCEDURE validate_issue_state;`
4. Check debug logs: `SELECT * FROM debug_log WHERE step = 'slow_query_validation';`

---

**Status:** ✅ Ready for validation testing  
**Last Updated:** 2026-05-01  
**Version:** 1.0
