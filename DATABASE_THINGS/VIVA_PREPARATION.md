---
title: "Viva Exam Preparation: Key Architectural Decisions"
subtitle: "Be Ready for Any Question"
---

# Viva Preparation: Architectural Decisions FAQ

## The Core Philosophy

**Your one-liner:**
> "This schema separates detection, analysis, decision, execution, and learning into distinct tables, enforced by foreign keys. AI can recommend but cannot execute. Humans must approve every decision. ML learns from outcomes but never bypasses admin control."

---

## Expected Viva Questions & Answers

### Q1: "Why 8 tables? Why not merge some?"

**The Question:** Why not combine `ai_analysis` and `recovery_decisions`? Or `admin_approvals` and `action_executions`?

**Why It's Asked:** Examiner wants to know you understand separation of concerns, not just that it sounds good.

**Your Answer:**

"Separating these tables enforces a critical safety boundary:

- **Analysis + Decision merged:** AI could recommend AND make decisions without human review. No approval checkpoint.
- **Approval + Execution merged:** No way to distinguish "human approved this" from "system executed this." Audit trail loses clarity.

Each table represents a **workflow stage** where decision can be made:
- Analysis (AI): Keep? Ignore? Suggests confidence level.
- Decision (AI): Which action? Recommends, not orders.
- Approval (Human): Allow? Reject? Conditional? This is where humans inject judgment.
- Execution (System): Did it work? Record outcome.

Merging tables removes decision points. Foreign keys enforce that no stage skips previous stages."

**Back this up with:**
```sql
-- Cannot do this (FK violation):
INSERT INTO action_executions (approval_id, ...)
VALUES (NULL, ...);
-- ERROR: Foreign key constraint fails

-- Cannot do this (PK constraint):
SELECT * FROM action_executions 
WHERE approval_id NOT IN (SELECT approval_id FROM admin_approvals);
-- Result: 0 rows (good)
```

---

### Q2: "How does your schema prevent AI from executing actions directly?"

**The Question:** What stops an AI system from creating action_executions rows without human approval?

**Why It's Asked:** This is the CORE safety requirement. Examiner will grill you on this.

**Your Answer:**

"The schema makes it cryptographically impossible:

```sql
-- Attempt 1: Direct execution without approval
INSERT INTO action_executions (
    approval_id, action_id, execution_status, ...
) VALUES (
    NULL, 5, 'COMPLETED', ...
);
-- ERROR: Field 'approval_id' doesn't have a default value
-- (approval_id is NOT NULL, mandatory)

-- Attempt 2: Use non-existent approval
INSERT INTO action_executions (
    approval_id, action_id, ...
) VALUES (
    9999, 5, ...
);
-- ERROR 1452: Cannot add or update a child row: 
--  a foreign key constraint fails 
--  (`self_healing_dbms`.`action_executions`, 
--   CONSTRAINT `action_executions_ibfk_1` 
--   FOREIGN KEY (`approval_id`) REFERENCES `admin_approvals` 
--   (`approval_id`))
```

This is **database-level enforcement**, not application-level. No amount of code manipulation can bypass it without modifying MySQL itself.

Every action_executions row **requires** a corresponding admin_approvals row. The only way to create that is through human interaction (admin_approvals.approval_status = 'APPROVED')."

---

### Q3: "What prevents an admin from approving a dangerous action?"

**The Question:** If admins have approval authority, can't they destroy the system?

**Why It's Asked:** Examiner wants to know you understand organizational controls vs. schema controls.

**Your Answer:**

"The schema does **not** prevent this—organizational controls do. However, the schema **enables detection**:

**Whitelist of Predefined Actions:**
```sql
SELECT * FROM predefined_actions 
WHERE action_enabled = TRUE;
-- Only ~10-20 safe actions exist
-- Dangerous actions (DROP TABLE, TRUNCATE, etc.) 
-- are never in this list
```

If admin approves 'kill_long_running_query', worst case: transaction terminates (tolerable). The action cannot be arbitrary SQL.

**Rubber-Stamping Detection:**
```sql
-- Red flag query
SELECT admin_user_id, 
       COUNT(*) as approvals,
       SUM(CASE WHEN approval_status = 'DECLINED' THEN 1 ELSE 0 END) as declines
FROM admin_approvals
WHERE approval_timestamp > DATE_SUB(NOW(), INTERVAL 7 DAY)
GROUP BY admin_user_id
HAVING approvals > 100 OR declines = 0;
-- Reveals if admin is rubber-stamping
```

