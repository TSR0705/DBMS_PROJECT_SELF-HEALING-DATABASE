---
title: "Phase 2, Step 1 – Implementation Checklist & Quick Reference"
---

# Quick Reference: Schema Implementation

## File Structure

```
DBMS PROJECT/
├── schema_phase2_step1.sql          ← CREATE TABLE statements (run this first)
├── DESIGN_DOCUMENT.md               ← Full architectural reasoning
└── IMPLEMENTATION_CHECKLIST.md      ← This file
```

---

## How to Use the Schema

### 1. Create the Database

```bash
mysql -u root -p < schema_phase2_step1.sql
```

Or in MySQL CLI:

```sql
USE self_healing_dbms;
SHOW TABLES;
-- Result: 8 tables + audit_log (optional)
```

### 2. Populate Master Data: `predefined_actions`

```sql
INSERT INTO predefined_actions (
    action_name, action_category, description, execution_query,
    applicable_issue_categories, risk_level, estimated_duration_seconds, estimated_impact
) VALUES
(
    'analyze_table_statistics',
    'STATISTICS_UPDATE',
    'Updates table statistics for query optimizer',
    'ANALYZE TABLE :table_name;',
    JSON_ARRAY('QUERY_PERFORMANCE', 'INDEX_INEFFICIENCY'),
    'LOW',
    10,
    'Improved query plan selection'
),
(
    'add_missing_index',
    'INDEX_OPTIMIZATION',
    'Creates index on frequently-scanned column',
    'ALTER TABLE :table_name ADD INDEX idx_:col_name (:col_name);',
    JSON_ARRAY('QUERY_PERFORMANCE'),
    'MEDIUM',
    60,
    'Reduced full table scans'
),
(
    'kill_long_running_query',
    'LOCK_MANAGEMENT',
    'Terminates blocking query',
    'KILL QUERY :thread_id;',
    JSON_ARRAY('LOCK_CONTENTION', 'DEADLOCK'),
    'HIGH',
    1,
    'Unblocks waiting transactions'
);
-- (Add more as needed)
```

### 3. Simulate Detection (From MySQL Mechanisms)

```sql
-- Step 1: Record what DBMS detected
INSERT INTO detection_events (
    detection_source, target_resource_type, target_resource_name,
    metric_name, metric_value, severity_indicator, raw_context
) VALUES
(
    'SLOW_QUERY_LOG',
    'TABLE',
    'users',
    'query_execution_time_ms',
    5432,
    'WARNING',
    JSON_OBJECT('query', 'SELECT * FROM users WHERE status = 1', 'thread_id', 123)
);
-- Result: event_id = 1

-- Step 2: Categorize as an issue
INSERT INTO detected_issues (
    issue_category, affected_resource_type, affected_resource_name,
    description, first_occurrence_event_id, last_detection_event_id, issue_status
) VALUES
(
    'QUERY_PERFORMANCE',
    'TABLE',
    'users',
    'Full table scan on users; WHERE clause not indexed',
    1,
    1,
    'DETECTED'
);
-- Result: issue_id = 1

-- Step 3: AI analyzes
INSERT INTO ai_analysis (
    issue_id, root_cause_hypothesis, confidence_score,
    contributing_factors, recommendation_summary, analysis_status
) VALUES
(
    1,
    'Column status in WHERE clause lacks index; full table scan required',
    0.92,
    JSON_ARRAY('Full table scan count', 'Table size 1M rows', 'Query frequency high'),
    'Creating index on status column should eliminate full scan',
    'RECOMMENDATION_ISSUED'
);
-- Result: analysis_id = 1

-- Step 4: AI recommends action
INSERT INTO recovery_decisions (
    analysis_id, recommended_action_id, confidence_based_score, decision_rationale, decision_status
) VALUES
(
    1,
    2,  /* action_id for 'add_missing_index' */
    0.92,
    'High confidence: lack of index is clearly the bottleneck. Medium risk: index creation will lock table briefly.',
    'PENDING_APPROVAL'
);
-- Result: decision_id = 1

-- Step 5: Admin reviews and approves
INSERT INTO admin_approvals (
    decision_id, admin_user_id, approval_status, approval_reason, admin_notes
) VALUES
(
    1,
    'admin@example.com',
    'APPROVED',
    'CONFIDENT',
    'Medium risk acceptable; off-peak hours. Index creation needed.'
);
-- Result: approval_id = 1

-- Step 6: Action executes
INSERT INTO action_executions (
    approval_id, action_id, execution_status, execution_outcome,
    execution_start_time, execution_end_time, actual_duration_seconds,
    affected_rows, executed_by
) VALUES
(
    1,
    2,
    'COMPLETED',
    'SUCCESS',
    NOW(),
    DATE_ADD(NOW(), INTERVAL 45 SECOND),
    45,
    NULL,  /* No rows affected for DDL */
    'system@automation'
);
-- Result: execution_id = 1

-- Step 7: Learning recorded
INSERT INTO learning_records (
    issue_id, execution_id, issue_resolved_flag,
    time_to_resolution_hours, metric_improvement_percent,
    human_assessment_notes, learning_complete
) VALUES
(
    1,
    1,
    TRUE,
    0.08,  /* 5 minutes from detection to resolution */
    68,    /* Query latency reduced 68% */
    'Index resolved the issue completely. Recommended for similar patterns.',
    TRUE
);
-- Result: learning_record_id = 1
```

