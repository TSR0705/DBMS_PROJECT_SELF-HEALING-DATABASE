---
title: "Architecture Diagrams & Visual Reference"
---

# Visual Architecture Reference

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                       AI-ASSISTED SELF-HEALING DBMS                         │
│                         Phase 2, Step 1 Schema                              │
└─────────────────────────────────────────────────────────────────────────────┘

STAGE 1: DETECTION (DBMS Responsibility)
═════════════════════════════════════════
        │
        ├─► Performance Schema ──────┐
        │                             │
        ├─► Slow Query Log ──────────┤──► detection_events (immutable append-only)
        │                             │
        └─► InnoDB Deadlock ────────┘

        Key: What did the DBMS observe? Record exactly what happened.

STAGE 2: ANALYSIS (AI Responsibility)
═════════════════════════════════════════
        │
        ├─► categorized issue ───┐
        │                         │
        ├─► root_cause_hypothesis ├──► detected_issues (categorized) + ai_analysis (confidence scored)
        │                         │
        └─► confidence_score ────┘

        Key: AI interprets events. Issues categorized. Confidence scored.
        AI cannot make decisions; only recommendations.

STAGE 3: DECISION (AI Recommends, Human Approves)
══════════════════════════════════════════════════
        │
        ├─► AI: "recommend action X" ───────────┐
        │                                         ├──► recovery_decisions (PENDING_APPROVAL)
        └─► Predefined Actions Whitelist ────────┘

        Key: Link recommendation to a predefined action (no arbitrary SQL).
        Status: PENDING_APPROVAL (not auto-executed).

STAGE 4: APPROVAL (Mandatory Human Checkpoint)
════════════════════════════════════════════════
        │
        ├─► Admin reviews decision
        │
        ├─► Admin assesses risk (predefined_actions.risk_level helps)
        │
        └─► Admin approves/declines ──────────► admin_approvals (decision_status = APPROVED or DECLINED)

        Key: No execution without approval. Approval recorded with admin_user_id and reason.

STAGE 5: EXECUTION (Automated, Safe)
═════════════════════════════════════════
        │
        └─► IF approval_status = 'APPROVED':
                │
                ├─► Fetch action from predefined_actions
                │
                ├─► Substitute parameters (validate)
                │
                ├─► Execute SQL ────────────► action_executions (COMPLETED/FAILED)
                │
                └─► Record outcome (success, errors, metrics)

        Key: Only predefined actions allowed. No dynamic SQL.

STAGE 6: LEARNING (ML Model Improvement)
═════════════════════════════════════════
        │
        ├─► Admin assesses: did action resolve issue?
        │
        ├─► Measure: metric improvement percentage
        │
        ├─► Calibrate: how well did AI's confidence predict outcome?
        │
        └─► Record: learning_records (learning_complete = TRUE)

        Key: ML ingests learning_records (read-only). Improves next recommendation.
        ML does NOT execute. Humans still approve every decision.


FEEDBACK LOOP (Continuous Improvement)
═══════════════════════════════════════
learning_records ──► [ML Model Retrains] ──► [Better confidence scores]
                                                      │
                                                      └──► ai_analysis (higher accuracy)
                                                              │
                                                              └──► recovery_decisions (better recommendations)

But: ML cannot write to recovery_decisions. Only admins can approve.


SAFETY BARRIERS (What Prevents Cheating?)
═════════════════════════════════════════════
        │
        ├─ AI executes without approval?
        │  └─ NO: FK constraint action_executions.approval_id → admin_approvals (NOT NULL)
        │
        ├─ Arbitrary SQL executed?
        │  └─ NO: FK constraint recovery_decisions.action_id → predefined_actions (whitelist only)
        │
        ├─ ML overrides human decision?
        │  └─ NO: learning_records is append-only; no write to recovery_decisions
        │
        ├─ Audit trail tampered?
        │  └─ NO: InnoDB transactions, server-side TIMESTAMP(6)
        │
        └─ Unapproved action queued silently?
           └─ NO: action_executions.approval_id is FOREIGN KEY (non-null enforcement)
```

---

## Entity-Relationship Diagram (ERD)

```
┌──────────────────────────┐
│ detection_events         │
│ (Immutable DBMS Log)     │
├──────────────────────────┤
│ event_id (PK)            │
│ event_timestamp          │
│ detection_source [ENUM]  │
│ target_resource_type     │
│ metric_value             │
│ raw_context [JSON]       │
└──────────────────────────┘
           │
           │ 1:N (first/last occurrence)
           │
           ▼