**Risk Level Annotation:**
```sql
SELECT pa.action_name, pa.risk_level, COUNT(*) 
FROM admin_approvals ap
JOIN recovery_decisions rd ON ap.decision_id = rd.decision_id
JOIN predefined_actions pa ON rd.recommended_action_id = pa.action_id
WHERE ap.approval_timestamp > DATE_SUB(NOW(), INTERVAL 30 DAY)
  AND pa.risk_level = 'HIGH'
GROUP BY pa.action_name;
-- Admins know they're approving HIGH-risk actions
```

**Conclusion:** Schema prevents arbitrary dangers and makes it auditable. Human integrity is required for the approval layer—that's organizational governance, not database design."

---

### Q4: "Why use DECIMAL(3,2) for confidence instead of FLOAT?"

**The Question:** What's wrong with just using a FLOAT?

**Why It's Asked:** Examiner wants precision in reasoning about data types.

**Your Answer:**

"FLOAT uses IEEE 754 binary representation, which has precision issues:

```sql
-- FLOAT example (bad for audit logs):
SELECT CAST(0.95 AS FLOAT) = 0.95;
-- Result: FALSE (in many systems)
-- Reason: 0.95 cannot be exactly represented in binary

SELECT CAST(0.95 AS FLOAT);
-- Result: 0.9499999... (not exactly 0.95)
```

This breaks:
1. **Auditing:** 'Confidence was 0.95' != actual stored value
2. **Constraints:** `WHERE confidence >= 0.80` might miss or include wrong rows
3. **Calibration:** ML feedback 'AI was 0.95 confident' doesn't match database

**DECIMAL(3, 2) solves this:**
```sql
SELECT CAST(0.95 AS DECIMAL(3, 2)) = 0.95;
-- Result: TRUE (always)

SELECT CAST(0.95 AS DECIMAL(3, 2));
-- Result: 0.95 (exactly)
```

This works because:
- DECIMAL stores as exact decimal digits, not binary approximation
- Range: 0.00 to 9.99 (so DECIMAL(3,2) is sufficient for 0.00-1.00)
- Standard for financial/audit data (which confidence calibration is)

**Size:** DECIMAL(3,2) uses 2 bytes vs. FLOAT 4 bytes. Negligible difference; correctness matters more."

---

### Q5: "How does ML learn from learning_records without controlling execution?"

**The Question:** Explain the learning loop. How is it safe?

**Why It's Asked:** This is the innovative part. Examiner wants to understand the ML boundary.

**Your Answer:**

"The key is **directional dependency**:

```
Execution Results → learning_records → ML Model Training
                                            ↓
                                    Improved Confidence
                                            ↓
                                    ai_analysis (higher confidence)
                                            ↓
                                    recovery_decisions (better recommendation)
                                            ↓
                                    admin_approvals (admin still approves)
                                            ↓
                                    action_executions (execution)

But: ML cannot write anywhere except logs.
     ML cannot read admin_approvals and modify recovery_decisions.
     ML cannot create action_executions directly.
```

**Schema enforcement:**

```sql
-- learning_records table (for ML)
CREATE TABLE learning_records (
    learning_record_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    issue_id BIGINT UNSIGNED NOT NULL,
    execution_id BIGINT UNSIGNED,  -- nullable; not all issues execute
    -- ... outcome fields ...
    PRIMARY KEY (learning_record_id),
    FOREIGN KEY (issue_id) REFERENCES detected_issues(issue_id),
    FOREIGN KEY (execution_id) REFERENCES action_executions(execution_id)
    -- NOTE: No FK back to recovery_decisions or admin_approvals
);
```

**What this means:**
- ML can read: learning_records, detected_issues, action_executions
- ML can write: Nothing (external ML system, no DB write permission)
- ML output: Improved model weights (external file or model registry)
- Next cycle: Better confidence scores in ai_analysis (created by AI system, not ML)

**Example workflow:**

```
Day 1:
  issue_id=1 → confidence=0.80 → approved → success → learning_record with confidence_accuracy=0.80

Day 2:
  ML model retrains on learning_records → confidence calibration improves

Day 8 (similar issue):
  issue_id=42 → AI system uses improved model → confidence=0.85 → admin approves

Day 9:
  Action succeeds → learning_record with confidence_accuracy=0.85
```