---

## Querying the Schema

### Admin Dashboard: Pending Approvals

```sql
SELECT 
    d.decision_id,
    i.affected_resource_name as resource,
    a.confidence_score,
    a.root_cause_hypothesis,
    pa.action_name,
    pa.risk_level,
    d.decision_timestamp
FROM recovery_decisions d
JOIN ai_analysis a ON d.analysis_id = a.analysis_id
JOIN detected_issues i ON a.issue_id = i.issue_id
JOIN predefined_actions pa ON d.recommended_action_id = pa.action_id
WHERE d.decision_status = 'PENDING_APPROVAL'
ORDER BY a.confidence_score DESC;
```

### Audit Trail: What Happened to Issue #1?

```sql
SELECT 
    'Detection' as step,
    event_timestamp,
    detection_source,
    metric_value,
    severity_indicator
FROM detection_events
WHERE event_id = (SELECT first_occurrence_event_id FROM detected_issues WHERE issue_id = 1)

UNION ALL

SELECT 
    'Issue Categorized',
    issue_created_at,
    issue_category,
    NULL,
    NULL
FROM detected_issues
WHERE issue_id = 1

UNION ALL

SELECT 
    'AI Analyzed',
    analysis_timestamp,
    CONCAT('Confidence: ', confidence_score),
    NULL,
    NULL
FROM ai_analysis
WHERE issue_id = 1

UNION ALL

SELECT 
    'Decision Made',
    decision_timestamp,
    decision_status,
    NULL,
    NULL
FROM recovery_decisions
WHERE analysis_id = (SELECT analysis_id FROM ai_analysis WHERE issue_id = 1)

UNION ALL

SELECT 
    'Admin Approved',
    approval_timestamp,
    CONCAT(approval_status, ' by ', admin_user_id),
    NULL,
    NULL
FROM admin_approvals
WHERE decision_id = (SELECT decision_id FROM recovery_decisions WHERE analysis_id = (SELECT analysis_id FROM ai_analysis WHERE issue_id = 1))

UNION ALL

SELECT 
    'Action Executed',
    execution_timestamp,
    execution_outcome,
    NULL,
    NULL
FROM action_executions
WHERE approval_id = (SELECT approval_id FROM admin_approvals WHERE decision_id = (SELECT decision_id FROM recovery_decisions WHERE analysis_id = (SELECT analysis_id FROM ai_analysis WHERE issue_id = 1)))

ORDER BY step;
```

### Learning Effectiveness: Which Actions Work Best?

```sql
SELECT 
    pa.action_name,
    COUNT(DISTINCT l.learning_record_id) as total_uses,
    SUM(CASE WHEN l.issue_resolved_flag THEN 1 ELSE 0 END) as successful,
    ROUND(100.0 * SUM(CASE WHEN l.issue_resolved_flag THEN 1 ELSE 0 END) / COUNT(*), 2) as success_rate,
    ROUND(AVG(l.metric_improvement_percent), 2) as avg_improvement,
    ROUND(AVG(a.confidence_score), 2) as avg_ai_confidence
FROM learning_records l
JOIN action_executions ae ON l.execution_id = ae.execution_id
JOIN predefined_actions pa ON ae.action_id = pa.action_id
JOIN admin_approvals ap ON ae.approval_id = ap.approval_id
JOIN recovery_decisions rd ON ap.decision_id = rd.decision_id
JOIN ai_analysis a ON rd.analysis_id = a.analysis_id
WHERE l.learning_complete = TRUE
GROUP BY pa.action_name
ORDER BY success_rate DESC;
```

### Red Flags: Admin Approval Patterns

