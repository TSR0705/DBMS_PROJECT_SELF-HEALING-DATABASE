DELETE FROM ai_analysis WHERE issue_id BETWEEN 777000 AND 777999;
DELETE FROM detected_issues WHERE issue_id BETWEEN 777000 AND 777999;

SELECT '--- STEP 1: INITIAL STATE (Empty) ---' AS status;
SELECT * FROM detected_issues WHERE issue_id BETWEEN 777000 AND 777999;
SELECT * FROM ai_analysis WHERE issue_id BETWEEN 777000 AND 777999;

SELECT '--- STEP 2: AN ISSUE TRIPS IN THE SYSTEM ---' AS status;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) 
VALUES (777001, 'DEADLOCK', 'INNODB', 85.0, '%', NOW());

SELECT 'Raw Issue table now has 1 unanalyzed event:' AS status;
SELECT issue_id, issue_type, raw_metric_value, detected_at FROM detected_issues WHERE issue_id = 777001;

SELECT 'Wait, AI Analysis table is still empty because the pipeline has not processed it yet.' AS note;
SELECT issue_id, severity_level FROM ai_analysis WHERE issue_id = 777001;

SELECT '--- STEP 3: PIPELINE EXECUTION ---' AS status;
SELECT 'Triggering the Engine: CALL run_ai_analysis(777001)...' AS action;
CALL run_ai_analysis(777001);

SELECT '--- STEP 4: FINAL DECISION LOGGED ---' AS status;
SELECT issue_id, severity_level, baseline_metric, severity_ratio as confidence_ratio_logged FROM ai_analysis WHERE issue_id = 777001;

SELECT '--- STEP 5: CREATING A BASELINE HISTORICAL DRIFT ---' AS status;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(777002, 'DEADLOCK', 'INNODB', 87.0, '%', NOW() - INTERVAL 5 HOUR),
(777003, 'DEADLOCK', 'INNODB', 88.0, '%', NOW() - INTERVAL 4 HOUR),
(777004, 'DEADLOCK', 'INNODB', 91.0, '%', NOW() - INTERVAL 3 HOUR);
CALL run_ai_analysis(777002); CALL run_ai_analysis(777003); CALL run_ai_analysis(777004);

SELECT 'Notice how baseline_metric continuously adapts upwards as issues flow:' AS status;
SELECT d.issue_id, d.raw_metric_value, a.baseline_metric, a.severity_level 
FROM detected_issues d JOIN ai_analysis a ON d.issue_id = a.issue_id 
WHERE d.issue_id BETWEEN 777002 AND 777004 ORDER BY d.issue_id;

SELECT '--- STEP 6: EXTREME OUTLIER HITS THE EXISTING BASELINE ---' AS status;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) 
VALUES (777005, 'DEADLOCK', 'INNODB', 1500.0, '%', NOW());
CALL run_ai_analysis(777005);

SELECT 'Final AI Analysis Table intercepts the hit:' AS status;
SELECT issue_id, severity_level, baseline_metric, severity_ratio FROM ai_analysis WHERE issue_id = 777005;
