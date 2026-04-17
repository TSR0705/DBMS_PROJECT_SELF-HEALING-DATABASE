DELETE FROM ai_analysis WHERE issue_id LIKE '998%';
DELETE FROM detected_issues WHERE issue_id LIKE '998%';

SELECT '--- TEST 1: NORMAL DATA ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(998101, 'DEADLOCK', 'INNODB', 50.0, '%', NOW() - INTERVAL 5 HOUR),
(998102, 'DEADLOCK', 'INNODB', 52.0, '%', NOW() - INTERVAL 4 HOUR),
(998103, 'DEADLOCK', 'INNODB', 51.0, '%', NOW() - INTERVAL 3 HOUR),
(998104, 'DEADLOCK', 'INNODB', 49.0, '%', NOW() - INTERVAL 2 HOUR),
(998105, 'DEADLOCK', 'INNODB', 53.0, '%', NOW() - INTERVAL 1 HOUR),
(998106, 'DEADLOCK', 'INNODB', 51.5, '%', NOW());
CALL run_ai_analysis(998101); CALL run_ai_analysis(998102); CALL run_ai_analysis(998103); CALL run_ai_analysis(998104); CALL run_ai_analysis(998105); CALL run_ai_analysis(998106);
SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id WHERE a.issue_id = 998106;

SELECT '--- TEST 2: SINGLE SPIKE ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(998201, 'DEADLOCK', 'INNODB', 99.0, '%', NOW());
CALL run_ai_analysis(998201);
SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id WHERE a.issue_id = 998201;


SELECT '--- TEST 3: MULTIPLE SPIKES ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(998301, 'DEADLOCK', 'INNODB', 98.0, '%', NOW() - INTERVAL 35 MINUTE),
(998302, 'DEADLOCK', 'INNODB', 97.0, '%', NOW() - INTERVAL 30 MINUTE),
(998303, 'DEADLOCK', 'INNODB', 99.0, '%', NOW() - INTERVAL 25 MINUTE),
(998304, 'DEADLOCK', 'INNODB', 98.5, '%', NOW());
CALL run_ai_analysis(998301); CALL run_ai_analysis(998302); CALL run_ai_analysis(998303); CALL run_ai_analysis(998304);
SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id WHERE a.issue_id IN (998301, 998302, 998303, 998304);


SELECT '--- TEST 4: DRIFT ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(998401, 'CONNECTION_OVERLOAD', 'INNODB', 100.0, 'MB', NOW() - INTERVAL 5 HOUR),
(998402, 'CONNECTION_OVERLOAD', 'INNODB', 120.0, 'MB', NOW() - INTERVAL 4 HOUR),
(998403, 'CONNECTION_OVERLOAD', 'INNODB', 150.0, 'MB', NOW() - INTERVAL 3 HOUR),
(998404, 'CONNECTION_OVERLOAD', 'INNODB', 190.0, 'MB', NOW() - INTERVAL 2 HOUR),
(998405, 'CONNECTION_OVERLOAD', 'INNODB', 250.0, 'MB', NOW() - INTERVAL 1 HOUR),
(998406, 'CONNECTION_OVERLOAD', 'INNODB', 320.0, 'MB', NOW());
CALL run_ai_analysis(998401); CALL run_ai_analysis(998402); CALL run_ai_analysis(998403); CALL run_ai_analysis(998404); CALL run_ai_analysis(998405); CALL run_ai_analysis(998406);
SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id WHERE a.issue_id BETWEEN 998401 AND 998406 ORDER BY a.issue_id;

SELECT '--- TEST 5: CHAOTIC DATA ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(998501, 'SLOW_QUERY', 'INNODB', 10.0, 'ms', NOW() - INTERVAL 5 HOUR),
(998502, 'SLOW_QUERY', 'INNODB', 500.0, 'ms', NOW() - INTERVAL 4 HOUR),
(998503, 'SLOW_QUERY', 'INNODB', 20.0, 'ms', NOW() - INTERVAL 3 HOUR),
(998504, 'SLOW_QUERY', 'INNODB', 800.0, 'ms', NOW() - INTERVAL 2 HOUR),
(998505, 'SLOW_QUERY', 'INNODB', 5.0, 'ms', NOW() - INTERVAL 1 HOUR),
(998506, 'SLOW_QUERY', 'INNODB', 450.0, 'ms', NOW());
CALL run_ai_analysis(998501); CALL run_ai_analysis(998502); CALL run_ai_analysis(998503); CALL run_ai_analysis(998504); CALL run_ai_analysis(998505); CALL run_ai_analysis(998506);
SELECT a.issue_id, d.raw_metric_value, a.baseline_metric AS avg_metric, a.severity_ratio AS z_score, a.severity_level FROM ai_analysis a JOIN detected_issues d ON a.issue_id = d.issue_id WHERE a.issue_id BETWEEN 998501 AND 998506 ORDER BY a.issue_id;
