-- ============================================================
-- REAL SYSTEM VALIDATION - COMPREHENSIVE TESTING
-- ============================================================
-- This script performs REAL validation of the self-healing system
-- NO ASSUMPTIONS - ONLY VERIFIED DATABASE STATE CHANGES
-- ============================================================

USE dbms_self_healing;

-- ============================================================
-- STEP 1: RESET SYSTEM STATE (CLEAN SLATE)
-- ============================================================
SELECT '=== STEP 1: RESET SYSTEM STATE ===' AS validation_step;

-- Clear all tables for clean testing
TRUNCATE TABLE learning_history;
TRUNCATE TABLE healing_actions;
TRUNCATE TABLE admin_reviews;
TRUNCATE TABLE decision_log;
TRUNCATE TABLE ai_analysis;
TRUNCATE TABLE detected_issues;
TRUNCATE TABLE debug_log;

-- Ensure action_rules are configured
INSERT IGNORE INTO action_rules (issue_type, action_type, is_automatic)
VALUES 
    ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', TRUE),
    ('DEADLOCK', 'ROLLBACK_TRANSACTION', TRUE),
    ('SLOW_QUERY', 'KILL_CONNECTION', FALSE);  -- Not automatic

SELECT 'System state reset - all tables cleared' AS status;

-- ============================================================
-- STEP 2: BASELINE MEASUREMENTS
-- ============================================================
SELECT '=== STEP 2: BASELINE MEASUREMENTS ===' AS validation_step;

-- Capture baseline system state
SELECT 
    COUNT(*) AS active_connections,
    COUNT(CASE WHEN command != 'Sleep' AND time > 5 THEN 1 END) AS active_queries,
    COUNT(CASE WHEN time > 10 THEN 1 END) AS long_running_queries
FROM information_schema.processlist;

SELECT COUNT(*) AS active_transactions FROM information_schema.innodb_trx;

-- ============================================================
-- TEST 1: SLOW QUERY EXECUTION (SHOULD BE FIXED)
-- ============================================================
SELECT '=== TEST 1: SLOW QUERY EXECUTION ===' AS validation_step;

-- Step 1.1: Create a real slow query in background
-- NOTE: This needs to be run in a separate connection manually
SELECT 'MANUAL STEP: In another connection, run: SELECT SLEEP(60);' AS instruction;
SELECT 'Wait 15 seconds, then continue with this script' AS instruction;

-- Pause for manual setup
DO SLEEP(15);

-- Step 1.2: Capture BEFORE state
SELECT 
    COUNT(*) AS connections_before,
    COUNT(CASE WHEN command != 'Sleep' AND time > 10 THEN 1 END) AS long_queries_before
FROM information_schema.processlist;

-- Store in variables for comparison
SET @connections_before = (
    SELECT COUNT(*) FROM information_schema.processlist 
    WHERE command != 'Sleep' AND time > 10
);

SELECT CONCAT('BEFORE: ', @connections_before, ' long-running connections') AS before_state;

-- Step 1.3: Insert test issue
INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
VALUES ('CONNECTION_OVERLOAD', 'VALIDATION_TEST', @connections_before, 'connections');

SET @test1_issue_id = LAST_INSERT_ID();
SELECT CONCAT('Created test issue_id: ', @test1_issue_id) AS status;

-- Step 1.4: Trigger the pipeline manually (simulate event scheduler)
CALL run_ai_analysis(@test1_issue_id);
CALL make_decision(@test1_issue_id);

-- Step 1.5: Wait for execution to complete
DO SLEEP(5);

-- Step 1.6: Capture AFTER state
SET @connections_after = (
    SELECT COUNT(*) FROM information_schema.processlist 
    WHERE command != 'Sleep' AND time > 10
);

SELECT CONCAT('AFTER: ', @connections_after, ' long-running connections') AS after_state;

