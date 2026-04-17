DELETE FROM ai_analysis WHERE issue_id LIKE '997%';
DELETE FROM detected_issues WHERE issue_id LIKE '997%';

SELECT '--- TEST 1: NORMAL DISTRIBUTION ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(997101, 'DEADLOCK', 'INNODB', 10.0, 'count', NOW() - INTERVAL 10 HOUR),
(997102, 'DEADLOCK', 'INNODB', 11.0, 'count', NOW() - INTERVAL 9 HOUR),
(997103, 'DEADLOCK', 'INNODB', 12.0, 'count', NOW() - INTERVAL 8 HOUR),
(997104, 'DEADLOCK', 'INNODB', 14.0, 'count', NOW() - INTERVAL 7 HOUR),
(997105, 'DEADLOCK', 'INNODB', 13.0, 'count', NOW() - INTERVAL 6 HOUR),
(997106, 'DEADLOCK', 'INNODB', 10.5, 'count', NOW() - INTERVAL 5 HOUR),
(997107, 'DEADLOCK', 'INNODB', 11.5, 'count', NOW() - INTERVAL 4 HOUR),
(997108, 'DEADLOCK', 'INNODB', 15.0, 'count', NOW() - INTERVAL 3 HOUR),
(997109, 'DEADLOCK', 'INNODB', 12.5, 'count', NOW() - INTERVAL 2 HOUR),
(997110, 'DEADLOCK', 'INNODB', 13.5, 'count', NOW() - INTERVAL 1 HOUR);

CALL run_ai_analysis(997101);
CALL run_ai_analysis(997102);
CALL run_ai_analysis(997103);
CALL run_ai_analysis(997104);
CALL run_ai_analysis(997105);
CALL run_ai_analysis(997106);
CALL run_ai_analysis(997107);
CALL run_ai_analysis(997108);
CALL run_ai_analysis(997109);
CALL run_ai_analysis(997110);

SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level
FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id
WHERE a.issue_id BETWEEN 997101 AND 997110 ORDER BY a.issue_id;


SELECT '--- TEST 2: EXTREME OUTLIER ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(997201, 'DEADLOCK', 'INNODB', 1000.0, 'count', NOW());
CALL run_ai_analysis(997201);

SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level
FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id
WHERE a.issue_id = 997201;


SELECT '--- TEST 3: DATA CONTAMINATION ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(997301, 'DEADLOCK', 'INNODB', 12.0, 'count', NOW());
CALL run_ai_analysis(997301);

SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level
FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id
WHERE a.issue_id = 997301;


SELECT '--- TEST 4: CONTEXT SEGMENTATION ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(997401, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 10.0, 'conn', NOW() - INTERVAL 10 HOUR),
(997402, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 12.0, 'conn', NOW() - INTERVAL 9 HOUR),
(997403, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 5000.0, 'conn', NOW() - INTERVAL 8 HOUR),
(997404, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 5200.0, 'conn', NOW() - INTERVAL 7 HOUR);

CALL run_ai_analysis(997401);
CALL run_ai_analysis(997402);
CALL run_ai_analysis(997403);
CALL run_ai_analysis(997404);

INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(997405, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 11.0, 'conn', NOW()),
(997406, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 5100.0, 'conn', NOW());

CALL run_ai_analysis(997405);
CALL run_ai_analysis(997406);

SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level
FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id
WHERE a.issue_id IN (997405, 997406) ORDER BY a.issue_id;


SELECT '--- TEST 5: CONSTANT DATA ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(997501, 'TRANSACTION_FAILURE', 'INNODB', 800.0, 'fails', NOW() - INTERVAL 5 HOUR),
(997502, 'TRANSACTION_FAILURE', 'INNODB', 800.0, 'fails', NOW() - INTERVAL 4 HOUR),
(997503, 'TRANSACTION_FAILURE', 'INNODB', 800.0, 'fails', NOW() - INTERVAL 3 HOUR),
(997504, 'TRANSACTION_FAILURE', 'INNODB', 800.0, 'fails', NOW() - INTERVAL 2 HOUR),
(997505, 'TRANSACTION_FAILURE', 'INNODB', 800.0, 'fails', NOW() - INTERVAL 1 HOUR),
(997506, 'TRANSACTION_FAILURE', 'INNODB', 800.0, 'fails', NOW());

CALL run_ai_analysis(997501);
CALL run_ai_analysis(997502);
CALL run_ai_analysis(997503);
CALL run_ai_analysis(997504);
CALL run_ai_analysis(997505);
CALL run_ai_analysis(997506);

SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level
FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id
WHERE a.issue_id = 997506;


SELECT '--- TEST 6: RAPID INSERTS ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(997601, 'SLOW_QUERY', 'SLOW_QUERY_LOG', 1.0, 'count', NOW());

CALL run_ai_analysis(997601);
CALL run_ai_analysis(997601);
CALL run_ai_analysis(997601);
CALL run_ai_analysis(997601);
CALL run_ai_analysis(997601);

SELECT issue_id, COUNT(*) AS analysis_count FROM ai_analysis WHERE issue_id = 997601 GROUP BY issue_id;


SELECT '--- TEST 7: TIME WINDOW ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(997701, 'SLOW_QUERY', 'SLOW_QUERY_LOG', 50.0, 'count', NOW() - INTERVAL 48 HOUR),
(997702, 'SLOW_QUERY', 'SLOW_QUERY_LOG', 1.0, 'count', NOW());

CALL run_ai_analysis(997701);
CALL run_ai_analysis(997702);

SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level
FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id
WHERE a.issue_id = 997702;