**Safety guarantee:**
- ML never creates recovery_decisions
- ML never creates admin_approvals
- ML never creates action_executions
- ML can only suggest (via improved confidence), not command (no write to execution tables)"

---

### Q6: "What if an admin reviews an approval hours after deciding?"

**The Question:** How do you prevent approval and execution happening at different times, leading to stale decisions?

**Why It's Asked:** Temporal consistency is important for safety.

**Your Answer:**

"Good question. The schema doesn't prevent this—it's a **workflow enforcement issue**, not schema issue.

However, the schema enables detection:

```sql
-- Find stale approvals
SELECT a.approval_id, a.approval_timestamp,
       e.execution_timestamp,
       TIMESTAMPDIFF(MINUTE, a.approval_timestamp, e.execution_timestamp) as minutes_delayed
FROM admin_approvals a
JOIN action_executions e ON a.approval_id = e.approval_id
WHERE TIMESTAMPDIFF(MINUTE, a.approval_timestamp, e.execution_timestamp) > 60;
-- Shows approvals executed much later
```

**Design recommendation (for Phase 2, Step 2):**

Add approval expiration:
```sql
ALTER TABLE recovery_decisions ADD COLUMN (
    approval_timeout_minutes INT DEFAULT 30,
    CONSTRAINT chk_timeout CHECK (approval_timeout_minutes > 0)
);

-- Before execution, check:
SELECT * FROM admin_approvals a
JOIN recovery_decisions rd ON a.decision_id = rd.decision_id
WHERE a.approval_timestamp < DATE_SUB(NOW(), INTERVAL rd.approval_timeout_minutes MINUTE)
  AND a.approval_status = 'APPROVED'
  AND NOT EXISTS (
      SELECT 1 FROM action_executions e WHERE e.approval_id = a.approval_id
  );
-- Approvals that expired without execution
```

**For now:** This is an operational constraint (approval system should execute immediately), not enforced by schema. Auditable via timestamps if needed."

---

### Q7: "Why JSON for raw_context and post_execution_metrics?"

**The Question:** Why not normalize these into separate tables?

**Why It's Asked:** Examiner wants to know when to denormalize.

**Your Answer:**

"Good normalization question. Let's weigh options:

**Option A: Normalize (separate tables for each metric type)**
```sql
CREATE TABLE detection_event_metrics (
    metric_id, event_id, metric_name, metric_value, FOREIGN KEY (event_id)...
);
-- Every metric type becomes a separate row
-- Queries: lots of self-joins to get full context
```

**Pros:**
- Strictly normalized (3NF)
- Easy to query individual metrics
- Supports variable metric counts

**Cons:**
- Detection_events has 1:N relationship with metrics
- Every query for "what was detected" needs JOIN
- Bloats detection_events concept

**Option B: JSON (denormalized)**
```sql
INSERT INTO detection_events (raw_context) 
VALUES (JSON_OBJECT('query', 'SELECT...', 'thread_id', 123, 'lock_info', {...}));

SELECT raw_context->'$.query' FROM detection_events;
```

**Pros:**
- One row per event (conceptually correct)
- No joins needed to see full context
- Flexible schema (different events have different contexts)
- MySQL 5.7+ supports JSON

**Cons:**
- Not fully normalized
- Requires JSON extraction functions to query specific fields
- Less relational

**Decision:** Use JSON because:
1. Detection events are **read-heavy** (admin reviews them, not constantly queried)
2. Variable schema per event type (PERFORMANCE_SCHEMA vs. DEADLOCK logs have different structures)
3. Raw context is **archival**; rarely filtered on individual metrics
4. Avoids explosion of 1:N relationships

**Compromise:** Add indexes on frequently-queried fields:
```sql
ALTER TABLE detection_events 
ADD KEY idx_source_resource (detection_source, target_resource_type);
```

**For post_execution_metrics:** Same reasoning. Schema flexibility (different actions produce different metrics)."

---

### Q8: "What if the same issue never resolves, despite multiple actions?"

**The Question:** How do you handle persistent problems?

**Why It's Asked:** Examiner wants to see edge cases handled.

**Your Answer:**

"The schema tracks this automatically:

