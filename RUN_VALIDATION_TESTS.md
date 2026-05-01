# SLOW_QUERY Validation Test Instructions

## Prerequisites

1. **Backend is running** (or database is accessible)
2. **Database connection configured** in `.env`
3. **Python environment activated**

## Step 1: Reload SQL Procedures

The validation logic has been updated in `00_validation_library.sql`. You need to reload it:

### Option A: Using MySQL CLI
```bash
cd dbms-backend
mysql -u root -p dbms_self_healing < app/database/sql/step2_engine/00_validation_library.sql
```

### Option B: Using Python Script
```bash
cd dbms-backend
python scratch/reload_procedures.py
```

### Option C: Manual SQL
```sql
SOURCE /path/to/dbms-backend/app/database/sql/step2_engine/00_validation_library.sql;
```

## Step 2: Run Validation Tests

```bash
cd dbms-backend
python scratch/validate_slow_query_fix.py
```

## Expected Test Results

### ✅ TEST 1: Single Slow Query
- **Action:** Runs `SELECT SLEEP(60)` for 20+ seconds
- **Expected:** Query is KILLED, status=SUCCESS, verification=VERIFIED
- **Validates:** Single slow queries now trigger AUTO_HEAL

### ✅ TEST 2: Short Query
- **Action:** Runs `SELECT SLEEP(5)` (below threshold)
- **Expected:** Query NOT killed, routed to ADMIN_REVIEW or SKIPPED
- **Validates:** Threshold logic works (50% of 10.5 = 5.25s, or minimum 15s)

### ✅ TEST 3: Multiple Slow Queries
- **Action:** Runs 3 concurrent `SELECT SLEEP(60)` queries
- **Expected:** System kills the query with highest time
- **Validates:** Execution engine targets longest-running query

### ✅ TEST 4: Validation Trace
- **Action:** Checks `debug_log` table
- **Expected:** Logs show query counts and thresholds
- **Validates:** Debug logging is working

### ✅ TEST 5: Pipeline Flow
- **Action:** Verifies `execution_queue`, `execution_context`, `healing_actions`
- **Expected:** Complete flow: QUEUED → PROCESSING → SUCCESS → VERIFIED
- **Validates:** End-to-end pipeline integrity

## Manual Verification (Alternative)

If automated tests fail, you can manually verify:

### 1. Start a slow query
```sql
-- In one MySQL session:
SELECT SLEEP(60);
```

### 2. Check processlist (in another session)
```sql
SELECT id, user, time, info 
FROM information_schema.processlist 
WHERE command = 'Query' AND info LIKE '%SLEEP%';
```

### 3. Insert detected issue
```sql
INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, detected_at)
VALUES ('SLOW_QUERY', 'MANUAL_TEST', 10.5, NOW());
```

### 4. Run pipeline
```sql
CALL run_auto_heal_pipeline();
```

### 5. Check results
```sql
-- Check decision
SELECT dl.*, di.issue_type 
FROM decision_log dl
JOIN detected_issues di ON dl.issue_id = di.issue_id
WHERE di.detection_source = 'MANUAL_TEST'
ORDER BY dl.decision_id DESC LIMIT 1;

-- Check execution queue
SELECT eq.* 
FROM execution_queue eq
JOIN decision_log dl ON eq.decision_id = dl.decision_id
JOIN detected_issues di ON dl.issue_id = di.issue_id
WHERE di.detection_source = 'MANUAL_TEST'
ORDER BY eq.queue_id DESC LIMIT 1;

-- Check healing action
SELECT ha.* 
FROM healing_actions ha
JOIN decision_log dl ON ha.decision_id = dl.decision_id
JOIN detected_issues di ON dl.issue_id = di.issue_id
WHERE di.detection_source = 'MANUAL_TEST'
ORDER BY ha.action_id DESC LIMIT 1;

-- Check debug logs
SELECT * FROM debug_log 
WHERE step = 'slow_query_validation' 
ORDER BY id DESC LIMIT 5;
```

### Expected Results:
- **decision_type:** `AUTO_HEAL` (not ADMIN_REVIEW)
- **execution_queue.status:** `PROCESSING` or `COMPLETED`
- **healing_actions.execution_status:** `SUCCESS`
- **healing_actions.verification_status:** `VERIFIED`
- **debug_log:** Shows "Active slow queries: 1, threshold: 10.5"

## Troubleshooting

### Issue: Tests fail with "No queries found in processlist"
**Solution:** Increase wait time or check if queries are being killed too quickly

### Issue: Decision type is ADMIN_REVIEW instead of AUTO_HEAL
**Solution:** 
1. Verify procedure was reloaded: `SHOW CREATE PROCEDURE validate_issue_state;`
2. Check if the new logic is present (should have `GREATEST(15, v_dynamic_thresh * 0.5)`)
3. Reload procedure again

### Issue: "Table debug_log doesn't exist"
**Solution:** Create the table:
```sql
CREATE TABLE IF NOT EXISTS debug_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    step VARCHAR(50),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Issue: Execution status is SKIPPED_STALE_ISSUE
**Solution:** This means the query completed before execution. This is expected for TEST 2 (short query) but not TEST 1. Increase SLEEP duration or reduce wait time.

## Success Criteria

All 5 tests should PASS:
- ✅ TEST 1: Single slow query is killed automatically
- ✅ TEST 2: Short query is not killed (validation rejects)
- ✅ TEST 3: Multiple queries handled correctly
- ✅ TEST 4: Debug logs show validation data
- ✅ TEST 5: Complete pipeline flow verified

## What Changed

### Before Fix:
```sql
-- Required BOTH conditions:
IF v_active_queries >= 1 THEN
    IF v_lock_waits > 10 OR v_active_queries > 3 THEN 
        SET p_issue_exists = TRUE; 
    END IF;
END IF;
```
**Result:** Single slow query with low connections → ADMIN_REVIEW

### After Fix:
```sql
-- Simple existence check:
IF v_active_queries >= 1 THEN 
    SET p_issue_exists = TRUE; 
END IF;
```
**Result:** Single slow query → AUTO_HEAL

## Next Steps

After validation passes:
1. Monitor production behavior
2. Adjust threshold if needed (currently 50% of detected value, min 15s)
3. Consider adding strict mode flag for high-traffic environments
4. Review throttling settings if too aggressive
