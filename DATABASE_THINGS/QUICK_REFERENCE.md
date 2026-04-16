# Automatic Detection - Quick Reference Card

## 🚀 Quick Start (3 Commands)

```sql
-- 1. Enable event scheduler
SET GLOBAL event_scheduler = ON;

-- 2. Run installation script
SOURCE automatic_detection_system.sql;

-- 3. Verify it's working
SELECT * FROM detected_issues WHERE detected_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE);
```

---

## 📊 Key Commands

### Check Status
```sql
-- Is event scheduler running?
SELECT @@event_scheduler;

-- Is detection event active?
SHOW EVENTS WHERE Name = 'auto_detect_issues';

-- When did it last run?
SELECT last_executed FROM information_schema.events 
WHERE event_name = 'auto_detect_issues';
```

### Control Detection
```sql
-- Disable detection
ALTER EVENT auto_detect_issues DISABLE;

-- Enable detection
ALTER EVENT auto_detect_issues ENABLE;

-- Run detection manually
CALL run_automatic_detection();
```

### View Detections
```sql
-- Recent detections (last hour)
SELECT * FROM detected_issues 
WHERE detected_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY detected_at DESC;

-- Detection summary
SELECT issue_type, COUNT(*) as count 
FROM detected_issues 
WHERE detected_at > DATE_SUB(NOW(), INTERVAL 24 HOUR)
GROUP BY issue_type;
```

---

## 🧪 Testing

### Test Slow Query Detection
```sql
-- Create slow query (15 seconds)
SELECT SLEEP(15), 'Test query';

-- Wait 1-2 minutes, then check
SELECT * FROM detected_issues 
WHERE issue_type = 'SLOW_QUERY' 
ORDER BY detected_at DESC LIMIT 1;
```

### Test Long Transaction Detection
```sql
-- Session 1: Start long transaction
START TRANSACTION;
SELECT * FROM test_table WHERE id = 1 FOR UPDATE;
-- Wait 35+ seconds

-- Session 2: Check detection
SELECT * FROM detected_issues 
WHERE issue_type = 'TRANSACTION_FAILURE' 
ORDER BY detected_at DESC LIMIT 1;

-- Session 1: Clean up
ROLLBACK;
```

---

## ⚙️ Configuration

### Thresholds (Edit Procedures)
```sql
-- Slow query: 10 seconds (line ~50 in detect_slow_queries)
WHERE TIME > 10

-- Connection overload: 150 connections (line ~30 in detect_connection_overload)
IF v_connection_count > 150

-- Long transaction: 30 seconds (line ~40 in detect_long_transactions)
WHERE TIMESTAMPDIFF(SECOND, trx_started, NOW()) > 30

-- Duplicate window: 5 minutes (in all procedures)
AND last_detected_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
```

### Event Frequency
```sql
-- Change to 30 seconds
ALTER EVENT auto_detect_issues ON SCHEDULE EVERY 30 SECOND;

-- Change to 2 minutes
ALTER EVENT auto_detect_issues ON SCHEDULE EVERY 2 MINUTE;

-- Change to 5 minutes
ALTER EVENT auto_detect_issues ON SCHEDULE EVERY 5 MINUTE;
```

---

## 🔍 Monitoring

### Detection Activity
```sql
-- Detections per minute (last hour)
SELECT 
    DATE_FORMAT(detected_at, '%H:%i') as minute,
    COUNT(*) as detections
FROM detected_issues
WHERE detected_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY minute
ORDER BY minute DESC;

-- Detection cache status
SELECT COUNT(*) as cached_issues FROM issue_detection_cache;

-- Full workflow status
SELECT 
    di.issue_type,
    dl.decision_type,
    ha.execution_status,
    COUNT(*) as count
FROM detected_issues di
JOIN decision_log dl ON di.issue_id = dl.issue_id
LEFT JOIN healing_actions ha ON dl.decision_id = ha.decision_id
WHERE di.detected_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY di.issue_type, dl.decision_type, ha.execution_status;
```

---

## 🛠️ Troubleshooting

### Problem: No Detections
```sql
-- 1. Check event scheduler
SELECT @@event_scheduler;  -- Should be ON

-- 2. Check event status
SHOW EVENTS WHERE Name = 'auto_detect_issues';  -- Should be ENABLED

-- 3. Run manually
CALL run_automatic_detection();

-- 4. Check for slow queries
SELECT * FROM information_schema.processlist WHERE TIME > 10;
```

### Problem: Too Many Detections
```sql
-- Increase cooldown window (edit procedures)
-- Change: INTERVAL 5 MINUTE → INTERVAL 10 MINUTE

-- Or reduce event frequency
ALTER EVENT auto_detect_issues ON SCHEDULE EVERY 2 MINUTE;
```

### Problem: Event Not Running
```sql
-- Enable event scheduler
SET GLOBAL event_scheduler = ON;

-- Enable event
ALTER EVENT auto_detect_issues ENABLE;

-- Check MySQL error log for issues
```

---

## 📋 What Gets Detected

| Issue Type | Trigger | Threshold | Source |
|------------|---------|-----------|--------|
| SLOW_QUERY | Long-running query | > 10 sec | processlist |
| CONNECTION_OVERLOAD | Too many connections | > 150 | global_status |
| TRANSACTION_FAILURE | Long transaction | > 30 sec | innodb_trx |

---

## 🎯 Expected Behavior

### Normal Operation
- Event runs every 1 minute
- Checks for issues in system tables
- Inserts into `detected_issues` if found
- Existing triggers handle workflow
- Cache prevents duplicates

### After Detection
```
detected_issues (automatic insert)
    ↓
decision_log (trigger)
    ↓
healing_actions/admin_reviews (trigger)
    ↓
learning_history (trigger)
```

---

## 💡 Pro Tips

1. **Start with default thresholds**, tune later based on your workload
2. **Monitor for first 24 hours** to understand detection patterns
3. **Adjust cooldown window** if seeing too many duplicates
4. **Use manual testing** before relying on automatic detection
5. **Keep event frequency at 1 minute** unless performance issues

---

## 🔗 Related Files

- `automatic_detection_system.sql` - Full implementation
- `AUTOMATIC_DETECTION_GUIDE.md` - Detailed documentation
- `schema_refactored.sql` - Original database schema

---

## ✅ Verification Checklist

- [ ] Event scheduler enabled (`@@event_scheduler = ON`)
- [ ] Event created and enabled (`SHOW EVENTS`)
- [ ] Procedures created (`SHOW PROCEDURE STATUS`)
- [ ] Cache table created (`SHOW TABLES LIKE 'issue_detection_cache'`)
- [ ] Test detection works (`SELECT SLEEP(15)`)
- [ ] Workflow triggered automatically
- [ ] No duplicate detections within 5 minutes

---

**Quick Reference v1.0 - Ready for Production** ✨
