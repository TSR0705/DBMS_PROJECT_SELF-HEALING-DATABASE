---
title: "AI-Assisted Self-Healing DBMS: Phase 2, Step 1 Schema Design"
author: "DBMS Technical Lead"
date: "2026-01-30"
phase: "2"
step: "1"
---

# Schema Design Document: Phase 2, Step 1

## Executive Summary

This document details the normalized MySQL schema for an AI-assisted self-healing DBMS system that enforces:
- **Strict separation of concerns** (Detection → Analysis → Decision → Execution → Learning)
- **Mandatory human approval** before any risky action
- **Predefined action whitelist** (no arbitrary SQL execution)
- **AI recommendations only** (AI never controls execution)
- **ML learning from outcomes** (never bypasses admin control)

The schema is designed for **auditability, academic rigor, and viva readiness**.

---

## Core Design Principle: Separation of Concerns

```
┌─────────────────────────────────────────────────────────────┐
│ DETECTION (MySQL DBMS mechanisms)                           │
│ - Performance Schema                                         │
│ - Slow Query Logs                                           │
│ - InnoDB Deadlock Detection                                 │
│                    ↓                                         │
│ ANALYSIS (AI/ML interpretation)                             │
│ - Issue categorization                                      │
│ - Root cause hypothesis                                     │
│ - Confidence scoring (0.00-1.00)                            │
│                    ↓                                         │
│ DECISION (AI recommendation + Human oversight)              │
│ - Recovery decision created                                 │
│ - Awaits admin approval (PENDING_APPROVAL state)            │
│                    ↓                                         │
│ EXECUTION (Safe, predefined actions only)                  │
│ - Admin approves (admin_approvals record created)           │
│ - Action executed (action_executions record created)        │
│ - Outcome recorded (COMPLETED/FAILED status)                │
│                    ↓                                         │
│ LEARNING (ML model improvement)                             │
│ - Outcomes analyzed (learning_records)                      │
│ - Effectiveness assessed                                    │
│ - Model improved (but cannot execute)                       │
└─────────────────────────────────────────────────────────────┘
```

**Why this matters:**
- At every stage, there is a clear hand-off boundary
- No stage can skip to later stages (e.g., AI cannot jump to execution)
- Human approval is an irreplaceable checkpoint
- Audit trail shows exactly what happened and why

---

## Table Design Rationale

### 1. `detection_events` — The DBMS Detection Log

**Purpose:** Immutable, append-only log of what MySQL's built-in mechanisms detected.

**Key Design Decisions:**

| Field | Type | Rationale |
|-------|------|-----------|
| `event_id` | BIGINT UNSIGNED AUTO_INCREMENT | Immutable sequence for event ordering |
| `event_timestamp` | TIMESTAMP(6) | Microsecond precision for temporal analysis |
| `detection_source` | ENUM (PERFORMANCE_SCHEMA \| SLOW_QUERY_LOG \| INNODB_DEADLOCK) | Only these DBMS mechanisms allowed; no application-level detection |
| `severity_indicator` | ENUM (INFO \| WARNING \| CRITICAL) | Severity from DBMS, not AI-assigned |
| `raw_context` | JSON | Query text, thread ID, lock info, etc. (preserved as-is) |

**Constraints:**
- No foreign keys outbound (master data)
- No UPDATE or DELETE (append-only)
- CHECK: `metric_value >= 0`

**Why immutable?**
- Allows replaying events if AI needs re-analysis
- Prevents tampering with audit trail
- Enables temporal debugging ("what changed between time T1 and T2?")

**What this table does NOT do:**
- Does not interpret events (that's AI's job)
- Does not determine severity beyond what DBMS signals
- Does not make decisions (that comes later)

---

### 2. `detected_issues` — Categorized Problem Definitions

**Purpose:** Groups related detection events into actionable DBMS issues.

**Key Design Decisions:**

| Field | Type | Rationale |
|-------|------|-----------|
| `issue_id` | BIGINT UNSIGNED | Unique identifier for the problem |
| `issue_category` | ENUM | Predefined DBMS problem types (QUERY_PERFORMANCE, LOCK_CONTENTION, DEADLOCK, etc.) |
| `occurrence_count` | INT UNSIGNED | Aggregate count avoids expensive GROUP BY queries |
| `issue_status` | ENUM | Tracks progression: DETECTED → ANALYZING → DECISION_MADE → APPROVED → EXECUTING → RESOLVED |
| `first_occurrence_event_id`, `last_detection_event_id` | BIGINT UNSIGNED FK | Links to source events |