```sql
-- Rubber-stamping detection
SELECT 
    admin_user_id,
    DATE(approval_timestamp) as approval_date,
    COUNT(*) as approvals,
    SUM(CASE WHEN approval_status = 'APPROVED' THEN 1 ELSE 0 END) as approved,
    SUM(CASE WHEN approval_status = 'DECLINED' THEN 1 ELSE 0 END) as declined,
    ROUND(100.0 * SUM(CASE WHEN approval_status = 'APPROVED' THEN 1 ELSE 0 END) / COUNT(*), 1) as approval_rate
FROM admin_approvals
GROUP BY admin_user_id, DATE(approval_timestamp)
HAVING approval_rate > 95
ORDER BY approval_rate DESC;
```

---

## Schema Validation Queries

### Verify Foreign Key Integrity

```sql
-- Are there any decisions without analysis?
SELECT COUNT(*) FROM recovery_decisions d
WHERE NOT EXISTS (SELECT 1 FROM ai_analysis a WHERE a.analysis_id = d.analysis_id);
-- Expected: 0

-- Are there any executions without approval?
SELECT COUNT(*) FROM action_executions e
WHERE NOT EXISTS (SELECT 1 FROM admin_approvals ap WHERE ap.approval_id = e.approval_id);
-- Expected: 0

-- Are there any recommended actions that don't exist?
SELECT COUNT(*) FROM recovery_decisions d
WHERE NOT EXISTS (SELECT 1 FROM predefined_actions pa WHERE pa.action_id = d.recommended_action_id);
-- Expected: 0
```

### Verify Confidence Scores Are Valid

```sql
SELECT 
    'ai_analysis' as table_name,
    COUNT(*) as invalid_scores
FROM ai_analysis
WHERE confidence_score < 0.00 OR confidence_score > 1.00

UNION ALL

SELECT 
    'recovery_decisions',
    COUNT(*)
FROM recovery_decisions
WHERE confidence_based_score < 0.00 OR confidence_based_score > 1.00;

-- Expected: 0 rows (all scores valid)
```

---

## Viva Preparation: Key Points to Memorize

### 1. Table Purposes (Elevator Pitch)

| Table | Purpose |
|-------|---------|
| `detection_events` | "Raw signals from MySQL: what DBMS detected, when, where." |
| `detected_issues` | "Categorized problems; aggregates multiple events." |
| `ai_analysis` | "AI's interpretation and confidence score (informational only)." |
| `predefined_actions` | "Whitelist of safe actions; prevents arbitrary SQL execution." |
| `recovery_decisions` | "AI recommendation (not an order); awaits approval." |
| `admin_approvals` | "Human review checkpoint; no execution without approval." |
| `action_executions` | "What was actually executed and what happened." |
| `learning_records` | "Historical outcomes; ML learns from this (never executes)." |

### 2. Separation of Concerns

```
Detection (DBMS) ≠ Analysis (AI) ≠ Decision (Human+AI) ≠ Execution (Automation) ≠ Learning (ML)
```

**Key point:** Each stage can only proceed if previous stage completed successfully. No shortcuts.

### 3. Safety Guarantees

- **AI cannot execute:** FK constraint `action_executions.approval_id → admin_approvals`
- **Only predefined actions allowed:** FK constraint `recovery_decisions.action_id → predefined_actions`
- **ML cannot bypass approval:** learning_records have no write permission to recovery_decisions
- **Audit trail immutable:** InnoDB transactions, server-side timestamps

### 4. Confidence Scoring

- **0.00–1.00 range:** DECIMAL(3, 2) for precision (not FLOAT)
- **Used for:** Admin prioritization, decision approval likelihood, model calibration
- **Validated in learning:** `ai_confidence_accuracy` shows if AI's confidence matched outcome

### 5. If Examiner Challenges You...

**"Why not just use 3 tables and a JSON column?"**
→ "Violates separation of concerns; AI analysis mixed with decisions = safety risk."

**"Why not let ML execute directly?"**
→ "learning_records are read-only for ML. Execution always requires human approval via admin_approvals."

**"Why DECIMAL instead of FLOAT for confidence?"**
→ "Precision: 0.95 must equal 0.95 exactly. FLOAT has rounding errors; unsuitable for audit logs."

**"How do you prevent a rogue admin from approving dangerous actions?"**
→ "Whitelist in predefined_actions (only safe actions exist). approval_reason field enables auditing. Human integrity required; schema enables detection of rubber-stamping."

---

## Next Steps (Phase 2, Step 2)

After this schema is approved:
1. Design stored procedures for safe action execution
2. Design views for admin dashboards
3. Create backup/recovery mechanisms
4. Design ML model training pipeline (ingests learning_records, updates recommendation confidence)

---

**Ready for Viva!**

Print this document. Review the schema diagram. Practice explaining each table in <1 minute.

Good luck!