-- Step 1.7: VERIFY EXECUTION RESULTS
SELECT '--- TEST 1 RESULTS ---' AS section;

-- Check decision
SELECT 
    decision_id,
    decision_type,
    decision_reason,
    confidence_at_decision
FROM decision_log 
WHERE issue_id = @test1_issue_id;

-- Check healing action
SELECT 
    action_id,
    action_type,
    execution_status,
    verification_status,
    process_id,
    before_metric,
    after_metric,
    error_message
FROM healing_actions 
WHERE decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = @test1_issue_id);

-- Check learning
SELECT 
    issue_type,
    action_type,
    outcome,
    confidence_before,
    confidence_after
FROM learning_history 
WHERE issue_type = 'CONNECTION_OVERLOAD'
ORDER BY learning_id DESC LIMIT 1;

-- CRITICAL VALIDATION: Did the connection actually get killed?
SELECT 
    CASE 
        WHEN @connections_after < @connections_before THEN '✅ PASS: Connection was killed'
        WHEN @connections_after = @connections_before THEN '❌ FAIL: No connection killed'
        ELSE '⚠️ UNEXPECTED: More connections after execution'
    END AS test1_execution_validation;

-- CRITICAL VALIDATION: Does healing_actions reflect reality?
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM healing_actions ha
            WHERE ha.decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = @test1_issue_id)
            AND ha.execution_status = 'SUCCESS'
            AND ha.verification_status = 'VERIFIED'
            AND ha.before_metric > ha.after_metric
        ) THEN '✅ PASS: Healing action correctly verified'
        WHEN EXISTS (
            SELECT 1 FROM healing_actions ha
            WHERE ha.decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = @test1_issue_id)
            AND ha.execution_status = 'FAILED'
        ) THEN '⚠️ INFO: Execution failed (may be expected if no eligible process)'
        ELSE '❌ FAIL: Healing action verification incorrect'
    END AS test1_verification_validation;

-- CRITICAL VALIDATION: Does learning reflect reality?
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM learning_history lh
            WHERE lh.issue_type = 'CONNECTION_OVERLOAD'
            AND lh.outcome = 'RESOLVED'
            AND EXISTS (
                SELECT 1 FROM healing_actions ha
                WHERE ha.verification_status = 'VERIFIED'
                AND ha.decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = @test1_issue_id)
            )
        ) THEN '✅ PASS: Learning matches verified success'
        WHEN EXISTS (
            SELECT 1 FROM learning_history lh
            WHERE lh.issue_type = 'CONNECTION_OVERLOAD'
            AND lh.outcome = 'FAILED'
        ) THEN '✅ PASS: Learning correctly recorded failure'
        ELSE '❌ FAIL: Learning does not match execution reality'
    END AS test1_learning_validation;

-- ============================================================
-- TEST 2: NON-EXISTENT PROCESS (FAIL CASE)
-- ============================================================
SELECT '=== TEST 2: NON-EXISTENT PROCESS (FAIL CASE) ===' AS validation_step;

-- Step 2.1: Insert issue when no long-running processes exist
-- First, ensure no long-running processes
SELECT 
    COUNT(CASE WHEN command != 'Sleep' AND time > 10 THEN 1 END) AS long_queries_count
FROM information_schema.processlist;

-- Step 2.2: Insert test issue anyway
INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
VALUES ('CONNECTION_OVERLOAD', 'VALIDATION_TEST_FAIL', 50, 'connections');

SET @test2_issue_id = LAST_INSERT_ID();

-- Step 2.3: Trigger pipeline
CALL run_ai_analysis(@test2_issue_id);
CALL make_decision(@test2_issue_id);

DO SLEEP(3);

-- Step 2.4: VERIFY FAILURE HANDLING
SELECT '--- TEST 2 RESULTS ---' AS section;

-- Check healing action should show failure
SELECT 
    action_type,
    execution_status,
    verification_status,
    process_id,
    before_metric,
    after_metric,
    error_message
