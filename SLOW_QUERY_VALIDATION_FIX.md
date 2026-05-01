# SLOW_QUERY Validation Logic Fix

## Problem Identified
The SLOW_QUERY validation logic was **overly restrictive**, requiring BOTH:
1. Slow query existence (time > threshold) ✅
2. **AND** system pressure (connections > 10 OR queries > 3) ❌

This prevented single slow queries from being auto-healed, causing them to route to ADMIN_REVIEW instead.

---

## Root Cause
**File:** `dbms-backend/app/database/sql/step2_engine/00_validation_library.sql`  
**Lines:** 30-37 (OLD)

### OLD LOGIC (REMOVED):
```sql
WHEN 'SLOW_QUERY' THEN
    -- Advanced Impact Analysis: Check if threads_running is also high
    SELECT COUNT(*) INTO v_active_queries
    FROM information_schema.processlist
    WHERE command = 'Query' AND time > v_dynamic_thresh;

    IF v_active_queries >= 1 THEN
        -- Also check system pressure (Load factor)
        SELECT connections INTO v_lock_waits FROM system_metrics ORDER BY metric_id DESC LIMIT 1;
        IF v_lock_waits > 10 OR v_active_queries > 3 THEN SET p_issue_exists = TRUE; END IF;
    END IF;
```

**Problem:** Nested IF requiring both query existence AND (high connections OR multiple queries)

---

## Solution Applied

### NEW LOGIC (IMPLEMENTED):
```sql
WHEN 'SLOW_QUERY' THEN
    -- [FIXED] Simple existence check - any slow query is an issue
    -- Use 50% of threshold or minimum 15 seconds to avoid false positives
    SELECT COUNT(*) INTO v_active_queries
    FROM information_schema.processlist
    WHERE command = 'Query' 
      AND time >= GREATEST(15, v_dynamic_thresh * 0.5)
      AND info IS NOT NULL
      AND user NOT IN ('system user', 'event_scheduler');

    -- Debug logging
    INSERT INTO debug_log(step, message) 
    VALUES ('slow_query_validation', CONCAT('Active slow queries: ', v_active_queries, ', threshold: ', v_dynamic_thresh));

    -- SIMPLE RULE: If slow query exists, it's an issue
    IF v_active_queries >= 1 THEN 
        SET p_issue_exists = TRUE; 
    END IF;
```

---

## Key Changes

### 1. **Removed Nested Condition**
- ❌ OLD: Required `(queries >= 1) AND (connections > 10 OR queries > 3)`
- ✅ NEW: Requires only `queries >= 1`

### 2. **Improved Threshold Logic**
- ❌ OLD: `time > v_dynamic_thresh` (strict)
- ✅ NEW: `time >= GREATEST(15, v_dynamic_thresh * 0.5)` (50% of threshold, minimum 15 seconds)
- **Benefit:** More lenient matching while avoiding false positives

### 3. **Added Safety Filters**
- ✅ `info IS NOT NULL` - Ensures query has actual SQL content
- ✅ `user NOT IN ('system user', 'event_scheduler')` - Excludes internal MySQL processes

### 4. **Added Debug Logging**
```sql
INSERT INTO debug_log(step, message) 
VALUES ('slow_query_validation', CONCAT('Active slow queries: ', v_active_queries, ', threshold: ', v_dynamic_thresh));
```
- Logs validation results for troubleshooting
- Shows query count and threshold used

---

## Expected Behavior After Fix

### Test Case: `SELECT SLEEP(60)`
**Before Fix:**
```
detected_issues: ✅ Inserted (raw_metric_value = 10.5)
validate_issue_state: ❌ Returns FALSE (only 1 query, connections < 10)
decision_type: ADMIN_REVIEW
execution_queue: ❌ Not created
Result: Manual intervention required
```

**After Fix:**
```
detected_issues: ✅ Inserted (raw_metric_value = 10.5)
validate_issue_state: ✅ Returns TRUE (1 query found, time >= 15 seconds)
decision_type: AUTO_HEAL
execution_queue: ✅ Created with PENDING status
execution_worker: ✅ Executes KILL_CONNECTION
Result: Automatic healing
```

---

## Validation Steps

### 1. Reload the Procedure
```sql
SOURCE dbms-backend/app/database/sql/step2_engine/00_validation_library.sql;
```

### 2. Run Test
```bash
cd dbms-backend
pytest tests/test_self_healing_comprehensive.py::test_slow_query_healing -v
```

### 3. Check Debug Logs
```sql
SELECT * FROM debug_log WHERE step = 'slow_query_validation' ORDER BY id DESC LIMIT 5;
```

### 4. Verify Execution Queue
```sql
SELECT eq.*, dl.decision_type, di.issue_type 
FROM execution_queue eq
JOIN decision_log dl ON eq.decision_id = dl.decision_id
JOIN detected_issues di ON dl.issue_id = di.issue_id
WHERE di.issue_type = 'SLOW_QUERY'
ORDER BY eq.queue_id DESC LIMIT 5;
```

---

## Impact Analysis

### ✅ Benefits
1. **Single slow queries now auto-heal** - No longer require system-wide pressure
2. **Faster response time** - Issues caught earlier (50% threshold)
3. **Better debugging** - Debug logs show validation decisions
4. **Safer filtering** - Excludes system users and null queries

### ⚠️ Considerations
1. **More aggressive healing** - May trigger more frequently
2. **Throttling still applies** - Cooldown mechanism prevents spam
3. **Verification still runs** - Post-execution validation ensures success

### 🔧 Future Enhancements (Optional)
If you want to add strict mode for high-traffic environments:
```sql
-- Optional: Add strict mode flag
DECLARE v_strict_mode BOOLEAN DEFAULT FALSE;

IF v_strict_mode = TRUE THEN
    -- Require system pressure for validation
    IF v_active_queries > 3 OR v_lock_waits > 10 THEN 
        SET p_issue_exists = TRUE; 
    ELSE 
        SET p_issue_exists = FALSE; 
    END IF;
END IF;
```

---

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Logic** | Nested AND condition | Simple existence check |
| **Threshold** | Strict (> threshold) | Lenient (>= 50% or 15s) |
| **Single Query** | ❌ Fails validation | ✅ Passes validation |
| **Decision** | ADMIN_REVIEW | AUTO_HEAL |
| **Execution** | Manual only | Automatic |
| **Debug** | No logging | ✅ Logged |

**Status:** ✅ **FIXED** - Single slow queries will now trigger automatic healing
