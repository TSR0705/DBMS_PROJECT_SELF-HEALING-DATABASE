# Quick Start: SLOW_QUERY Validation Testing

## 🚀 3-Step Validation Process

### Step 1: Reload SQL Procedure (REQUIRED)
The validation logic has been fixed. You MUST reload the procedure:

```bash
cd dbms-backend
mysql -u root -p dbms_self_healing < app/database/sql/step2_engine/00_validation_library.sql
```

Or using Python:
```bash
cd dbms-backend
python scratch/reload_procedures.py
```

### Step 2: Run Automated Tests
```bash
cd dbms-backend
python scratch/validate_slow_query_fix.py
```

### Step 3: Review Results
Look for:
```
Results: 5/5 tests passed
🎉 ALL TESTS PASSED!
```

---

## ⚡ What Was Fixed

**Problem:** Single slow queries were NOT being auto-healed

**Root Cause:** Validation required BOTH:
- Slow query exists ✅
- AND (connections > 10 OR queries > 3) ❌

**Fix:** Simplified to:
- Slow query exists ✅ → AUTO_HEAL

---

## 📊 Expected Test Results

| Test | Expected Result |
|------|----------------|
| **1. Single Slow Query** | ✅ KILLED + VERIFIED |
| **2. Short Query** | ✅ NOT KILLED (below threshold) |
| **3. Multiple Queries** | ✅ HIGHEST TIME targeted |
| **4. Debug Logs** | ✅ Validation data logged |
| **5. Pipeline Flow** | ✅ QUEUED → SUCCESS → VERIFIED |

---

## 🔍 Manual Verification (If Automated Tests Fail)

### 1. Start slow query
```sql
-- Session 1:
SELECT SLEEP(60);
```

### 2. Trigger healing (Session 2)
```sql
-- Insert issue
INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, detected_at)
VALUES ('SLOW_QUERY', 'MANUAL_TEST', 10.5, NOW());

-- Run pipeline
CALL run_auto_heal_pipeline();
```

### 3. Check results
```sql
-- Should show AUTO_HEAL (not ADMIN_REVIEW)
SELECT decision_type, decision_reason 
FROM decision_log 
WHERE issue_id = (SELECT MAX(issue_id) FROM detected_issues WHERE detection_source = 'MANUAL_TEST');

-- Should show SUCCESS + VERIFIED
SELECT execution_status, verification_status 
FROM healing_actions 
WHERE decision_id = (SELECT MAX(decision_id) FROM decision_log);

-- Should show validation logs
SELECT * FROM debug_log 
WHERE step = 'slow_query_validation' 
ORDER BY id DESC LIMIT 5;
```

---

## ✅ Success Indicators

**Before Fix (BROKEN):**
- decision_type: `ADMIN_REVIEW` ❌
- No execution_queue entry ❌
- Manual intervention required ❌

**After Fix (WORKING):**
- decision_type: `AUTO_HEAL` ✅
- execution_queue: `PENDING` → `PROCESSING` ✅
- execution_status: `SUCCESS` ✅
- verification_status: `VERIFIED` ✅

---

## 🐛 Common Issues

### Issue: Tests fail with "Decision type is ADMIN_REVIEW"
**Fix:** Procedure not reloaded. Run Step 1 again.

### Issue: "No queries found in processlist"
**Fix:** Query completed too fast. This is normal for Test 2 (short query).

### Issue: "Table debug_log doesn't exist"
**Fix:** 
```sql
CREATE TABLE IF NOT EXISTS debug_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    step VARCHAR(50),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 📁 Files Created

| File | Purpose |
|------|---------|
| `SLOW_QUERY_VALIDATION_FIX.md` | Technical details of the fix |
| `RUN_VALIDATION_TESTS.md` | Detailed test instructions |
| `VALIDATION_TEST_SUMMARY.md` | Complete test documentation |
| `validate_slow_query_fix.py` | Automated test suite |
| `quick_test.bat` / `.sh` | Quick test runners |

---

## 🎯 Bottom Line

1. **Reload procedure** (Step 1)
2. **Run tests** (Step 2)
3. **Verify 5/5 pass** (Step 3)

**Expected:** Single slow queries now trigger automatic healing instead of requiring manual review.

---

**Ready to test?** Run: `python scratch/validate_slow_query_fix.py`
