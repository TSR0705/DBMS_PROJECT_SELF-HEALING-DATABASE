USE self_healing_dbms;

INSERT INTO detected_issues (detected_timestamp, detection_source, target_resource_type, target_resource_name, severity_level, metric_value, description) 
VALUES (NOW(6), 'SLOW_QUERY_LOG', 'QUERY', 'SELECT * FROM orders', 'CRITICAL', 5.25, 'Slow query detected');

INSERT INTO ai_analysis (issue_id, confidence_score, root_cause_hypothesis, suggested_action_category) 
VALUES (1, 0.87, 'Missing index on order_date', 'INDEX_TUNING');

INSERT INTO decision_log (analysis_id, decision_type, rationale) 
VALUES (1, 'AUTO_HEAL', 'High confidence analysis');

INSERT INTO healing_actions (decision_id, action_description, action_type, execution_status) 
VALUES (1, 'CREATE INDEX idx_order_date ON orders(order_date)', 'INDEX_CREATE', 'EXECUTED');

INSERT INTO admin_reviews (decision_id, reviewer_name, approval_status, review_comment) 
VALUES (1, 'DBA_ADMIN', 'APPROVED', 'Index creation approved');

INSERT INTO learning_history (issue_id, action_id, was_resolved, ai_confidence_at_time, outcome_notes) 
VALUES (1, 1, TRUE, 0.87, 'Query resolved after index creation');

SELECT 'DETECTED_ISSUES' as table_name;
SELECT * FROM detected_issues;

SELECT 'AI_ANALYSIS' as table_name;
SELECT * FROM ai_analysis;

SELECT 'DECISION_LOG' as table_name;
SELECT * FROM decision_log;

SELECT 'HEALING_ACTIONS' as table_name;
SELECT * FROM healing_actions;

SELECT 'ADMIN_REVIEWS' as table_name;
SELECT * FROM admin_reviews;

SELECT 'LEARNING_HISTORY' as table_name;
SELECT * FROM learning_history;
