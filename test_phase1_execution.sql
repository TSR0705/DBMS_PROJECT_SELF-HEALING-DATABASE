-- ============================================================
-- PHASE 1 TESTING SCRIPT
-- Test real execution with verification
-- ============================================================

USE dbms_self_healing;

-- ============================================================
-- STEP 1: VERIFY DEPLOYMENT
-- ============================================================
SELECT '=== STEP 1: VERIFY DEPLOYMENT ===' AS test_step;

-- Check new columns exist
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    IS_NULLABLE,
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'healing_actions'
  AND COLUMN_NAME IN ('before_metric', 'after_metric', 'verification_status', 'process_id', 'error_message')
ORDER BY COLUMN_NAME;

-- Check procedures exist
SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED,
    LAST_ALTERED
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE()
  AND ROUTINE_NAME IN ('execute_healing_action_v2', 'update_learning_v2', 'execute_healing_action', 'update_learning')
ORDER BY ROUTINE_NAME;

-- ============================================================
-- STEP 2: SETUP TEST DATA
-- ============================================================
SELECT '=== STEP 2: SETUP TEST DATA ===' AS test_step;

-- Ensure action_rules table has test rules
INSERT IGNORE INTO action_rules (issue_type, action_type, is_automatic)
VALUES 
    ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', TRUE),
    ('DEADLOCK', 'ROLLBACK_TRANSACTION', TRUE),
    ('SLOW_QUERY', 'KILL_CONNECTION', FALSE);  -- Not automatic

SELECT 'Action rules configured' AS status;

-- ============================================================
-- STEP 3: TEST SCENARIO 1 - KILL_CONNECTION (Should Execute)
-- ============================================================
SELECT '=== STEP 3: TEST KILL_CONNECTION ===' AS test_step;

-- Clear debug log for clean test
TRUNCATE TABLE debug_log;

-- Insert test issue
INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
VALUES ('CONNECTION_OVERLOAD', 'TEST_PHASE1', 100, 'connections');

SET @test_issue_id = LAST_INSERT_ID();
SELECT CONCAT('Created test issue_id: ', @test_issue_id) AS status;

-- Run AI analysis
CALL run_ai_analysis(@test_issue_id);
SELECT 'AI analysis completed' AS status;

-- Run decision (which will trigger execution and learning)
CALL make_decision(@test_issue_id);
SELECT 'Decision completed' AS status;

-- Wait a moment for async processing
DO SLEEP(1);

-- Check results
SELECT '--- Decision Log ---' AS section;
SELECT 
    decision_id,
    issue_id,
    decision_type,
    decision_reason,
    confidence_at_decision,
    decided_at
FROM decision_log
WHERE issue_id = @test_issue_id;

SELECT '--- Healing Action ---' AS section;
SELECT 
    action_id,
    decision_id,
    action_type,
    execution_mode,
    executed_by,
    execution_status,
    verification_status,
    process_id,
    before_metric,
    after_metric,
    error_message,
    executed_at
FROM healing_actions
WHERE decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = @test_issue_id);

SELECT '--- Learning History ---' AS section;
SELECT 
    learning_id,
    issue_type,
    action_type,
    outcome,
    confidence_before,
    confidence_after,
    (confidence_after - confidence_before) AS confidence_change,
    recorded_at
FROM learning_history
WHERE issue_type = 'CONNECTION_OVERLOAD'
ORDER BY learning_id DESC
LIMIT 1;

SELECT '--- Debug Log ---' AS section;
SELECT 
    step,
    message,
    created_at
FROM debug_log
ORDER BY id DESC
LIMIT 20;

-- ============================================================
-- STEP 4: TEST SCENARIO 2 - ADMIN_REVIEW (Should Skip)
-- ============================================================
SELECT '=== STEP 4: TEST ADMIN_REVIEW (Should Skip) ===' AS test_step;

-- Clear debug log
TRUNCATE TABLE debug_log;

-- Insert test issue for SLOW_QUERY (not automatic)
INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
VALUES ('SLOW_QUERY', 'TEST_PHASE1', 45.5, 'seconds');

SET @test_issue_id2 = LAST_INSERT_ID();
SELECT CONCAT('Created test issue_id: ', @test_issue_id2) AS status;