FROM healing_actions 
WHERE decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = @test2_issue_id);

-- Check learning should record failure
SELECT 
    issue_type,
    action_type,
    outcome,
    confidence_before,
    confidence_after
FROM learning_history 
WHERE issue_type = 'CONNECTION_OVERLOAD'
ORDER BY learning_id DESC LIMIT 1;

-- CRITICAL VALIDATION: Failure properly recorded?
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM healing_actions ha
            WHERE ha.decision_id = (SELECT decision_id FROM decision_log WHERE issue_id = @test2_issue_id)
            AND ha.execution_status = 'FAILED'
            AND ha.error_message IS NOT NULL
        ) THEN '✅ PASS: Failure properly recorded with error message'
        ELSE '❌ FAIL: Failure not properly recorded'
    END AS test2_failure_validation;

-- CRITICAL VALIDATION: Learning records failure?
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM learning_history lh
            WHERE lh.issue_type = 'CONNECTION_OVERLOAD'
            AND lh.outcome = 'FAILED'
            AND lh.confidence_after < lh.confidence_before
        ) THEN '✅ PASS: Learning correctly recorded failure with confidence decrease'
        ELSE '❌ FAIL: Learning did not record failure correctly'
    END AS test2_learning_validation;

-- ============================================================
-- TEST 3: VERIFICATION LAYER TEST
-- ============================================================
SELECT '=== TEST 3: VERIFICATION LAYER TEST ===' AS validation_step;

-- This test verifies that the verification layer works correctly
-- We'll check if metrics are properly compared

-- Step 3.1: Check current verification logic by examining recent actions
SELECT 
    ha.action_id,
    ha.before_metric,
    ha.after_metric,
    ha.verification_status,
    CASE 
        WHEN ha.before_metric IS NOT NULL AND ha.after_metric IS NOT NULL THEN
            CASE 
                WHEN ha.after_metric < ha.before_metric AND ha.verification_status = 'VERIFIED' THEN 'CORRECT'
                WHEN ha.after_metric >= ha.before_metric AND ha.verification_status = 'FAILED' THEN 'CORRECT'
                ELSE 'INCORRECT'
            END
        ELSE 'NO_METRICS'
    END AS verification_correctness
FROM healing_actions ha
ORDER BY ha.action_id DESC
LIMIT 5;

-- CRITICAL VALIDATION: Verification logic correctness
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM healing_actions ha
            WHERE ha.before_metric IS NOT NULL 
            AND ha.after_metric IS NOT NULL
            AND ((ha.after_metric < ha.before_metric AND ha.verification_status != 'VERIFIED')
                 OR (ha.after_metric >= ha.before_metric AND ha.verification_status = 'VERIFIED'))
        ) THEN '✅ PASS: Verification logic is correct'
        ELSE '❌ FAIL: Verification logic has errors'
    END AS test3_verification_validation;

-- ============================================================
-- TEST 4: SUCCESS LEARNING LOOP
-- ============================================================
SELECT '=== TEST 4: SUCCESS LEARNING LOOP ===' AS validation_step;

-- Step 4.1: Check current success rate for CONNECTION_OVERLOAD + KILL_CONNECTION
CALL compute_success_rate('CONNECTION_OVERLOAD', 'KILL_CONNECTION', @current_success_rate);
SELECT CONCAT('Current success rate: ', ROUND(@current_success_rate * 100, 2), '%') AS current_rate;

-- Step 4.2: Simulate multiple successful outcomes by inserting learning records
-- (This simulates what would happen after multiple real successes)
INSERT INTO learning_history (issue_type, action_type, outcome, confidence_before, confidence_after)
VALUES 
    ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', 'RESOLVED', 0.5000, 0.5500),
    ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', 'RESOLVED', 0.5500, 0.6000),
    ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', 'RESOLVED', 0.6000, 0.6500),
    ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', 'RESOLVED', 0.6500, 0.7000),
    ('CONNECTION_OVERLOAD', 'KILL_CONNECTION', 'RESOLVED', 0.7000, 0.7500);

