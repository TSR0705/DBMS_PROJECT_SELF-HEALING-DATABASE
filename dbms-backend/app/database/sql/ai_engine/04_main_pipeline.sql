DELIMITER //

DROP PROCEDURE IF EXISTS run_ai_analysis//
CREATE PROCEDURE run_ai_analysis(IN p_issue_id BIGINT)
BEGIN
    DECLARE v_issue_type VARCHAR(255);
    DECLARE v_raw_metric DECIMAL(15, 6);
    DECLARE v_metric_group VARCHAR(20);
    
    DECLARE v_avg DECIMAL(15, 6);
    DECLARE v_std DECIMAL(15, 6);
    DECLARE v_min DECIMAL(15, 6);
    DECLARE v_max DECIMAL(15, 6);
    DECLARE v_recent_anomalies INT;
    DECLARE v_q1 DECIMAL(15, 6);
    DECLARE v_q3 DECIMAL(15, 6);
    
    DECLARE v_z_score DECIMAL(15, 6);
    DECLARE v_severity VARCHAR(20);
    DECLARE v_exists INT DEFAULT 0;

    CALL get_issue_features(p_issue_id, v_issue_type, v_raw_metric, v_metric_group);

    IF v_issue_type IS NOT NULL THEN
        CALL compute_baseline(
            p_issue_id, 
            v_issue_type, 
            v_metric_group, 
            v_avg, 
            v_std,
            v_min,
            v_max,
            v_recent_anomalies,
            v_q1,
            v_q3
        );

        CALL compute_severity(
            v_raw_metric, 
            v_avg, 
            v_std, 
            v_recent_anomalies,
            v_q1,
            v_q3,
            v_z_score, 
            v_severity
        );

        SELECT COUNT(*) INTO v_exists FROM ai_analysis WHERE issue_id = p_issue_id;

        IF v_exists = 0 THEN
            INSERT IGNORE INTO ai_analysis (
                issue_id,
                severity_level,
                baseline_metric,
                severity_ratio,
                created_at
            ) VALUES (
                p_issue_id,
                v_severity,
                v_avg,
                v_z_score,
                NOW()
            );
        END IF;
    END IF;
END //

DELIMITER ;