-- Run AI analysis
CALL run_ai_analysis(@test_issue_id2);

-- Run decision
CALL make_decision(@test_issue_id2);

-- Check results
SELECT '--- Decision Log ---' AS section;
SELECT 
    decision_id,
    issue_id,
    decision_type,
    decision_reason
FROM decision_log
WHERE issue_id = @test_issue_id2;

SELECT '--- Healing Action (Should be empty or skipped) ---' AS section;
SELECT 
    action_id,
    action_type,
    execution_status,
    verification_status
FROM healing_actions
WHERE decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = @test_issue_id2);

SELECT '--- Debug Log ---' AS section;
SELECT 
    step,
    message
FROM debug_log
WHERE step LIKE 'exec%'
ORDER BY id DESC
LIMIT 10;

-- ============================================================
-- STEP 5: STATISTICS
-- ============================================================
SELECT '=== STEP 5: STATISTICS ===' AS test_step;

-- Overall execution statistics
SELECT 
    action_type,
    execution_mode,
    executed_by,
    COUNT(*) AS total_executions,
    SUM(CASE WHEN execution_status = 'SUCCESS' THEN 1 ELSE 0 END) AS successes,
    SUM(CASE WHEN execution_status = 'FAILED' THEN 1 ELSE 0 END) AS failures,
    SUM(CASE WHEN verification_status = 'VERIFIED' THEN 1 ELSE 0 END) AS verified,
    SUM(CASE WHEN verification_status = 'FAILED' THEN 1 ELSE 0 END) AS verification_failed,
    ROUND(SUM(CASE WHEN verification_status = 'VERIFIED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS verification_rate_pct
FROM healing_actions
WHERE executed_by IN ('SYSTEM_V2', 'SYSTEM')
GROUP BY action_type, execution_mode, executed_by
ORDER BY total_executions DESC;

-- Learning outcomes
SELECT 
    issue_type,
    action_type,
    outcome,
    COUNT(*) AS count,
    AVG(confidence_after - confidence_before) AS avg_confidence_change
FROM learning_history
GROUP BY issue_type, action_type, outcome
ORDER BY count DESC;

-- Recent executions with full details
SELECT 
    ha.action_id,
    ha.action_type,
    ha.execution_status,
    ha.verification_status,
    ha.process_id,
    ha.before_metric,
    ha.after_metric,
    CASE 
        WHEN ha.before_metric IS NOT NULL AND ha.after_metric IS NOT NULL 
        THEN ROUND((ha.before_metric - ha.after_metric) / ha.before_metric * 100, 2)
        ELSE NULL
    END AS improvement_pct,
    ha.error_message,
    ha.executed_at
FROM healing_actions ha
WHERE ha.executed_by = 'SYSTEM_V2'
ORDER BY ha.executed_at DESC
LIMIT 10;

-- ============================================================
-- STEP 6: VALIDATION SUMMARY
-- ============================================================
SELECT '=== STEP 6: VALIDATION SUMMARY ===' AS test_step;

SELECT 
    'PHASE 1 TESTING COMPLETE' AS status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM healing_actions WHERE executed_by = 'SYSTEM_V2') 
        THEN '✅ Real execution working'
        ELSE '❌ No real executions found'
    END AS execution_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM healing_actions WHERE verification_status IS NOT NULL) 
        THEN '✅ Verification layer active'
        ELSE '❌ Verification not working'
    END AS verification_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM learning_history WHERE recorded_at > NOW() - INTERVAL 5 MINUTE) 
        THEN '✅ Learning system active'
        ELSE '⚠️ No recent learning records'
    END AS learning_status;

-- ============================================================
-- CLEANUP (Optional - uncomment to clean test data)
-- ============================================================
-- DELETE FROM detected_issues WHERE detection_source = 'TEST_PHASE1';
-- DELETE FROM ai_analysis WHERE issue_id IN (SELECT issue_id FROM detected_issues WHERE detection_source = 'TEST_PHASE1');
-- DELETE FROM decision_log WHERE issue_id IN (SELECT issue_id FROM detected_issues WHERE detection_source = 'TEST_PHASE1');
-- TRUNCATE TABLE debug_log;

SELECT '=== TESTING COMPLETE ===' AS final_message;