┌──────────────────────────┐
│ detected_issues          │
│ (Categorized Problems)   │
├──────────────────────────┤
│ issue_id (PK)            │
│ issue_category [ENUM]    │
│ occurrence_count         │
│ issue_status [ENUM]      │
│ first_occurrence_event_id (FK)
│ last_detection_event_id (FK)
└──────────────────────────┘
           │
           │ 1:N (AI may re-analyze)
           │
           ▼
┌──────────────────────────┐
│ ai_analysis              │
│ (Interpretation)         │
├──────────────────────────┤
│ analysis_id (PK)         │
│ issue_id (FK)            │
│ confidence_score         │
│ root_cause_hypothesis    │
│ recommendation_summary   │
│ analysis_status [ENUM]   │
└──────────────────────────┘
           │
           │ 1:1 (one decision per analysis usually)
           │
           ▼
┌──────────────────────────┐         ┌─────────────────────────────┐
│ recovery_decisions       │ ─────► │ predefined_actions          │
│ (AI Recommendation)      │  N:1   │ (Safety Whitelist)          │
├──────────────────────────┤         ├─────────────────────────────┤
│ decision_id (PK)         │         │ action_id (PK)              │
│ analysis_id (FK)         │         │ action_name [UNIQUE]        │
│ recommended_action_id (FK)         │ execution_query             │
│ decision_status [ENUM]   │         │ risk_level [ENUM]           │
│ confidence_based_score   │         │ applicable_issue_categories │
│ decision_rationale       │         │ requires_manual_verification│
└──────────────────────────┘         └─────────────────────────────┘
           │
           │ 1:1 (one approval per decision)
           │
           ▼
┌──────────────────────────┐
│ admin_approvals          │
│ (MANDATORY CHECKPOINT)   │
├──────────────────────────┤
│ approval_id (PK)         │
│ decision_id (FK)         │
│ admin_user_id            │
│ approval_status [ENUM]   │
│ approval_reason [ENUM]   │
│ admin_notes              │
└──────────────────────────┘
           │
           │ 1:1 (execution follows approval)
           │
           ▼
┌──────────────────────────┐         ┌──────────────────────────┐
│ action_executions        │ ────── │ predefined_actions       │
│ (Execution Log)          │  N:1    │                          │
├──────────────────────────┤         └──────────────────────────┘
│ execution_id (PK)        │
│ approval_id (FK)         │
│ action_id (FK)           │
│ execution_status [ENUM]  │
│ execution_outcome [ENUM] │
│ post_execution_metrics   │
│ actual_duration_seconds  │
│ execution_errors         │
└──────────────────────────┘
           │
           │ 0:1 (only executed actions)
           │
           ▼
┌──────────────────────────┐
│ learning_records         │
│ (ML Training Data)       │
├──────────────────────────┤
│ learning_record_id (PK)  │
│ issue_id (FK)            │
│ execution_id (FK)        │
│ issue_resolved_flag      │
│ metric_improvement_%     │
│ would_approve_again      │
│ learning_complete        │
└──────────────────────────┘
```

**Key Relationships:**
- `detection_events` ← (1:N) → `detected_issues` ← (1:N) → `ai_analysis`
- `ai_analysis` ← (1:1) → `recovery_decisions` ← (1:1) → `admin_approvals`
- `admin_approvals` ← (1:1) → `action_executions` ← (N:1) → `predefined_actions`
- `action_executions` ← (0:1) → `learning_records`

**Safety Guarantees:**
- All FKs are NOT NULL (except where noted as optional)
- No circular dependencies
- No direct path from `ai_analysis` or ML to `action_executions` (human approval mandatory)

---

## State Machine: Issue Lifecycle

```
┌─────────────┐
│   DETECTED  │  ← Issue first detected (detection_events recorded)
└──────┬──────┘
       │ (AI analysis started)
       ▼
┌─────────────────────┐
│  UNDER_ANALYSIS     │  ← ai_analysis record created, confidence being scored
└──────┬──────────────┘
       │ (Analysis complete)
       ▼
┌──────────────────────┐
│  AWAITING_DECISION   │  ← waiting for recovery_decisions to be made
└──────┬───────────────┘
       │ (AI recommends action)
       ▼
