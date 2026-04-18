/*!40101 SET NAMES utf8mb4 */;
USE dbms_self_healing;
-- Step 1
SELECT 'STEP 1: Verify Automation Layer' as step;
SHOW VARIABLES LIKE 'event_scheduler';
SELECT EVENT_NAME, STATUS 
FROM INFORMATION_SCHEMA.EVENTS 
WHERE EVENT_NAME = 'evt_auto_heal_pipeline' AND EVENT_SCHEMA = 'dbms_self_healing';

-- Clean DB for precise testing
SET SQL_SAFE_UPDATES = 0;
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE healing_actions;
TRUNCATE TABLE decision_log;
TRUNCATE TABLE learning_history;
TRUNCATE TABLE admin_reviews;
TRUNCATE TABLE debug_log;
DELETE FROM ai_analysis;
DELETE FROM detected_issues;
SET FOREIGN_KEY_CHECKS = 1;

INSERT IGNORE INTO action_rules (issue_type, action_type, is_automatic) VALUES 
('SLOW_QUERY', 'KILL_CONNECTION', 1);

-- Force execution logic for debug tracing internally
SET @force_execution = TRUE;

-- Step 2
SELECT 'STEP 2: Insert Raw Test Data' as step;
INSERT INTO detected_issues (issue_id, issue_type, raw_metric_value, detected_at) VALUES 
(800, 'SLOW_QUERY', 50, NOW()),
(801, 'SLOW_QUERY', 9999, NOW()),
(802, 'SLOW_QUERY', 9999, NOW());

-- Step 3
SELECT 'STEP 3: Wait for automation' as step;
SELECT SLEEP(15);

-- Step 4
SELECT 'STEP 4: Verify Pipeline Execution counts' as step;
SELECT COUNT(*) as analysis_count FROM ai_analysis;
SELECT COUNT(*) as decision_count FROM decision_log;
SELECT COUNT(*) as healing_count FROM healing_actions;
SELECT COUNT(*) as learning_count FROM learning_history;

-- Step 5
SELECT 'STEP 5: Trace Full Pipeline' as step;
SELECT * FROM detected_issues WHERE issue_id = 801;
SELECT * FROM ai_analysis WHERE issue_id = 801;
SELECT * FROM decision_log WHERE issue_id = 801;
SELECT * FROM healing_actions WHERE decision_id = (SELECT decision_id FROM decision_log WHERE issue_id=801 LIMIT 1);
SELECT * FROM learning_history WHERE decision_id = (SELECT decision_id FROM decision_log WHERE issue_id=801 LIMIT 1);

-- Step 6
SELECT 'STEP 6: Duplication Test' as step;
SELECT decision_id, COUNT(*) as occurs FROM healing_actions GROUP BY decision_id HAVING occurs > 1;

-- Step 7
SELECT 'STEP 7: Concurrency Test' as step;
INSERT INTO detected_issues (issue_id, issue_type, raw_metric_value, detected_at) VALUES 
(2001, 'SLOW_QUERY', 100, NOW()), (2002, 'SLOW_QUERY', 100, NOW()), (2003, 'SLOW_QUERY', 100, NOW()),
(2004, 'SLOW_QUERY', 100, NOW()), (2005, 'SLOW_QUERY', 100, NOW()), (2006, 'SLOW_QUERY', 100, NOW()),
(2007, 'SLOW_QUERY', 100, NOW()), (2008, 'SLOW_QUERY', 100, NOW()), (2009, 'SLOW_QUERY', 100, NOW()),
(2010, 'SLOW_QUERY', 100, NOW()), (2011, 'SLOW_QUERY', 100, NOW()), (2012, 'SLOW_QUERY', 100, NOW()),
(2013, 'SLOW_QUERY', 100, NOW()), (2014, 'SLOW_QUERY', 100, NOW()), (2015, 'SLOW_QUERY', 100, NOW()),
(2016, 'SLOW_QUERY', 100, NOW()), (2017, 'SLOW_QUERY', 100, NOW()), (2018, 'SLOW_QUERY', 100, NOW()),
(2019, 'SLOW_QUERY', 100, NOW()), (2020, 'SLOW_QUERY', 100, NOW());

SELECT SLEEP(20);

SELECT COUNT(*) as issues_count FROM detected_issues;
SELECT COUNT(*) as ai_analyzed FROM ai_analysis;

-- Step 8
SELECT 'STEP 8: Lock Test (Critical)' as step;
SELECT * FROM debug_log WHERE step = 'pipeline_start' ORDER BY created_at DESC LIMIT 5;

-- Step 9
SELECT 'STEP 9: Execution Validity Test' as step;
SELECT execution_status, COUNT(*) as exec_counts FROM healing_actions GROUP BY execution_status;

-- Step 10
SELECT 'STEP 10: Learning Adaptation Test' as step;
INSERT INTO learning_history (decision_id, issue_type, action_type, outcome, confidence_before, confidence_after) VALUES 
(9001,'SLOW_QUERY','KILL_CONNECTION','FAILED',0.5,0.4), (9002,'SLOW_QUERY','KILL_CONNECTION','FAILED',0.4,0.3),
(9003,'SLOW_QUERY','KILL_CONNECTION','FAILED',0.3,0.2), (9004,'SLOW_QUERY','KILL_CONNECTION','FAILED',0.2,0.1),
(9005,'SLOW_QUERY','KILL_CONNECTION','FAILED',0.1,0.0), (9006,'SLOW_QUERY','KILL_CONNECTION','FAILED',0.1,0.0),
(9007,'SLOW_QUERY','KILL_CONNECTION','FAILED',0.1,0.0), (9008,'SLOW_QUERY','KILL_CONNECTION','FAILED',0.1,0.0);

INSERT INTO detected_issues (issue_id, issue_type, raw_metric_value, detected_at) VALUES (3001, 'SLOW_QUERY', 9999, NOW());
SELECT SLEEP(15);
SELECT decision_type, decision_reason FROM decision_log WHERE issue_id = 3001;

-- Step 11
SELECT 'STEP 11: Idempotency Validation' as step;
SELECT issue_id, COUNT(*) as idemp_count FROM ai_analysis GROUP BY issue_id HAVING idemp_count > 1;

-- Step 12
SELECT 'STEP 12: System Health Check' as step;
SELECT * FROM debug_log ORDER BY id DESC LIMIT 20;