**Constraints:**
- Foreign keys to `detection_events` (immutable source)
- `issue_status` drives workflow (no AI can change this without going through proper stages)

**Why separate from events?**
- A single event might be noise; multiple events indicate a pattern
- Multiple events of the same type form one issue
- Issues are **mutable** (status changes); events are **immutable** (read-only)
- Allows cleanup: resolve old issues without touching detection_events

---

### 3. `ai_analysis` — AI Interpretation & Confidence Scoring

**Purpose:** AI's assessment of an issue; recommendations for recovery.

**Key Design Decisions:**

| Field | Type | Rationale |
|-------|------|-----------|
| `analysis_id` | BIGINT UNSIGNED | Multiple analyses per issue allowed (re-analysis with new data) |
| `root_cause_hypothesis` | VARCHAR(500) | AI's best guess (may be wrong; confidence field indicates certainty) |
| `confidence_score` | DECIMAL(3, 2) | 0.00–1.00; informs human review (high confidence = faster approval) |
| `recommendation_summary` | TEXT | Suggests which actions might help (informational only) |
| `historical_similarity_score` | DECIMAL(3, 2) | How similar to past issues (feeds learning loop) |
| `analysis_status` | ENUM | Tracks if recommendation was acted on |

**Constraints:**
- CHECK: `confidence_score BETWEEN 0.00 AND 1.00`
- No outbound control; only informational

**Why AI cannot skip ahead:**
- `analysis_status` shows whether this analysis led to a decision
- If analysis is ignored, AI learns why (human reasoning in admin_approvals.approval_reason)
- AI provides **recommendations**, not **orders**

**What confidence_score influences:**
- Admin prioritization (review highest-confidence first)
- Decision approval likelihood (admins trust high-confidence recommendations more)
- Learning feedback (if AI was wrong despite high confidence, model is poorly calibrated)

---

### 4. `predefined_actions` — The Safety Whitelist

**Purpose:** Catalog of approved recovery actions; only these can be executed.

**Key Design Decisions:**

| Field | Type | Rationale |
|-------|------|-----------|
| `action_id` | BIGINT UNSIGNED | Unique identifier |
| `action_name` | VARCHAR(100) UNIQUE | Descriptive name (e.g., "add_missing_index_on_fk") |
| `execution_query` | TEXT | SQL with placeholders (e.g., `:table_name`, `:index_name`) |
| `risk_level` | ENUM (LOW \| MEDIUM \| HIGH) | Helps admins assess risk |
| `applicable_issue_categories` | JSON | Which issue types this action addresses |
| `requires_manual_verification` | BOOLEAN | Does admin need to check results? |
| `action_enabled` | BOOLEAN | Can be disabled without deleting |

**Constraints:**
- No programmatic generation of `execution_query`
- Placeholders are validated before substitution
- HIGH-risk actions might require special approval tokens

**Why this matters:**
- **AI can never execute arbitrary SQL.** It can only recommend from this list.
- **No dynamic code generation.** Every action is pre-tested, safe.
- **Admin can audit every action before it's used.** No surprises.

**Example actions:**

```json
{
  "action_name": "analyze_table_statistics",
  "action_category": "STATISTICS_UPDATE",
  "execution_query": "ANALYZE TABLE :table_name;",
  "risk_level": "LOW",
  "estimated_duration_seconds": 10
}

{
  "action_name": "add_index_on_fk",
  "action_category": "INDEX_OPTIMIZATION",
  "execution_query": "ALTER TABLE :table_name ADD INDEX idx_:col_name (:col_name);",
  "risk_level": "MEDIUM",
  "estimated_duration_seconds": 60,
  "requires_manual_verification": true
}

{
  "action_name": "kill_long_running_transaction",
  "action_category": "LOCK_MANAGEMENT",
  "execution_query": "KILL QUERY :thread_id;",
  "risk_level": "HIGH",
  "estimated_duration_seconds": 1,
  "requires_manual_verification": true
}
```