┌──────────────────────┐
│   DECISION_MADE      │  ← recovery_decisions.status = PENDING_APPROVAL
└──────┬───────────────┘
       │ (Admin reviews)
       │
       ├─ APPROVED ──────┐
       │                 │
       │                 └──────┬──────────┐
       │                        │          │
       │                  (Approved) ┌──────────────┐
       │                        │    │   APPROVED   │
       │                        │    └──────┬───────┘
       │                        │           │ (Execution starts)
       │                        │           ▼
       │                        │    ┌──────────────────┐
       │                        │    │   EXECUTING      │  ← action_executions in progress
       │                        │    └──────┬───────────┘
       │                        │           │ (Execution completes)
       │                        │           ▼
       │                        │    ┌──────────────────┐
       │                        │    │   RESOLVED       │  ← Issue fixed (learning_records.issue_resolved_flag=TRUE)
       │                        │    └──────────────────┘
       │                        │
       │                        │
       │    (Rejected) ┌────────┴──────────────┐
       │               │                       │
       └─ DECLINED ────┤   ┌──────────────┐   │
                       │   │  DECLINED    │   │
                       │   └──────┬───────┘   │
                       │          │           │
                       │          └─ Re-analyze (loop back to UNDER_ANALYSIS)
                       │
                       └─ Other issue (mark as CANCELLED)

Transitions:
  DETECTED → UNDER_ANALYSIS → AWAITING_DECISION → DECISION_MADE → {APPROVED|DECLINED}
  APPROVED → EXECUTING → RESOLVED
  DECLINED → (closed or re-analyze)
  Any state → CANCELLED (if issue no longer relevant)
```

---

## Data Flow: A Complete Example

```
SCENARIO: Query performance issue detected

TIME    EVENT                            TABLE              ACTION
─────────────────────────────────────────────────────────────────────────────

10:00   Slow query detected by          detection_events   INSERT event_id=1
        Performance Schema              
        - SELECT * FROM users
        - Duration: 5.4 seconds
        - Full table scan

10:01   Issue categorized               detected_issues    INSERT issue_id=1
        - Category: QUERY_PERFORMANCE   
        - Status: DETECTED
        - Reference: event_id=1

10:02   AI analyzes issue               ai_analysis        INSERT analysis_id=1
        - Hypothesis: Missing index on status
        - Confidence: 0.92
        - Status: RECOMMENDATION_ISSUED

10:03   AI recommends action            recovery_decisions INSERT decision_id=1
        - Action: add_missing_index
        - Status: PENDING_APPROVAL
        - Confidence: 0.92

10:04   Admin reviews dashboard         admin_approvals    QUERY recovery_decisions
        - Sees pending approval
        - Risk level: MEDIUM
        - Decides to approve

10:05   Admin approves                  admin_approvals    INSERT approval_id=1
        - Status: APPROVED
        - Reason: CONFIDENT
        - Notes: "Index on status will help"

10:06   Action executes                 action_executions  INSERT execution_id=1
        - Queries: ALTER TABLE users ADD INDEX...
        - Duration: 45 seconds
        - Status: COMPLETED
        - Outcome: SUCCESS

10:50   Admin verifies outcome          action_executions  SELECT post_execution_metrics
        - Query now executes in 1.8 sec
        - Improvement: 67%
        - No side effects

10:51   Learning recorded               learning_records   INSERT learning_record_id=1
        - issue_resolved_flag: TRUE
        - metric_improvement_percent: 67
        - would_approve_again: TRUE
        - learning_complete: TRUE

NEXT:   ML model retrains on             [External ML]     Model confidence improved
        learning_record_id=1                                for similar issues

FUTURE: Similar issue detected          recovery_decisions [AI recommends with higher
        within 3 days                                       confidence (0.95+)]
```

---

## Safety: What Prevents Each Risk?

```
RISK                              PREVENTED BY                        WHERE IN SCHEMA
────────────────────────────────────────────────────────────────────────────────────

AI executes without approval      FK NOT NULL                         action_executions.approval_id
                                  action_executions → admin_approvals

Arbitrary SQL executed            FK enforcement                      recovery_decisions.action_id
                                  recovery_decisions → predefined_    → predefined_actions.action_id
                                  actions (whitelist only)

ML overrides human                Referential integrity               learning_records has no FK
                                  learning_records is read-only       to recovery_decisions
                                  for ML; no write permission

Execution without decision        FK enforcement                      action_executions.approval_id
                                  action_executions → admin_approvals

Decision without analysis         FK enforcement                      recovery_decisions.analysis_id
                                  recovery_decisions → ai_analysis

Audit trail tampering            Server-side TIMESTAMP(6)            All tables
                                 InnoDB transactions
                                 FOREIGN_KEY_CHECKS = ON