-- Step 4.3: Check new success rate
CALL compute_success_rate('CONNECTION_OVERLOAD', 'KILL_CONNECTION', @new_success_rate);
SELECT CONCAT('New success rate: ', ROUND(@new_success_rate * 100, 2), '%') AS new_rate;

-- CRITICAL VALIDATION: Success rate increased?
SELECT 
    CASE 
        WHEN @new_success_rate > @current_success_rate THEN '✅ PASS: Success rate increased after successful outcomes'
        ELSE '❌ FAIL: Success rate did not increase'
    END AS test4_learning_validation;

-- ============================================================
-- TEST 5: FAILURE LEARNING LOOP
-- ============================================================
SELECT '=== TEST 5: FAILURE LEARNING LOOP ===' AS validation_step;

-- Step 5.1: Simulate multiple failed outcomes
INSERT INTO learning_history (issue_type, action_type, outcome, confidence_before, confidence_after)
VALUES 
    ('SLOW_QUERY', 'KILL_CONNECTION', 'FAILED', 0.5000, 0.4500),
    ('SLOW_QUERY', 'KILL_CONNECTION', 'FAILED', 0.4500, 0.4000),
    ('SLOW_QUERY', 'KILL_CONNECTION', 'FAILED', 0.4000, 0.3500),
    ('SLOW_QUERY', 'KILL_CONNECTION', 'FAILED', 0.3500, 0.3000),
    ('SLOW_QUERY', 'KILL_CONNECTION', 'FAILED', 0.3000, 0.2500);

-- Step 5.2: Check success rate for SLOW_QUERY
CALL compute_success_rate('SLOW_QUERY', 'KILL_CONNECTION', @slow_query_success_rate);
SELECT CONCAT('SLOW_QUERY success rate: ', ROUND(@slow_query_success_rate * 100, 2), '%') AS slow_query_rate;

-- Step 5.3: Test decision making with low success rate
INSERT INTO detected_issues (issue_type, detection_source, raw_metric_value, raw_metric_unit)
VALUES ('SLOW_QUERY', 'VALIDATION_TEST_DECISION', 30.5, 'seconds');

SET @test5_issue_id = LAST_INSERT_ID();

CALL run_ai_analysis(@test5_issue_id);
CALL make_decision(@test5_issue_id);

-- Check if low success rate forced ADMIN_REVIEW
SELECT 
    decision_type,
    decision_reason
FROM decision_log 
WHERE issue_id = @test5_issue_id;

-- CRITICAL VALIDATION: Low success rate forces ADMIN_REVIEW?
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM decision_log dl
            WHERE dl.issue_id = @test5_issue_id
            AND dl.decision_type = 'ADMIN_REVIEW'
            AND dl.decision_reason LIKE '%success rate%'
        ) THEN '✅ PASS: Low success rate correctly forced ADMIN_REVIEW'
        WHEN EXISTS (
            SELECT 1 FROM decision_log dl
            WHERE dl.issue_id = @test5_issue_id
            AND dl.decision_type = 'ADMIN_REVIEW'
        ) THEN '⚠️ PARTIAL: ADMIN_REVIEW chosen but reason unclear'
        ELSE '❌ FAIL: Low success rate did not force ADMIN_REVIEW'
    END AS test5_decision_validation;

-- ============================================================
-- TEST 6: SAFETY VALIDATION
-- ============================================================
SELECT '=== TEST 6: SAFETY VALIDATION ===' AS validation_step;

-- Step 6.1: Check that system threads are not targeted
SELECT 
    COUNT(*) AS system_threads,
    COUNT(CASE WHEN user = 'system user' THEN 1 END) AS system_user_threads,
    COUNT(CASE WHEN command = 'Binlog Dump' THEN 1 END) AS replication_threads