---

### 5. `recovery_decisions` — AI Recommendations Await Approval

**Purpose:** AI recommends a specific action for an issue.

**Key Design Decisions:**

| Field | Type | Rationale |
|-------|------|-----------|
| `decision_id` | BIGINT UNSIGNED | Unique recommendation |
| `analysis_id` | BIGINT UNSIGNED FK | Links to AI analysis |
| `recommended_action_id` | BIGINT UNSIGNED FK | Links to predefined_actions (no arbitrary actions) |
| `decision_status` | ENUM (PENDING_APPROVAL \| APPROVED \| DECLINED \| CANCELLED) | Workflow state; must be APPROVED before execution |

**Constraints:**
- Foreign keys enforce that only defined actions are recommended
- `decision_status` defaults to PENDING_APPROVAL (not auto-approved)

**Why separate from analysis?**
- Analysis (interpreting the issue) ≠ Decision (what to do about it)
- One analysis might lead to multiple possible decisions
- Allows admin to reject one action and request AI recommend another

**Example workflow:**
1. Detection detects slow query
2. AI analyzes (confidence 0.95: "missing index")
3. AI creates decision: "recommend INDEX_OPTIMIZATION action"
4. Admin reviews (status: PENDING_APPROVAL)
5. Admin approves or declines (creates admin_approvals record)
6. If approved, action can execute (creates action_executions record)

---

### 6. `admin_approvals` — The Mandatory Checkpoint

**Purpose:** Human review and approval of AI recommendations.

**Key Design Decisions:**

| Field | Type | Rationale |
|-------|------|-----------|
| `approval_id` | BIGINT UNSIGNED | Each approval is auditable |
| `decision_id` | BIGINT UNSIGNED FK | Links to the decision being reviewed |
| `admin_user_id` | VARCHAR(100) | Who approved? (system user ID, auditable) |
| `approval_status` | ENUM (APPROVED \| DECLINED \| CONDITIONAL_APPROVAL) | Final decision |
| `approval_reason` | ENUM | Why did admin approve? (CONFIDENT, ROUTINE, SKEPTICAL_BUT_APPROVED, SAFETY_CONCERN, etc.) |

**Constraints:**
- Foreign key to recovery_decisions (cannot approve non-existent decision)
- NO automatic approval; always human review

**Why this is non-negotiable:**
- Admins understand organizational context AI doesn't have
- If decision is controversial, approval_reason documents why
- High-risk actions get escalated (approval_status = CONDITIONAL_APPROVAL)
- Learning loop sees which approval_reasons led to success (calibrates future confidence thresholds)

---

### 7. `action_executions` — Immutable Execution Log

**Purpose:** Records actual execution of approved actions and their outcomes.

**Key Design Decisions:**

| Field | Type | Rationale |
|-------|------|-----------|
| `execution_id` | BIGINT UNSIGNED | Each execution is auditable |
| `approval_id` | BIGINT UNSIGNED FK | Links to approval (no execution without approval) |
| `action_id` | BIGINT UNSIGNED FK | Which action was executed? |
| `execution_status` | ENUM (QUEUED \| IN_PROGRESS \| COMPLETED \| FAILED) | Lifecycle tracking |
| `execution_outcome` | ENUM (SUCCESS \| PARTIAL_SUCCESS \| FAILED \| ROLLED_BACK) | Final result |
| `post_execution_metrics` | JSON | Metrics after action (query latency, lock count, etc.) |
| `executed_by` | VARCHAR(100) | System user that ran it (should be automated system, logged for audit) |

**Constraints:**
- Foreign key to admin_approvals (cannot execute without approval)
- `execution_status` and `execution_outcome` track lifecycle
- `actual_duration_seconds` vs. estimated duration informs future planning