Admin approval bypassed           InnoDB constraint                   admin_approvals.approval_status
                                  Cannot set to APPROVED without      must be explicitly set
                                  record creation

ML confidence not validated       CHECK constraints                   ai_analysis, recovery_decisions
                                  confidence_score BETWEEN 0 AND 1

Action partially succeeds         Captured in execution_outcome       action_executions.execution_outcome
silently                          PARTIAL_SUCCESS tracked            can be PARTIAL_SUCCESS

Admin rubber-stamps               Queryable approval_reason field     admin_approvals.approval_reason
decisions                         enables audit of patterns

Issue resolved but                learning_records tracks             learning_records.
recurs weeks later                effectiveness over time            would_approve_again,
                                                                      time_to_resolution_hours
```

---

## Admin Dashboard View (Conceptual)

```
┌─────────────────────────────────────────────────────────────────────────┐
│ ADMIN DASHBOARD: Self-Healing DBMS Control Panel                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│ PENDING APPROVALS (5 waiting)                                            │
│ ┌──────────────────────────────────────────────────────────────────────┐ │
│ │ Decision    │ Issue            │ AI Confidence │ Action      │ Risk  │ │
│ ├──────────────────────────────────────────────────────────────────────┤ │
│ │ #1001       │ Query: users     │ 0.92          │ Add index   │ MEDIUM│ │
│ │ #1002       │ Lock contention  │ 0.87          │ Kill QUERY  │ HIGH  │ │
│ │ #1003       │ Table fragment   │ 0.71          │ OPTIMIZE    │ LOW   │ │
│ └──────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│ EXECUTION STATUS (24 hours)                                              │
│ ┌──────────────────────────────────────────────────────────────────────┐ │
│ │ Action         │ Count │ Successful │ Success Rate │ Avg Improvement │ │
│ ├──────────────────────────────────────────────────────────────────────┤ │
│ │ Add index      │ 8     │ 7          │ 87.5%        │ +58%            │ │
│ │ Kill QUERY     │ 5     │ 4          │ 80%          │ +12ms           │ │
│ │ OPTIMIZE TABLE │ 3     │ 2          │ 66%          │ +3%             │ │
│ └──────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
│ APPROVAL AUDIT (last 7 days)                                             │
│ ┌──────────────────────────────────────────────────────────────────────┐ │
│ │ Admin      │ Approvals │ Declined │ Rate  │ Most Common Reason      │ │
│ ├──────────────────────────────────────────────────────────────────────┤ │
│ │ admin1     │ 24        │ 3        │ 88%   │ CONFIDENT               │ │
│ │ admin2     │ 18        │ 2        │ 89%   │ ROUTINE                 │ │
│ │ admin3     │ 12        │ 5        │ 70%   │ SAFETY_CONCERN          │ │
│ └──────────────────────────────────────────────────────────────────────┘ │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Learning Loop Feedback

```
ITERATION 1
===========
Issue detected → AI analyzes → Recommends with 0.80 confidence
              → Admin approves → Action succeeds → Metric +50%
              → Learning recorded: confidence_accuracy = 0.85

Result: AI was slightly over-confident (0.80 vs. 0.85 actual accuracy)


ITERATION 2 (Days later, similar issue)
========================================
Issue detected → AI analyzes → Recommends with 0.82 confidence
              → Admin approves (slightly higher confidence) → Action succeeds
              → Learning recorded: confidence_accuracy = 0.90

Result: AI confidence improved (from 0.80 to 0.82); accuracy better (0.85 → 0.90)


FEEDBACK MECHANISM
==================
Learning_records → [ML Model] → Updated confidence weights
                  ↓
        AI_analysis recommendations improve
                  ↓
        recovery_decisions more effective
                  ↓
        Admin approvals faster (trust higher confidence)
                  ↓
        Better outcomes (higher success rate)


But ALWAYS:
  Admin approval is still required
  ML does not execute anything
  Only predefined actions allowed
  Schema enforces boundaries
```

---

## This Is Your Viva Cheat Sheet

**Keep this diagram in mind:**

```
DBMS Detects → AI Interprets → Human Approves → System Executes → ML Learns
   (Immutable)   (Confidence)    (Mandatory)    (Predefined)      (Not Control)
```

**Each stage:**
- Cannot skip previous stages
- Cannot directly modify next stage
- Has its own table(s)
- Is auditable
- Has clear success/failure criteria

**The magic:** Separation of concerns built into the schema itself.

---

**End of Architecture Document**
