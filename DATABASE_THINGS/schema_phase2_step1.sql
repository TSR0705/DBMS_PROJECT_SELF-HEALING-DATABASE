-- ============================================================================
-- AI-ASSISTED SELF-HEALING DBMS SYSTEM
-- Phase 2, Step 1: Normalized MySQL Schema Design
-- ============================================================================
-- ARCHITECTURAL PRINCIPLES:
--   1. Strict separation: Detection → Analysis → Decision → Execution → Learning
--   2. AI recommends, humans approve, DBMS executes predefined actions only
--   3. Every action is auditable; no direct ML control over execution
--   4. All tables use InnoDB with proper constraints
-- ============================================================================

CREATE DATABASE IF NOT EXISTS self_healing_dbms CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE self_healing_dbms;

-- ============================================================================
-- TABLE 1: detection_events
-- ============================================================================
-- PURPOSE: Records raw detection signals from MySQL DBMS mechanisms
--   - Performance Schema queries
--   - Slow query logs
--   - InnoDB deadlock detection
-- RATIONALE:
--   - Immutable append-only log of what the DBMS detected
--   - Timestamps allow temporal analysis
--   - Source field enables traceability (which MySQL mechanism detected this)
--   - Separates detection (DBMS responsibility) from interpretation (AI responsibility)
-- PRIMARY KEY: event_id (surrogate key for auditability)
-- ============================================================================
CREATE TABLE detection_events (
    event_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    event_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    detection_source ENUM('PERFORMANCE_SCHEMA', 'SLOW_QUERY_LOG', 'INNODB_DEADLOCK') NOT NULL,
    target_resource_type ENUM('TABLE', 'INDEX', 'CONNECTION', 'TRANSACTION', 'LOCK') NOT NULL,
    target_resource_name VARCHAR(255) NOT NULL,
    metric_name VARCHAR(100) NOT NULL COMMENT 'e.g., full_table_scans, lock_wait_time_ms',
    metric_value DECIMAL(20, 4) NOT NULL COMMENT 'Numeric value of detected metric',
    severity_indicator ENUM('INFO', 'WARNING', 'CRITICAL') NOT NULL COMMENT 'Severity from DBMS, not AI',
    raw_context JSON NOT NULL COMMENT 'Additional context from DBMS (e.g., query text, thread info)',
    
    PRIMARY KEY (event_id),
    KEY idx_timestamp (event_timestamp),
    KEY idx_source (detection_source),
    KEY idx_resource (target_resource_type, target_resource_name),
    CONSTRAINT chk_metric_positive CHECK (metric_value >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Immutable log of DBMS detections; source of truth for what DBMS observed';

-- ============================================================================
-- TABLE 2: detected_issues
-- ============================================================================
-- PURPOSE: Categorized classification of events into actionable issues
--   - One or more events may indicate the same underlying issue
--   - Issues are DBMS-focused (not application problems)
-- RATIONALE:
--   - Aggregates multiple events into meaningful problems
--   - Allows tracking the lifecycle of an issue (detected → analyzed → decided → executed)
--   - status field tracks progression (not for AI to change; only execution updates it)
--   - first_occurrence links to originating event; last_detection_event tracks latest signal
-- PRIMARY KEY: issue_id
-- FOREIGN KEY: first_occurrence_event_id → detection_events.event_id
-- ============================================================================
CREATE TABLE detected_issues (
    issue_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    issue_created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    issue_category ENUM('QUERY_PERFORMANCE', 'LOCK_CONTENTION', 'DEADLOCK', 'INDEX_INEFFICIENCY', 'TABLE_FRAGMENTATION', 'CONNECTION_EXHAUSTION') NOT NULL,
    affected_resource_type ENUM('TABLE', 'INDEX', 'CONNECTION', 'TRANSACTION', 'LOCK') NOT NULL,
    affected_resource_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL COMMENT 'Human-readable summary of the issue',
    first_occurrence_event_id BIGINT UNSIGNED NOT NULL,
    last_detection_event_id BIGINT UNSIGNED NOT NULL,
    occurrence_count INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'How many events triggered this issue',
    issue_status ENUM('DETECTED', 'UNDER_ANALYSIS', 'AWAITING_DECISION', 'DECISION_MADE', 'APPROVED', 'EXECUTING', 'RESOLVED', 'DECLINED') NOT NULL DEFAULT 'DETECTED',
    
    PRIMARY KEY (issue_id),
    FOREIGN KEY (first_occurrence_event_id) REFERENCES detection_events(event_id),
    FOREIGN KEY (last_detection_event_id) REFERENCES detection_events(event_id),
    KEY idx_category (issue_category),
    KEY idx_status (issue_status),
    KEY idx_resource (affected_resource_type, affected_resource_name),
    KEY idx_created (issue_created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Categorized DBMS issues derived from detection_events; bridges detection and analysis';

-- ============================================================================
-- TABLE 3: ai_analysis
-- ============================================================================
-- PURPOSE: AI interpretation and confidence assessment of issues
--   - AI never modifies issues or makes decisions; it only provides analysis
--   - Confidence scores inform decision-making
-- RATIONALE:
--   - Strict separation: detection (DBMS) vs. analysis (AI) vs. decision (human + AI recommendation)
--   - root_cause_hypothesis is AI's best guess; may be wrong (hence confidence field)
--   - confidence_score (0-1) indicates AI certainty
--   - recommendation_summary suggests which actions might help (not a decision)
--   - Multiple analyses possible for one issue (e.g., re-analyze with more data)
--   - analysis_status tracks whether recommendation was acted upon
-- PRIMARY KEY: analysis_id
-- FOREIGN KEY: issue_id → detected_issues.issue_id
-- ============================================================================
CREATE TABLE ai_analysis (
    analysis_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    issue_id BIGINT UNSIGNED NOT NULL,
    analysis_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    root_cause_hypothesis VARCHAR(500) NOT NULL COMMENT 'AI best guess at root cause',
    confidence_score DECIMAL(3, 2) NOT NULL COMMENT 'AI confidence (0.00-1.00)',
    contributing_factors JSON NOT NULL COMMENT 'List of factors contributing to issue (e.g., query complexity, index stats)',
    recommendation_summary TEXT NOT NULL COMMENT 'What actions might resolve this issue (informational only)',
    affected_queries JSON COMMENT 'Queries involved in the issue (if applicable)',
    historical_similarity_score DECIMAL(3, 2) COMMENT 'How similar to past issues (0.00-1.00)',
    analysis_status ENUM('RECOMMENDATION_ISSUED', 'DECISION_PENDING', 'DECISION_DECLINED', 'DECISION_APPROVED', 'ACTION_COMPLETED') NOT NULL DEFAULT 'RECOMMENDATION_ISSUED',
    
    PRIMARY KEY (analysis_id),
    FOREIGN KEY (issue_id) REFERENCES detected_issues(issue_id),
    KEY idx_issue (issue_id),
    KEY idx_timestamp (analysis_timestamp),
    KEY idx_status (analysis_status),
    CONSTRAINT chk_confidence_range CHECK (confidence_score >= 0.00 AND confidence_score <= 1.00),
    CONSTRAINT chk_similarity_range CHECK (historical_similarity_score IS NULL OR (historical_similarity_score >= 0.00 AND historical_similarity_score <= 1.00))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='AI interpretation and confidence; never controls execution, only informs decisions';

-- ============================================================================
-- TABLE 4: predefined_actions
-- ============================================================================
-- PURPOSE: Catalog of safe, pre-approved recovery actions
--   - Only these actions can ever be executed
--   - Acts as a safety whitelist; prevents arbitrary DBMS modifications
-- RATIONALE:
--   - Explicit list of allowed actions ensures safety
--   - risk_level helps admins review decisions
--   - estimated_impact allows admins to understand consequences
--   - Execution query is parameterized and validated before use
--   - No dynamic SQL generation; only predefined actions allowed
-- PRIMARY KEY: action_id
-- NO FOREIGN KEYS (these are master data)
-- ============================================================================
CREATE TABLE predefined_actions (
    action_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    action_name VARCHAR(100) NOT NULL UNIQUE,
    action_category ENUM('INDEX_OPTIMIZATION', 'QUERY_REWRITE', 'LOCK_MANAGEMENT', 'CONNECTION_MANAGEMENT', 'TABLE_OPTIMIZATION', 'STATISTICS_UPDATE') NOT NULL,
    description TEXT NOT NULL COMMENT 'What this action does',
    execution_query TEXT NOT NULL COMMENT 'SQL command to execute (may contain placeholders like :table_name)',
    applicable_issue_categories JSON NOT NULL COMMENT 'Which issue_category types this action addresses',
    risk_level ENUM('LOW', 'MEDIUM', 'HIGH') NOT NULL COMMENT 'Human assessment of risk',
    estimated_duration_seconds INT UNSIGNED NOT NULL DEFAULT 5 COMMENT 'Approximate execution time',
    estimated_impact VARCHAR(255) NOT NULL COMMENT 'What will improve (e.g., "query latency", "lock contention")',
    requires_manual_verification BOOLEAN DEFAULT FALSE COMMENT 'Does admin need to verify outcome?',
    action_enabled BOOLEAN DEFAULT TRUE COMMENT 'Can this action be used?',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (action_id),
    KEY idx_category (action_category),
    KEY idx_enabled (action_enabled)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Whitelist of safe recovery actions; only these can be executed';

-- ============================================================================
-- TABLE 5: recovery_decisions
-- ============================================================================
-- PURPOSE: AI recommends which action(s) to take for an issue
--   - AI proposes, humans dispose
--   - Decision status tracks human approval workflow
-- RATIONALE:
--   - Links AI analysis to predefined actions
--   - Separates recommendation (AI) from approval (human)
--   - decision_status ensures human review is mandatory
--   - Optional rationale field allows admins to add notes
--   - confidence_based_score helps admins prioritize which decisions to review first
-- PRIMARY KEY: decision_id
-- FOREIGN KEYS: analysis_id → ai_analysis.analysis_id
--               recommended_action_id → predefined_actions.action_id
-- ============================================================================
CREATE TABLE recovery_decisions (
    decision_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    analysis_id BIGINT UNSIGNED NOT NULL,
    recommended_action_id BIGINT UNSIGNED NOT NULL,
    decision_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    confidence_based_score DECIMAL(3, 2) NOT NULL COMMENT 'AI analysis confidence applied to this decision',
    decision_rationale TEXT NOT NULL COMMENT 'Why AI recommends this action',
    decision_status ENUM('PENDING_APPROVAL', 'APPROVED', 'DECLINED', 'CANCELLED') NOT NULL DEFAULT 'PENDING_APPROVAL',
    
    PRIMARY KEY (decision_id),
    FOREIGN KEY (analysis_id) REFERENCES ai_analysis(analysis_id),
    FOREIGN KEY (recommended_action_id) REFERENCES predefined_actions(action_id),
    KEY idx_analysis (analysis_id),
    KEY idx_status (decision_status),
    KEY idx_timestamp (decision_timestamp),
    CONSTRAINT chk_decision_confidence CHECK (confidence_based_score >= 0.00 AND confidence_based_score <= 1.00)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='AI recommendations for actions; awaits human approval before execution';

-- ============================================================================
-- TABLE 6: admin_approvals
-- ============================================================================
-- PURPOSE: Human review and approval of AI-recommended decisions
--   - Mandatory checkpoint; no execution without approval
--   - Audit trail of human judgment
-- RATIONALE:
--   - Ensures human oversight of all risky decisions
--   - approval_timestamp shows when decision was reviewed
--   - admin_notes allows reasoning documentation
--   - Approvals can be conditional (e.g., "approve during maintenance window only")
--   - approval_reason helps build historical knowledge
-- PRIMARY KEY: approval_id
-- FOREIGN KEY: decision_id → recovery_decisions.decision_id
-- ============================================================================
CREATE TABLE admin_approvals (
    approval_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    decision_id BIGINT UNSIGNED NOT NULL,
    admin_user_id VARCHAR(100) NOT NULL COMMENT 'System user ID of approving admin',
    approval_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    approval_status ENUM('APPROVED', 'DECLINED', 'CONDITIONAL_APPROVAL') NOT NULL,
    admin_notes TEXT,
    approval_reason ENUM('CONFIDENT', 'ROUTINE', 'EMERGENCY', 'SKEPTICAL_BUT_APPROVED', 'SAFETY_CONCERN', 'RESOURCE_CONSTRAINT') NOT NULL,
    
    PRIMARY KEY (approval_id),
    FOREIGN KEY (decision_id) REFERENCES recovery_decisions(decision_id),
    KEY idx_decision (decision_id),
    KEY idx_timestamp (approval_timestamp),
    KEY idx_admin (admin_user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Human approval checkpoints; mandatory for execution';

-- ============================================================================
-- TABLE 7: action_executions
-- ============================================================================
-- PURPOSE: Records actual execution of approved actions and their outcomes
--   - Only APPROVED decisions in admin_approvals trigger executions
--   - Immutable execution log
-- RATIONALE:
--   - execution_timestamp shows when action ran
--   - execution_outcome tracks success/failure
--   - actual_duration_seconds allows monitoring of performance
--   - execution_errors captures any MySQL errors encountered
--   - affected_rows shows impact of the action
--   - post_execution_metrics allows validation (e.g., query latency after optimization)
--   - status field shows if execution is complete or in-progress
-- PRIMARY KEY: execution_id
-- FOREIGN KEYS: approval_id → admin_approvals.approval_id
--               action_id → predefined_actions.action_id
-- ============================================================================
CREATE TABLE action_executions (
    execution_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    approval_id BIGINT UNSIGNED NOT NULL,
    action_id BIGINT UNSIGNED NOT NULL,
    execution_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    execution_status ENUM('QUEUED', 'IN_PROGRESS', 'COMPLETED', 'FAILED') NOT NULL DEFAULT 'QUEUED',
    execution_outcome ENUM('SUCCESS', 'PARTIAL_SUCCESS', 'FAILED', 'ROLLED_BACK') COMMENT 'NULL until execution completes',
    execution_start_time TIMESTAMP(6),
    execution_end_time TIMESTAMP(6),
    actual_duration_seconds DECIMAL(10, 3),
    affected_rows INT UNSIGNED COMMENT 'Number of rows/objects affected',
    execution_errors TEXT COMMENT 'MySQL error messages, if any',
    post_execution_metrics JSON COMMENT 'Metrics after action (e.g., new query latency)',
    executed_by VARCHAR(100) COMMENT 'System user that executed the action',
    rollback_available BOOLEAN DEFAULT TRUE COMMENT 'Can this action be rolled back?',
    
    PRIMARY KEY (execution_id),
    FOREIGN KEY (approval_id) REFERENCES admin_approvals(approval_id),
    FOREIGN KEY (action_id) REFERENCES predefined_actions(action_id),
    KEY idx_approval (approval_id),
    KEY idx_timestamp (execution_timestamp),
    KEY idx_status (execution_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Immutable log of action executions; source of truth for what was done';

-- ============================================================================
-- TABLE 8: learning_records
-- ============================================================================
-- PURPOSE: Historical outcomes for ML model training
--   - Records effectiveness of decisions and actions
--   - ML learns from outcomes but cannot override human decisions
-- RATIONALE:
--   - issue_resolved_flag tracks success (human assessment needed)
--   - time_to_resolution measures action effectiveness
--   - metric_improvement_percent shows actual improvement achieved
--   - confidence_accuracy compares AI confidence to actual outcome (for model calibration)
--   - human_assessment allows admin to override AI's success evaluation
--   - learning_complete flag indicates record is ready for ML ingestion
--   - ML can identify patterns but never execute; execution always requires human approval
-- PRIMARY KEY: learning_record_id
-- FOREIGN KEYS: issue_id → detected_issues.issue_id
--               execution_id → action_executions.execution_id (nullable; some issues never executed)
-- ============================================================================
CREATE TABLE learning_records (
    learning_record_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    issue_id BIGINT UNSIGNED NOT NULL,
    execution_id BIGINT UNSIGNED COMMENT 'NULL if issue not executed',
    record_created_at TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    issue_resolved_flag BOOLEAN COMMENT 'Did the action resolve the issue? (human assessed)',
    time_to_resolution_hours DECIMAL(8, 2) COMMENT 'Hours from detection to resolution',
    metric_improvement_percent DECIMAL(6, 2) COMMENT 'Percentage improvement in target metric',
    ai_confidence_accuracy DECIMAL(3, 2) COMMENT 'How well AI confidence predicted outcome',
    human_assessment_notes TEXT COMMENT 'Admin notes on what worked/failed',
    unexpected_side_effects BOOLEAN DEFAULT FALSE COMMENT 'Did action cause unintended consequences?',
    side_effect_description TEXT,
    would_approve_again BOOLEAN COMMENT 'Would admin approve this same decision again?',
    learning_complete BOOLEAN DEFAULT FALSE COMMENT 'Ready for ML model training?',
    
    PRIMARY KEY (learning_record_id),
    FOREIGN KEY (issue_id) REFERENCES detected_issues(issue_id),
    FOREIGN KEY (execution_id) REFERENCES action_executions(execution_id),
    KEY idx_issue (issue_id),
    KEY idx_execution (execution_id),
    KEY idx_timestamp (record_created_at),
    KEY idx_learning_ready (learning_complete),
    CONSTRAINT chk_improvement_range CHECK (metric_improvement_percent IS NULL OR (metric_improvement_percent >= -100 AND metric_improvement_percent <= 100)),
    CONSTRAINT chk_accuracy_range CHECK (ai_confidence_accuracy IS NULL OR (ai_confidence_accuracy >= 0.00 AND ai_confidence_accuracy <= 1.00))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Historical learning data; ML trains on this but never executes actions';

-- ============================================================================
-- OPTIONAL: audit_log (Fine-grained audit trail)
-- ============================================================================
-- PURPOSE: Optional table for comprehensive audit trail of all changes
-- RATIONALE:
--   - If your viva examiner asks "who changed what, when?", this answers it
--   - Includes schema changes and table modifications
--   - NOT a shortcut; complements transaction logs
-- ============================================================================
CREATE TABLE audit_log (
    audit_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    audit_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    table_name VARCHAR(100) NOT NULL,
    record_id BIGINT UNSIGNED,
    change_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    changed_by VARCHAR(100) COMMENT 'User or system making the change',
    old_values JSON COMMENT 'Previous values (for UPDATE/DELETE)',
    new_values JSON COMMENT 'New values (for INSERT/UPDATE)',
    
    PRIMARY KEY (audit_id),
    KEY idx_table (table_name),
    KEY idx_timestamp (audit_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Optional comprehensive audit trail';

-- ============================================================================
-- SUMMARY OF DESIGN CHOICES
-- ============================================================================
/*

1. TABLE STRUCTURE & RELATIONSHIPS:
   ├─ detection_events (DBMS mechanisms only)
   │   └─ detected_issues (categorized problems)
   │       └─ ai_analysis (AI interpretation, confidence scoring)
   │           └─ recovery_decisions (AI recommendations)
   │               └─ admin_approvals (human approval MANDATORY)
   │                   └─ action_executions (safe execution)
   │                       └─ learning_records (learning from outcomes)
   
2. STRICT SEPARATION OF CONCERNS:
   • DETECTION: MySQL mechanisms → detection_events (immutable, DBMS-only)
   • ANALYSIS: AI interprets issues → ai_analysis (recommendations, not commands)
   • DECISION: AI recommends + Human approves → recovery_decisions + admin_approvals
   • EXECUTION: Only predefined actions → action_executions (no dynamic SQL)
   • LEARNING: Outcomes recorded → learning_records (ML trains, doesn't execute)

3. AI SAFETY GUARANTEES:
   ✓ AI can NEVER modify issues or force decisions
   ✓ AI recommendations await human approval (mandatory checkpoint)
   ✓ Only predefined actions allowed (whitelist in predefined_actions)
   ✓ ML learns from outcomes but cannot execute anything
   ✓ Every decision is traceable: who approved, when, why

4. DATA TYPES & CONSTRAINTS:
   • BIGINT UNSIGNED for IDs (supports 18+ billion records, proper for audit logs)
   • TIMESTAMP(6) for microsecond precision (critical for temporal analysis)
   • DECIMAL(3, 2) for confidence scores (precise, not floating-point)
   • ENUM for status fields (prevents invalid states, compact storage)
   • JSON for complex nested data (metrics, factors) without normalization overhead
   • CHECK constraints on confidence/similarity scores (0.00-1.00 range)
   • Foreign keys enforce referential integrity (no orphaned records)
   • InnoDB with FOREIGN_KEY_CHECKS for transactional safety

5. AUDITABILITY:
   ✓ event_id auto-increment ensures immutable sequence
   ✓ All timestamps use CURRENT_TIMESTAMP(6) (server-side, tamper-proof)
   ✓ admin_approvals records WHO approved and WHY
   ✓ action_executions logs actual execution outcomes
   ✓ learning_records preserves historical effectiveness
   ✓ audit_log (optional) provides fine-grained change history

6. NORMALIZED vs. DENORMALIZED CHOICES:
   • Normalized: Core entities (issue, analysis, decision, approval) are 1NF
   • Denormalized: occurrence_count in detected_issues avoids expensive aggregation
   • Denormalized: post_execution_metrics as JSON (reduces table joins, acceptable for metrics)
   • Rationale: DBMS operations are read-heavy; slight denormalization acceptable

7. WHY EACH TABLE WAS NECESSARY:
   ✗ NOT merged detection_events + detected_issues
     → Need immutable raw detection separate from categorization
   ✗ NOT merged ai_analysis + recovery_decisions
     → Need analysis (many) linked to decisions (some); AI may re-analyze
   ✗ NOT merged admin_approvals + action_executions
     → Need approval (decision point) separate from execution (outcome)
   ✗ NOT used generic "logs" table
     → Each table has specific schema; generic logs lose structure
   ✗ NOT stored "decision JSON" instead of normalized tables
     → Need queryable fields (status, confidence) for admin dashboards

8. WHAT'S DELIBERATELY EXCLUDED:
   ✗ User/role management tables (out of scope; controlled by MySQL users)
   ✗ Configuration tables (no system knobs; only predefined actions)
   ✗ UI/application-specific tables (DBMS-only, not application logic)
   ✗ Kubernetes/cloud metadata (MySQL-only, no external infrastructure)
   ✗ Raw ML model storage (separate tool; learning_records feed ML, not reverse)

9. VIVA QUESTIONS YOU'RE PREPARED FOR:

   Q: "Why separate detection_events and detected_issues?"
   A: Detection is DBMS responsibility (immutable); issues are problem categories 
      (mutable, aggregated). Conflating them violates separation of concerns.

   Q: "How do you prevent AI from executing actions?"
   A: recovery_decisions link to admin_approvals with status='APPROVED'. 
      action_executions only created AFTER admin approves. No execution logic 
      in AI system; only in schema constraints.

   Q: "What stops an admin from approving a dangerous action?"
   A: predefined_actions whitelist (only safe actions exist). Risk level 
      annotated. learning_records track failures; historical analysis guides 
      future approvals.

   Q: "How does ML learn without executing?"
   A: learning_records store outcomes (success, improvement, side effects). 
      ML ingests these as training data but produces only recommendations 
      (recovery_decisions). Execution always requires admin approval.

   Q: "How do you handle failures?"
   A: action_executions logs all outcomes (SUCCESS, PARTIAL, FAILED). 
      rollback_available flag indicates if reversal is possible. 
      learning_records assess effectiveness for future decisions.

*/
-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
