DELETE FROM ai_analysis WHERE issue_id LIKE '999%';
DELETE FROM detected_issues WHERE issue_id LIKE '999%';

SELECT '--- TEST 1: NORMAL ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(999101, 'DEADLOCK', 'INNODB', 50.0, '%', NOW() - INTERVAL 5 HOUR),
(999102, 'DEADLOCK', 'INNODB', 52.0, '%', NOW() - INTERVAL 4 HOUR),
(999103, 'DEADLOCK', 'INNODB', 49.0, '%', NOW() - INTERVAL 3 HOUR),
(999104, 'DEADLOCK', 'INNODB', 51.0, '%', NOW() - INTERVAL 2 HOUR),
(999105, 'DEADLOCK', 'INNODB', 48.0, '%', NOW() - INTERVAL 1 HOUR),
(999106, 'DEADLOCK', 'INNODB', 50.5, '%', NOW());
CALL run_ai_analysis(999101); CALL run_ai_analysis(999102); CALL run_ai_analysis(999103); CALL run_ai_analysis(999104); CALL run_ai_analysis(999105); CALL run_ai_analysis(999106);
SELECT issue_id, severity_level FROM ai_analysis WHERE issue_id = 999106;

SELECT '--- TEST 2: EXTREME OUTLIER ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(999201, 'SLOW_QUERY', 'SLOW_QUERY_LOG', 10.0, 'ms', NOW() - INTERVAL 5 HOUR),
(999202, 'SLOW_QUERY', 'SLOW_QUERY_LOG', 12.0, 'ms', NOW() - INTERVAL 4 HOUR),
(999203, 'SLOW_QUERY', 'SLOW_QUERY_LOG', 11.0, 'ms', NOW() - INTERVAL 3 HOUR),
(999204, 'SLOW_QUERY', 'SLOW_QUERY_LOG', 8000.0, 'ms', NOW());
CALL run_ai_analysis(999201); CALL run_ai_analysis(999202); CALL run_ai_analysis(999203); CALL run_ai_analysis(999204);
SELECT issue_id, severity_level FROM ai_analysis WHERE issue_id = 999204;

SELECT '--- TEST 3: SKEWED DATA ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(999301, 'UNAUTHORIZED_ACCESS', 'APPLICATION', 1.0, 'count', NOW() - INTERVAL 5 HOUR),
(999302, 'UNAUTHORIZED_ACCESS', 'APPLICATION', 1.0, 'count', NOW() - INTERVAL 4 HOUR),
(999303, 'UNAUTHORIZED_ACCESS', 'APPLICATION', 1.0, 'count', NOW() - INTERVAL 3 HOUR),
(999304, 'UNAUTHORIZED_ACCESS', 'APPLICATION', 10.0, 'count', NOW() - INTERVAL 2 HOUR),
(999305, 'UNAUTHORIZED_ACCESS', 'APPLICATION', 1.0, 'count', NOW() - INTERVAL 1 HOUR),
(999306, 'UNAUTHORIZED_ACCESS', 'APPLICATION', 50.0, 'count', NOW());
CALL run_ai_analysis(999301); CALL run_ai_analysis(999302); CALL run_ai_analysis(999303); CALL run_ai_analysis(999304); CALL run_ai_analysis(999305); CALL run_ai_analysis(999306);
SELECT issue_id, severity_level FROM ai_analysis WHERE issue_id = 999306;

SELECT '--- TEST 4: MULTI-SPIKE ---' AS test_name;
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(999401, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 100.0, 'count', NOW() - INTERVAL 6 HOUR),
(999402, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 100.0, 'count', NOW() - INTERVAL 5 HOUR),
(999403, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 900.0, 'count', NOW() - INTERVAL 4 HOUR),
(999404, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 900.0, 'count', NOW() - INTERVAL 3 HOUR),
(999405, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 920.0, 'count', NOW() - INTERVAL 2 HOUR),
(999406, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 950.0, 'count', NOW() - INTERVAL 1 HOUR),
(999407, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 990.0, 'count', NOW());
CALL run_ai_analysis(999401); CALL run_ai_analysis(999402); CALL run_ai_analysis(999403); CALL run_ai_analysis(999404); CALL run_ai_analysis(999405); CALL run_ai_analysis(999406); CALL run_ai_analysis(999407);
SELECT issue_id, severity_level FROM ai_analysis WHERE issue_id IN (999403, 999404, 999405, 999406, 999407);