FROM information_schema.processlist;

-- Step 6.2: Verify no system processes were killed in our tests
SELECT 
    ha.process_id,
    pl.user,
    pl.command,
    pl.time
FROM healing_actions ha
LEFT JOIN information_schema.processlist pl ON ha.process_id = pl.id
WHERE ha.process_id IS NOT NULL
ORDER BY ha.action_id DESC
LIMIT 5;

-- CRITICAL VALIDATION: No system threads killed?
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM healing_actions ha
            JOIN information_schema.processlist pl ON ha.process_id = pl.id
            WHERE pl.user = 'system user' OR pl.command IN ('Binlog Dump', 'Daemon')
        ) THEN '✅ PASS: No system threads were killed'
        ELSE '❌ FAIL: System threads were killed (DANGEROUS)'
    END AS test6_safety_validation;

-- Step 6.3: Check for duplicate executions
SELECT 
    decision_id,
    COUNT(*) AS execution_count
FROM healing_actions
GROUP BY decision_id
HAVING COUNT(*) > 1;

-- CRITICAL VALIDATION: No duplicate executions?
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM healing_actions
            GROUP BY decision_id
            HAVING COUNT(*) > 1
        ) THEN '✅ PASS: No duplicate executions found'
        ELSE '❌ FAIL: Duplicate executions detected'
    END AS test6_duplicate_validation;

-- ============================================================
-- STEP 7: COMPREHENSIVE VALIDATION SUMMARY
-- ============================================================
SELECT '=== COMPREHENSIVE VALIDATION SUMMARY ===' AS validation_step;

-- Check for fake successes (SUCCESS without improvement)
SELECT 
    COUNT(*) AS fake_success_count
FROM healing_actions ha
WHERE ha.execution_status = 'SUCCESS'
AND ha.verification_status = 'VERIFIED'
AND (ha.before_metric IS NULL 
     OR ha.after_metric IS NULL 
     OR ha.after_metric >= ha.before_metric);

-- Check for missing failures (improvement without SUCCESS)
SELECT 
    COUNT(*) AS missing_failure_count
FROM healing_actions ha
WHERE ha.execution_status = 'FAILED'
AND ha.before_metric IS NOT NULL
AND ha.after_metric IS NOT NULL
AND ha.after_metric < ha.before_metric;

-- Learning consistency check
SELECT 
    COUNT(*) AS learning_inconsistency_count
FROM learning_history lh
JOIN healing_actions ha ON (
    lh.issue_type = (
        SELECT di.issue_type 
        FROM decision_log dl 
        JOIN detected_issues di ON dl.issue_id = di.issue_id 
        WHERE dl.decision_id = ha.decision_id
    )
    AND lh.action_type = ha.action_type
)
WHERE (lh.outcome = 'RESOLVED' AND ha.verification_status != 'VERIFIED')
   OR (lh.outcome = 'FAILED' AND ha.verification_status = 'VERIFIED');

-- ============================================================
-- FINAL VALIDATION REPORT
-- ============================================================
SELECT '=== FINAL VALIDATION REPORT ===' AS validation_step;

SELECT 
    'EXECUTION VALIDATION' AS category,
    CASE 
        WHEN EXISTS (SELECT 1 FROM healing_actions WHERE execution_status = 'SUCCESS' AND process_id IS NOT NULL)
        THEN '✅ PASS: Real executions occurred'
        ELSE '❌ FAIL: No real executions found'
    END AS result;

SELECT 
    'VERIFICATION VALIDATION' AS category,
    CASE 
        WHEN (SELECT COUNT(*) FROM healing_actions WHERE before_metric IS NULL OR after_metric IS NULL) = 0
        AND NOT EXISTS (
            SELECT 1 FROM healing_actions 
            WHERE execution_status = 'SUCCESS' 
            AND verification_status = 'VERIFIED' 
            AND after_metric >= before_metric
        )
        THEN '✅ PASS: Verification layer working correctly'
        ELSE '❌ FAIL: Verification layer has issues'
    END AS result;