```sql
-- Find issues with low success rate despite multiple attempts
SELECT i.issue_id, i.affected_resource_name, 
       COUNT(DISTINCT e.execution_id) as attempts,
       SUM(CASE WHEN l.issue_resolved_flag THEN 1 ELSE 0 END) as successes,
       ROUND(100.0 * SUM(CASE WHEN l.issue_resolved_flag THEN 1 ELSE 0 END) 
             / COUNT(DISTINCT e.execution_id), 2) as success_rate
FROM detected_issues i
LEFT JOIN action_executions e ON e.approval_id IN 
    (SELECT ap.approval_id FROM admin_approvals ap 
     WHERE ap.decision_id IN (
        SELECT rd.decision_id FROM recovery_decisions rd 
        WHERE rd.analysis_id IN (
            SELECT a.analysis_id FROM ai_analysis a WHERE a.issue_id = i.issue_id
        )
     ))
LEFT JOIN learning_records l ON l.execution_id = e.execution_id
WHERE i.issue_status != 'RESOLVED'
GROUP BY i.issue_id
HAVING attempts >= 3 AND success_rate < 50%;
-- Issues that failed 50%+ of the time after 3+ attempts
```

**What this reveals:**
- Root cause not understood (multiple actions tried)
- Predefined actions insufficient for this problem
- Needs human expert review

**Next step (not in schema, but in operations):**
- Mark issue as ESCALATED_TO_HUMAN
- Notify DBA team: "Issue #42 (table fragmentation) failed 4 times. Needs manual diagnosis."
- Update learning_records: `would_approve_again = FALSE`

**Schema contribution:**
- Records every attempt
- Calculates success rate
- Learning loop identifies ineffective actions
- Admins can see patterns (if action X never works, stop recommending it)"

---

### Q9: "Can an admin approve an action, then undo the approval?"

**The Question:** What's the approval workflow once a decision is approved?

**Why It's Asked:** Immutability and audit trail integrity.

**Your Answer:**

"Short answer: **Approved approvals cannot be undone in this schema.**

**Here's why:**

```sql
-- Once admin_approvals.approval_status = 'APPROVED', it's immutable
UPDATE admin_approvals 
SET approval_status = 'DECLINED'
WHERE approval_id = 5;
-- This UPDATE is allowed by the schema (no constraint prevents it)
-- BUT it violates audit integrity
```

**Design recommendation (Phase 2, Step 2):**

Add immutability constraint:
```sql
ALTER TABLE admin_approvals ADD COLUMN (
    approval_finalized BOOLEAN DEFAULT FALSE,
    CONSTRAINT chk_no_update_after_approval 
    CHECK (approval_finalized = FALSE)
);

-- Once set to TRUE, prevents updates:
UPDATE admin_approvals 
SET approval_finalized = TRUE
WHERE approval_id = 5;
-- Now if someone tries to change approval_status:
UPDATE admin_approvals 
SET approval_status = 'DECLINED'
WHERE approval_id = 5;
-- ERROR: CHECK constraint fails
```

**Alternative pattern (for now):**

Use application-level enforcement:
```sql
-- Before execution, query to verify approval hasn't changed:
SELECT COUNT(*) FROM admin_approvals 
WHERE approval_id = 1 
  AND approval_status = 'APPROVED'
  AND approval_timestamp > '2026-01-30 10:00:00';
-- If count = 0, approval was withdrawn (execute action cancelled)
```

**Best practice:**
- Use timestamps to detect changes: If execution_timestamp > approval_timestamp + X minutes, reject execution
- Audit logs show if approval was ever modified
- Operational policy: Once approved, cannot revoke (unless emergency stop)"

---

### Q10: "How do you prevent data loss if MySQL crashes during execution?"

**The Question:** What about crash recovery? Transaction safety?

**Why It's Asked:** DBMS reliability is fundamental.

**Your Answer:**

"InnoDB provides crash recovery automatically. Schema design supports this:

**Transaction Safety:**

```sql
-- All writes use InnoDB transactions
START TRANSACTION;
  INSERT INTO action_executions (...) VALUES (...);  -- record starting
  -- Execute the recovery action (e.g., ANALYZE TABLE)
  ANALYZE TABLE users;
  UPDATE action_executions 
  SET execution_status = 'COMPLETED', execution_outcome = 'SUCCESS' 
  WHERE execution_id = LAST_INSERT_ID();
COMMIT;  -- All or nothing
```

If MySQL crashes:
- Either all inserts/updates committed (complete record)
- Or none (rollback, no partial record)

