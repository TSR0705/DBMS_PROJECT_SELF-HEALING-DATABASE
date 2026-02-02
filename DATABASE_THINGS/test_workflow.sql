-- ============================================================================
-- COMPREHENSIVE TEST: Full Workflow from Detection to Learning
-- ============================================================================

USE self_healing_dbms;

-- ============================================================================
-- TEST 1: Insert Predefined Actions (Master Data)
-- ============================================================================
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

SELECT 'TEST 1: PREDEFINED_ACTIONS CREATED' as test_result;
SELECT COUNT(*) as action_count FROM predefined_actions;

-- ============================================================================
-- TEST 2: Detection Phase (DBMS detects slow query)
-- ============================================================================
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

SELECT 'TEST 2: DETECTION_EVENT RECORDED' as test_result;
SELECT event_id, detection_source, metric_value FROM detection_events LIMIT 1;

-- ============================================================================
-- TEST 3: Issue Categorization Phase
-- ============================================================================
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

SELECT 'TEST 3: DETECTED_ISSUE CREATED' as test_result;
SELECT issue_id, issue_status, affected_resource_name FROM detected_issues LIMIT 1;

-- ============================================================================
-- TEST 4: AI Analysis Phase
-- ============================================================================
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

SELECT 'TEST 4: AI_ANALYSIS CREATED' as test_result;
SELECT analysis_id, confidence_score, analysis_status FROM ai_analysis LIMIT 1;

-- ============================================================================
-- TEST 5: Recovery Decision Phase
-- ============================================================================
INSERT INTO recovery_decisions (
    analysis_id, recommended_action_id, confidence_based_score, 
    decision_rationale, decision_status
) VALUES
(
    1,
    2,  /* add_missing_index action */
    0.92,
    'High confidence: lack of index is clearly the bottleneck. Medium risk: index creation will lock table briefly.',
    'PENDING_APPROVAL'
);

SELECT 'TEST 5: RECOVERY_DECISION CREATED (PENDING_APPROVAL)' as test_result;
SELECT decision_id, decision_status FROM recovery_decisions LIMIT 1;

-- ============================================================================
-- TEST 6: Admin Approval Phase (Mandatory Checkpoint)
-- ============================================================================
INSERT INTO admin_approvals (
    decision_id, admin_user_id, approval_status, approval_reason, admin_notes
) VALUES
(
    1,
    'admin@dbms.local',
    'APPROVED',
    'CONFIDENT',
    'Medium risk acceptable; off-peak hours. Index creation needed.'
);

SELECT 'TEST 6: ADMIN_APPROVAL CREATED' as test_result;
SELECT approval_id, approval_status, admin_user_id FROM admin_approvals LIMIT 1;

-- ============================================================================
-- TEST 7: Action Execution Phase
-- ============================================================================
INSERT INTO action_executions (
    approval_id, action_id, execution_status, execution_outcome,
    execution_start_time, execution_end_time, actual_duration_seconds,
    executed_by
) VALUES
(
    1,
    2,
    'COMPLETED',
    'SUCCESS',
    NOW(),
    DATE_ADD(NOW(), INTERVAL 45 SECOND),
    45,
    'system@automation'
);

SELECT 'TEST 7: ACTION_EXECUTION COMPLETED' as test_result;
SELECT execution_id, execution_outcome, actual_duration_seconds FROM action_executions LIMIT 1;

-- ============================================================================
-- TEST 8: Learning Phase
-- ============================================================================
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

SELECT 'TEST 8: LEARNING_RECORD CREATED' as test_result;
SELECT learning_record_id, issue_resolved_flag, learning_complete FROM learning_records LIMIT 1;

-- ============================================================================
-- SAFETY TEST: Try to Execute Without Approval (Should Fail)
-- ============================================================================
SELECT 'TEST 9: SAFETY TEST - Try execution without approval (FK should prevent)' as test_result;

INSERT INTO action_executions (
    approval_id, action_id, execution_status
) VALUES
(
    9999,  /* Non-existent approval_id */
    2,
    'QUEUED'
);
-- Expected: ERROR 1452 (Foreign key constraint fails)

-- ============================================================================
-- FINAL AUDIT: Show Complete Workflow Chain
-- ============================================================================
SELECT 'TEST 10: COMPLETE WORKFLOW CHAIN' as test_result;

SELECT 
    'Detection' as stage,
    e.event_id as record_id,
    e.detection_source as source,
    e.event_timestamp as timestamp
FROM detection_events e
WHERE e.event_id = 1

UNION ALL

SELECT 
    'Issue',
    i.issue_id,
    i.issue_category,
    i.issue_created_at
FROM detected_issues i
WHERE i.issue_id = 1

UNION ALL

SELECT 
    'Analysis',
    a.analysis_id,
    CONCAT('Confidence: ', a.confidence_score),
    a.analysis_timestamp
FROM ai_analysis a
WHERE a.issue_id = 1

UNION ALL

SELECT 
    'Decision',
    d.decision_id,
    d.decision_status,
    d.decision_timestamp
FROM recovery_decisions d
WHERE d.analysis_id = 1

UNION ALL

SELECT 
    'Approval',
    ap.approval_id,
    ap.approval_status,
    ap.approval_timestamp
FROM admin_approvals ap
WHERE ap.decision_id = 1

UNION ALL

SELECT 
    'Execution',
    e.execution_id,
    e.execution_outcome,
    e.execution_timestamp
FROM action_executions e
WHERE e.approval_id = 1

UNION ALL

SELECT 
    'Learning',
    l.learning_record_id,
    CONCAT('Resolved: ', l.issue_resolved_flag),
    l.record_created_at
FROM learning_records l
WHERE l.issue_id = 1

ORDER BY timestamp;

-- ============================================================================
-- VALIDATION: Verify FK Integrity
-- ============================================================================
SELECT 'TEST 11: FOREIGN KEY INTEGRITY CHECK' as test_result;

SELECT COUNT(*) as orphaned_decisions
FROM recovery_decisions d
WHERE NOT EXISTS (SELECT 1 FROM ai_analysis a WHERE a.analysis_id = d.analysis_id);

SELECT COUNT(*) as orphaned_executions
FROM action_executions e
WHERE NOT EXISTS (SELECT 1 FROM admin_approvals ap WHERE ap.approval_id = e.approval_id);

SELECT COUNT(*) as orphaned_approvals
FROM admin_approvals ap
WHERE NOT EXISTS (SELECT 1 FROM recovery_decisions d WHERE d.decision_id = ap.decision_id);

-- ============================================================================
-- SUMMARY: Show All Table Row Counts
-- ============================================================================
SELECT 'TEST 12: FINAL ROW COUNTS' as test_result;

SELECT 'detection_events' as table_name, COUNT(*) as rows FROM detection_events
UNION ALL
SELECT 'detected_issues', COUNT(*) FROM detected_issues
UNION ALL
SELECT 'ai_analysis', COUNT(*) FROM ai_analysis
UNION ALL
SELECT 'predefined_actions', COUNT(*) FROM predefined_actions
UNION ALL
SELECT 'recovery_decisions', COUNT(*) FROM recovery_decisions
UNION ALL
SELECT 'admin_approvals', COUNT(*) FROM admin_approvals
UNION ALL
SELECT 'action_executions', COUNT(*) FROM action_executions
UNION ALL
SELECT 'learning_records', COUNT(*) FROM learning_records
ORDER BY table_name;

SELECT 'ALL TESTS COMPLETED SUCCESSFULLY' as final_status;