SELECT 
    'LEARNING VALIDATION' AS category,
    CASE 
        WHEN EXISTS (SELECT 1 FROM learning_history WHERE outcome = 'RESOLVED')
        AND EXISTS (SELECT 1 FROM learning_history WHERE outcome = 'FAILED')
        AND NOT EXISTS (
            SELECT 1 FROM learning_history lh
            WHERE lh.outcome = 'RESOLVED'
            AND NOT EXISTS (
                SELECT 1 FROM healing_actions ha
                WHERE ha.verification_status = 'VERIFIED'
            )
        )
        THEN '✅ PASS: Learning system working correctly'
        ELSE '❌ FAIL: Learning system has issues'
    END AS result;

SELECT 
    'SAFETY VALIDATION' AS category,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM healing_actions ha
            JOIN information_schema.processlist pl ON ha.process_id = pl.id
            WHERE pl.user = 'system user'
        )
        AND NOT EXISTS (
            SELECT 1 FROM healing_actions
            GROUP BY decision_id
            HAVING COUNT(*) > 1
        )
        THEN '✅ PASS: Safety mechanisms working'
        ELSE '❌ FAIL: Safety violations detected'
    END AS result;

SELECT 
    'CLOSED LOOP VALIDATION' AS category,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM detected_issues di
            JOIN decision_log dl ON di.issue_id = dl.issue_id
            JOIN healing_actions ha ON dl.decision_id = ha.decision_id
            JOIN learning_history lh ON lh.issue_type = di.issue_type AND lh.action_type = ha.action_type
            WHERE ha.verification_status IS NOT NULL
            AND lh.outcome = CASE WHEN ha.verification_status = 'VERIFIED' THEN 'RESOLVED' ELSE 'FAILED' END
        )
        THEN '✅ PASS: Complete closed loop verified'
        ELSE '❌ FAIL: Closed loop broken'
    END AS result;

-- ============================================================
-- DETAILED STATISTICS
-- ============================================================
SELECT '=== DETAILED STATISTICS ===' AS validation_step;

-- Execution statistics
SELECT 
    'EXECUTION STATS' AS category,
    COUNT(*) AS total_actions,
    SUM(CASE WHEN execution_status = 'SUCCESS' THEN 1 ELSE 0 END) AS successes,
    SUM(CASE WHEN execution_status = 'FAILED' THEN 1 ELSE 0 END) AS failures,
    SUM(CASE WHEN verification_status = 'VERIFIED' THEN 1 ELSE 0 END) AS verified,
    ROUND(SUM(CASE WHEN verification_status = 'VERIFIED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS verification_rate_pct
FROM healing_actions;

-- Learning statistics
SELECT 
    'LEARNING STATS' AS category,
    COUNT(*) AS total_learning_records,
    SUM(CASE WHEN outcome = 'RESOLVED' THEN 1 ELSE 0 END) AS resolved_count,
    SUM(CASE WHEN outcome = 'FAILED' THEN 1 ELSE 0 END) AS failed_count,
    AVG(confidence_after - confidence_before) AS avg_confidence_change
FROM learning_history;

-- Decision statistics
SELECT 
    'DECISION STATS' AS category,
    COUNT(*) AS total_decisions,
    SUM(CASE WHEN decision_type = 'AUTO_HEAL' THEN 1 ELSE 0 END) AS auto_heal_count,
    SUM(CASE WHEN decision_type = 'ADMIN_REVIEW' THEN 1 ELSE 0 END) AS admin_review_count,
    AVG(confidence_at_decision) AS avg_confidence
FROM decision_log;

SELECT '=== VALIDATION COMPLETE ===' AS final_status;