**No partial execution log (good).**

**InnoDB Features:**
- Redo logs: Recover committed transactions
- Undo logs: Rollback uncommitted transactions
- Doublewrite buffer: Prevent partial page writes

**Schema contribution:**
- Use BIGINT UNSIGNED (64-bit, no overflow)
- Use InnoDB only (MyISAM has no crash recovery)
- Foreign keys enforce consistency (no orphaned records)
- Timestamps use server-side CURRENT_TIMESTAMP(6) (crash-safe)

**For Phase 2, Step 2:**

Consider adding:
```sql
ALTER TABLE action_executions ADD COLUMN (
    execution_txn_id BIGINT UNSIGNED,  -- MySQL transaction ID
    execution_binlog_pos VARCHAR(100)  -- Binlog file:offset for recovery
);
```

**Answer for viva:** "InnoDB provides crash recovery automatically. The schema uses FOREIGN KEY constraints and proper data types to ensure referential integrity. Timestamps are server-side, not app-side (crash-safe). Every table is InnoDB; no MyISAM (no crash recovery)."

---

## Rapid-Fire Questions (30-Second Answers)

### "Where does the raw MySQL detection come from?"

**Answer:** `detection_events.raw_context` captures performance schema queries, slow query log entries, and InnoDB deadlock info. All immutable, append-only.

---

### "What's the most critical foreign key?"

**Answer:** `action_executions.approval_id → admin_approvals` (NOT NULL). Without approval, execution is impossible.

---

### "How many admins can approve the same decision?"

**Answer:** One record per decision (1:1 relationship). But you could modify schema to allow multiple approvals (approval_count INT, multiple admin_approvals rows). Depends on organizational policy.

---

### "What if AI confidence is always 0.99?"

**Answer:** Check `learning_records.confidence_accuracy`. If confidence_accuracy < 0.80, AI is overconfident. Admins learn to distrust high scores. ML retrains to calibrate better.

---

### "Can you query 'which actions work best'?"

**Answer:** Yes. Join learning_records → action_executions → predefined_actions. Group by action_name, count successes. Already wrote the query in design doc.

---

### "What prevents insertion of invalid JSON?"

**Answer:** Application validation (not schema-enforced). But you could add: `CHECK (JSON_VALID(raw_context))` in MySQL 5.7.8+.

---

### "How do you handle actions that timeout?"

**Answer:** `actual_duration_seconds` exceeds estimated. Log in `execution_errors`. Learning_records assess: success despite timeout, or failed?

---

### "What if an index creation fails during execution?"

**Answer:** `execution_outcome = 'FAILED'`, `execution_errors` contains MySQL error message. Learning_records: `issue_resolved_flag = FALSE`. Next recommendation might try different action.

---

## Your Viva Cheat Sheet (Print & Memorize)

**Table Purposes (8 tables):**
1. `detection_events` — DBMS mechanisms only; immutable log
2. `detected_issues` — Categorized problems; mutable status
3. `ai_analysis` — AI confidence; recommendations only
4. `predefined_actions` — Safety whitelist; master data
5. `recovery_decisions` — AI suggestions awaiting approval
6. `admin_approvals` — MANDATORY human checkpoint
7. `action_executions` — What was executed and why
8. `learning_records` — ML training data (never executes)

**Safety Barriers (Memorize These):**
- AI cannot execute: FK enforcement (approval_id → admin_approvals)
- Arbitrary SQL blocked: FK enforcement (action_id → predefined_actions)
- ML doesn't control: learning_records is read-only to ML
- Audit trail immutable: InnoDB transactions, server-side timestamps

**Confidence Scoring:**
- DECIMAL(3, 2) not FLOAT (precision matters)
- 0.00–1.00 range via CHECK constraint
- Calibrated via confidence_accuracy in learning_records

**Workflow (Cannot Skip Stages):**
```
Detection → Issue → Analysis → Decision → Approval → Execution → Learning
   1         2        3         4         5           6          7
```

**Your closing statement if questioned:**
> "This schema enforces separation of concerns at the database level. Detection is DBMS-only. Analysis is AI-only (informational). Approval is human-mandatory (foreign key NOT NULL). Execution is automated but safe (whitelist of actions). Learning is from outcomes (no write access). Foreign keys make bypassing these stages cryptographically impossible."

---

**Good luck in your viva! You're ready.**
