-- END TO END DATABASE FLOW SIMULATION
-- Clean environment
DELETE FROM ai_analysis;
DELETE FROM detected_issues;

-- SCENARIO A: TRANSACTION_FAILURE (Stable Baseline with Sudden Outlier)
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(1, 'TRANSACTION_FAILURE', 'INNODB', 2.0, 'count', NOW() - INTERVAL 5 HOUR),
(2, 'TRANSACTION_FAILURE', 'INNODB', 3.0, 'count', NOW() - INTERVAL 4 HOUR),
(3, 'TRANSACTION_FAILURE', 'INNODB', 2.0, 'count', NOW() - INTERVAL 3 HOUR),
(4, 'TRANSACTION_FAILURE', 'INNODB', 1.0, 'count', NOW() - INTERVAL 2 HOUR),
(5, 'TRANSACTION_FAILURE', 'INNODB', 2.5, 'count', NOW() - INTERVAL 1 HOUR),
(6, 'TRANSACTION_FAILURE', 'INNODB', 950.0, 'count', NOW());

CALL run_ai_analysis(1); CALL run_ai_analysis(2); CALL run_ai_analysis(3); 
CALL run_ai_analysis(4); CALL run_ai_analysis(5); CALL run_ai_analysis(6);

-- SCENARIO B: CONNECTION_OVERLOAD (Temporal Drift Upwards)
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(11, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 150.0, 'conn', NOW() - INTERVAL 5 HOUR),
(12, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 160.0, 'conn', NOW() - INTERVAL 4 HOUR),
(13, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 180.0, 'conn', NOW() - INTERVAL 3 HOUR),
(14, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 250.0, 'conn', NOW() - INTERVAL 2 HOUR),
(15, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 350.0, 'conn', NOW() - INTERVAL 1 HOUR),
(16, 'CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', 700.0, 'conn', NOW());

CALL run_ai_analysis(11); CALL run_ai_analysis(12); CALL run_ai_analysis(13); 
CALL run_ai_analysis(14); CALL run_ai_analysis(15); CALL run_ai_analysis(16);

-- SCENARIO C: DATA_CORRUPTION (Chaotic Binary Swings)
INSERT INTO detected_issues (issue_id, issue_type, detection_source, raw_metric_value, raw_metric_unit, detected_at) VALUES 
(21, 'SLOW_QUERY', 'INNODB', 0.0, 'bool', NOW() - INTERVAL 5 HOUR),
(22, 'SLOW_QUERY', 'INNODB', 1.0, 'bool', NOW() - INTERVAL 4 HOUR),
(23, 'SLOW_QUERY', 'INNODB', 0.0, 'bool', NOW() - INTERVAL 3 HOUR),
(24, 'SLOW_QUERY', 'INNODB', 50.0, 'bool', NOW() - INTERVAL 2 HOUR),
(25, 'SLOW_QUERY', 'INNODB', 0.0, 'bool', NOW() - INTERVAL 1 HOUR),
(26, 'SLOW_QUERY', 'INNODB', 1.0, 'bool', NOW());

CALL run_ai_analysis(21); CALL run_ai_analysis(22); CALL run_ai_analysis(23); 
CALL run_ai_analysis(24); CALL run_ai_analysis(25); CALL run_ai_analysis(26);

-- FULL OUTPUT SELECTION
SELECT d.issue_id, d.issue_type, d.raw_metric_value,
       a.baseline_metric AS "p_avg",
       a.severity_ratio AS "confidence_or_z",
       a.severity_level
FROM detected_issues d
LEFT JOIN ai_analysis a ON d.issue_id = a.issue_id
ORDER BY d.issue_type, d.issue_id;