**Why execution outcomes matter:**
- Feeds learning_records (was the action effective?)
- Informs next decision (same action helps? recommend again; doesn't help? suggest alternative)
- If failed, learning_records note why (query error, timeout, etc.) for future decisions

---

### 8. `learning_records` — Historical Outcomes for ML Training

**Purpose:** Records effectiveness of decisions; ML learns from outcomes without controlling execution.

**Key Design Decisions:**

| Field | Type | Rationale |
|-------|------|-----------|
| `learning_record_id` | BIGINT UNSIGNED | Each learning outcome auditable |
| `issue_id` | BIGINT UNSIGNED FK | Which issue was addressed? |
| `execution_id` | BIGINT UNSIGNED FK | Which action was executed? (NULL if issue not executed) |
| `issue_resolved_flag` | BOOLEAN | Did the action resolve the issue? (human assessed) |
| `metric_improvement_percent` | DECIMAL(6, 2) | % improvement in the target metric (e.g., query latency -45%) |
| `ai_confidence_accuracy` | DECIMAL(3, 2) | How well did AI's confidence predict outcome? (calibration metric) |
| `would_approve_again` | BOOLEAN | Would admin make same decision again? |
| `learning_complete` | BOOLEAN | Ready for ML model ingestion? |

**Constraints:**
- CHECK: `metric_improvement_percent BETWEEN -100 AND 100` (can go negative if action harmed)
- learning_complete defaults to FALSE (human must validate before ML ingests)

**Why separate learning from execution?**
- ML model training requires clean, validated data
- Premature ingestion of incomplete outcomes corrupts model
- Human assessment (issue_resolved_flag, would_approve_again) adds context AI cannot infer

**How ML improves without executing:**
1. Learning_records show which actions worked for similar issues
2. ML model retrains on this data
3. AI next time recommends more effective actions (via recovery_decisions)
4. But ML cannot execute; only recommend (with updated confidence scores)
5. Humans still approve every decision

**Example learning record:**

```json
{
  "issue_id": 42,
  "execution_id": 105,
  "issue_resolved_flag": true,
  "metric_improvement_percent": 73,  /* Query latency reduced 73% */
  "ai_confidence_accuracy": 0.94,    /* AI was 0.95 confident; was right */
  "would_approve_again": true,
  "learning_complete": true          /* Ready for ML model training */
}
```

---

## Additional Schema: `audit_log` (Optional)

**Purpose:** Fine-grained audit trail of all table modifications.

**When to use:**
- If viva examiner asks "Who changed what, when?"
- For compliance requirements (if applicable)
- For debugging (who updated an approval decision?)

**NOT a shortcut:**
- Does not replace transaction logs
- Complements, does not replace, MySQL's binary log
- Used for application-level audit, not DBMS recovery

---

## Normalization Analysis

### Why Normalized?

1. **Core entities (1st Normal Form):**
   - `detection_events`: No repeating groups
   - `detected_issues`: Attributes depend on issue_id
   - `ai_analysis`, `recovery_decisions`, `admin_approvals`, `action_executions`: Each row is unique

2. **3rd Normal Form (No Transitive Dependencies):**
   - `detection_events.metric_value` depends on event_id, not on source
   - `ai_analysis.confidence_score` depends on analysis_id, not on issue_id transitively
   - Foreign keys enforce correct dependencies

### Why Some Denormalization?

| Field | Reason |
|-------|--------|
| `detected_issues.occurrence_count` | Avoids expensive COUNT() queries; updated atomically |
| `action_executions.post_execution_metrics` | JSON avoids normalization; reduces joins for read-heavy queries |
| `ai_analysis.affecting_queries` | JSON for variable schema; reduces 1:N relationships |

**Rationale:** DBMS operations are read-heavy (admins querying for decisions to review). Slight denormalization acceptable for performance.

---

## Foreign Key Design

### Relationship Graph

```
detection_events
    ↓ (first/last reference)
detected_issues
    ↓ (issue_id)
ai_analysis
    ↓ (analysis_id)
recovery_decisions ──→ predefined_actions (action_id)
    ↓ (decision_id)
admin_approvals
    ↓ (approval_id)
action_executions ──→ predefined_actions (action_id)
    ↓ (execution_id)
learning_records (issue_id, execution_id)
```

### Constraint Enforcement

| Constraint | Purpose | Violates Safety If Broken |
|-----------|---------|--------------------------|
| recovery_decisions → predefined_actions | Only predefined actions allowed | YES (arbitrary SQL could be recommended) |
| recovery_decisions → ai_analysis | All decisions link to analysis | YES (decisions with no rationale) |
| admin_approvals → recovery_decisions | All approvals link to decisions | YES (actions approved with no decision) |
| action_executions → admin_approvals | All executions require approval | **CRITICAL** (AI could execute unapproved) |
| action_executions → predefined_actions | Only allowed actions execute | **CRITICAL** (arbitrary SQL could run) |

**Enforcement:**
```sql
SET FOREIGN_KEY_CHECKS = ON;
SET CONSTRAINT ALL DEFERRED;
```

---

## Auditability: How This Schema Prevents Cheating

### Scenario 1: "Can AI execute without approval?"

**No.** action_executions requires a foreign key to admin_approvals.
If no approval exists, action cannot be created (FK constraint violated).

```sql
-- This INSERT would FAIL:
INSERT INTO action_executions (approval_id, action_id, ...)
VALUES (9999, 42, ...);
-- ERROR: Foreign key constraint fails; approval_id 9999 doesn't exist
```

### Scenario 2: "Can ML directly modify decisions?"

**No.** recovery_decisions are created once, with decision_status.
Learning_records only read from action_executions; cannot write to recovery_decisions.

Schema-level enforcement: `learning_records` has NO foreign key to `recovery_decisions` (only to `issues` and `executions`).

### Scenario 3: "Can AI change its analysis to justify approval?"

**No.** ai_analysis has a timestamp. If analysis is updated after approval, it's a timestamp violation (viva examiner can see this).
Better: treat analysis as immutable. If AI wants to re-analyze, create a new row in ai_analysis.

### Scenario 4: "Can an admin approve silently (no audit trail)?"

**No.** Every approval creates an `admin_approvals` record with:
- approval_timestamp
- admin_user_id
- approval_reason (enum with explicit options)
- admin_notes (optional, but visible)

Viva examiner can query: "Show me all approvals for issue #42."

---

## Confidentiality & Integrity Checks

### Data Integrity via Constraints

```sql
-- Confidence scores always valid
CHECK (confidence_score >= 0.00 AND confidence_score <= 1.00)

-- Metrics never go backward (usually)
CHECK (metric_value >= 0)

-- Improvement percentages sensible
CHECK (metric_improvement_percent BETWEEN -100 AND 100)
```

### Security by Design

| Risk | Prevention |
|------|-----------|
| AI executes arbitrary SQL | Foreign key to predefined_actions only |
| Admin approval bypassed | FK action_executions → admin_approvals (non-null) |
| Execution outcome hidden | Immutable action_executions log |
| ML overrides human decision | learning_records only read-append; no write to recovery_decisions |
| Audit trail tampering | InnoDB transactions, timestamps server-side |

---

## Viva Readiness: Common Questions & Answers

### Q1: "Why 8 tables instead of 3 or 30?"

**Answer:**
- **3 tables:** Would violate separation of concerns; AI analysis mixed with decisions = danger
- **8 tables:** Each serves a single, clear purpose (detection, analysis, decision, approval, execution, learning)
- **30 tables:** Over-engineered; every normalized piece doesn't need its own table

Justification: Read schema diagram (above). Each stage in the pipeline has its own table.

---

### Q2: "How do you prevent AI from bypassing human approval?"

**Answer:**

```sql
-- Examine action_executions creation:
SELECT * FROM action_executions WHERE approval_id IS NULL;
-- Result: 0 rows (impossible; FK constraint enforces NOT NULL)
```

The schema makes it cryptographically impossible to execute without approval:
1. `action_executions.approval_id` is BIGINT UNSIGNED (not nullable)
2. FOREIGN KEY (approval_id) REFERENCES admin_approvals(approval_id)
3. No approval → Cannot insert into action_executions

---

### Q3: "How does ML learn if it can't execute?"

**Answer:**

ML learns through the learning_records table:
1. Action executes → outcome recorded in action_executions
2. Admin assesses outcome → learning_record created
3. ML ingests learning_records (read-only; no write access to recovery_decisions)
4. ML model retrains, improving confidence calibration
5. **Next issue:** AI recommends better action (higher confidence), but still requires approval

**Diagram:**
```
[Action Executes] → [action_executions record]
        ↓
[Admin Reviews Outcome]
        ↓
[learning_record created] → [ML Model Retrains]
        ↓
[Next Issue] → [AI Recommends Better] → [Admin Approves/Declines]
```

---

### Q4: "Why is `confidence_score` a DECIMAL, not a FLOAT?"

**Answer:**

- **FLOAT:** Uses IEEE 754 binary representation (imprecise)
  - 0.95 might store as 0.949999999...
  - Breaks checks like `WHERE confidence_score = 0.95`
  - Unsuitable for audit logs

- **DECIMAL(3, 2):** Exact decimal representation
  - 0.95 stores exactly as 0.95
  - Suitable for financial/audit contexts (score calibration is critical)
  - Constraint checking reliable

---

### Q5: "What if an action partially succeeds (some rows updated, some fail)?"

**Answer:**

The schema handles this via `execution_outcome`:

```sql
UPDATE action_executions 
SET execution_outcome = 'PARTIAL_SUCCESS',
    affected_rows = 5000,  /* 5000 succeeded, 3000 failed */
    execution_errors = 'Timeout after 5000 rows due to lock'
WHERE execution_id = 123;
```

Learning_record can then assess:
- Is partial success acceptable?
- Should this action be attempted again?
- Are there prerequisites missing (e.g., kill blocking transaction first)?

---

### Q6: "How do you track which MySQL mechanisms detected what?"

**Answer:**

`detection_events.detection_source` explicitly records source:

```sql
SELECT * FROM detection_events 
WHERE detection_source = 'PERFORMANCE_SCHEMA' 
  AND event_timestamp > '2026-01-30 10:00:00'
ORDER BY event_timestamp;
```

Allows:
- Auditing which MySQL features are actually used
- Validating that only DBMS mechanisms are sources of truth (not application logs)
- Debugging (if a mechanism is unreliable, phase it out)

---

### Q7: "What prevents an admin from rubber-stamping all approvals?"

**Answer:**

Schema doesn't enforce this (human integrity required), but enables detection:

```sql
SELECT admin_user_id, COUNT(*) as approval_count
FROM admin_approvals
WHERE approval_timestamp > DATE_SUB(NOW(), INTERVAL 1 DAY)
GROUP BY admin_user_id
ORDER BY approval_count DESC;
```

Patterns visible:
- Too many approvals too quickly (100 per hour = rubber stamping)
- All approvals marked CONFIDENT (suspicious if not realistic)
- No DECLINED decisions (admin never says no?)

**How to prevent:** Organizational controls (approval quorum for HIGH-risk actions, rotation policies). Schema enables auditing; management enforces discipline.

---

### Q8: "What if the same issue recurs after a 'resolved' action?"

**Answer:**

1. Original issue: `detected_issues.issue_id = 1` (RESOLVED)
2. Same problem detected again
3. New issue: `detected_issues.issue_id = 2` (DETECTED)
4. Learning_records can compare both

```sql
SELECT l1.issue_id as original, l2.issue_id as recurrence
FROM learning_records l1
JOIN learning_records l2 ON l1.action_id = l2.action_id
WHERE l1.issue_resolved_flag = TRUE
  AND l2.issue_id != l1.issue_id
  AND ABS(DATEDIFF(l2.record_created_at, l1.record_created_at)) < 30;
```

**Indicates:**
- Action effectiveness decays over time (needs re-application)
- Root cause wasn't fully addressed (original analysis too shallow)
- Feeds learning loop: "this action works, but needs maintenance"

---

## Testing the Schema

### Test Case 1: Normal Flow (Happy Path)

```sql
-- 1. DBMS detects slow query
INSERT INTO detection_events (...) VALUES (...);
-- Result: detection_events.event_id = 1

-- 2. Issue categorized
INSERT INTO detected_issues (first_occurrence_event_id, ...) VALUES (1, ...);
-- Result: detected_issues.issue_id = 1, status = DETECTED

-- 3. AI analyzes
INSERT INTO ai_analysis (issue_id, ...) VALUES (1, ...);
-- Result: ai_analysis.analysis_id = 1

-- 4. AI recommends action
INSERT INTO recovery_decisions (analysis_id, recommended_action_id, decision_status) VALUES (1, 5, 'PENDING_APPROVAL');
-- Result: recovery_decisions.decision_id = 1, status = PENDING_APPROVAL

-- 5. Admin approves
INSERT INTO admin_approvals (decision_id, approval_status) VALUES (1, 'APPROVED');
-- Result: admin_approvals.approval_id = 1

-- 6. Action executes
INSERT INTO action_executions (approval_id, action_id, execution_status) VALUES (1, 5, 'COMPLETED');
-- Result: action_executions.execution_id = 1

-- 7. Learning recorded
INSERT INTO learning_records (issue_id, execution_id, issue_resolved_flag) VALUES (1, 1, TRUE);
-- Result: learning_record_id = 1
```

All foreign keys satisfied. No errors.

### Test Case 2: Safety Boundary — AI Cannot Execute Unapproved

```sql
-- AI tries to execute without approval
INSERT INTO action_executions (approval_id, action_id, ...) 
VALUES (9999, 5, ...);  -- approval_id 9999 doesn't exist

-- Result: ERROR 1452 - Foreign key constraint fails
```

**Good.** Schema prevents this.

### Test Case 3: Safety Boundary — Only Predefined Actions

```sql
-- AI recommends non-existent action
INSERT INTO recovery_decisions (analysis_id, recommended_action_id, ...) 
VALUES (1, 9999, ...);  -- action_id 9999 doesn't exist

-- Result: ERROR 1452 - Foreign key constraint fails
```

**Good.** Schema prevents this.

---

## Performance Considerations

### Indexes

```sql
-- High-cardinality fields (used in WHERE/JOIN)
KEY idx_timestamp (event_timestamp)
KEY idx_status (issue_status)
KEY idx_decision_status (decision_status)
KEY idx_approval_status (approval_status)
KEY idx_execution_status (execution_status)

-- Foreign key columns (used in JOIN)
KEY idx_issue (issue_id)
KEY idx_analysis (analysis_id)
KEY idx_action (action_id)

-- Composite indexes (common queries)
KEY idx_resource (affected_resource_type, affected_resource_name)
KEY idx_source (detection_source)
```

### Query Patterns

**Query 1: "Show me all pending decisions"**
```sql
SELECT d.decision_id, d.decision_rationale, a.confidence_score
FROM recovery_decisions d
JOIN ai_analysis a ON d.analysis_id = a.analysis_id
WHERE d.decision_status = 'PENDING_APPROVAL'
ORDER BY a.confidence_score DESC;
```
Uses: `idx_decision_status`, FK index on analysis_id

**Query 2: "How effective was this action?"**
```sql
SELECT COUNT(*) as total_uses,
       SUM(CASE WHEN issue_resolved_flag THEN 1 ELSE 0 END) as successful,
       AVG(metric_improvement_percent) as avg_improvement
FROM learning_records
WHERE execution_id IN (SELECT execution_id FROM action_executions WHERE action_id = 5);
```
Uses: FK index on execution_id

**Query 3: "What's AI's accuracy on high-confidence recommendations?"**
```sql
SELECT a.confidence_score, 
       COUNT(*) as predictions,
       SUM(CASE WHEN l.issue_resolved_flag THEN 1 ELSE 0 END) as correct
FROM ai_analysis a
JOIN recovery_decisions d ON a.analysis_id = d.analysis_id
JOIN admin_approvals ap ON d.decision_id = ap.decision_id
JOIN action_executions e ON ap.approval_id = e.approval_id
LEFT JOIN learning_records l ON e.execution_id = l.execution_id
WHERE a.confidence_score >= 0.80
GROUP BY ROUND(a.confidence_score, 2);
```

Uses: Multiple FK indexes, confidence_score index

---

## Conclusion

This schema is:

✓ **Architecturally sound:** Strict separation of concerns enforced at the database level  
✓ **Safe:** AI cannot execute anything; ML cannot bypass approval  
✓ **Auditable:** Every decision, approval, and execution is traceable  
✓ **Normalized:** Reduces anomalies; maintains data integrity  
✓ **Viva-ready:** Clear design rationale for every table and constraint  
✓ **Minimal:** 8 tables, no over-engineering  
✓ **MySQL-appropriate:** InnoDB, proper indexes, constraints  

It answers the fundamental question: **"How do we build a system where DBMS detects, AI interprets, humans decide, and only safe actions execute?"**

---

**End of Design Document**
