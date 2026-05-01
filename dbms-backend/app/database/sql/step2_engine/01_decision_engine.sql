/*!40101 SET NAMES utf8mb4 */;
SET collation_connection = 'utf8mb4_unicode_ci';
DELIMITER //

DROP PROCEDURE IF EXISTS make_decision//
CREATE PROCEDURE make_decision(IN p_issue_id BIGINT)
proc_label: BEGIN
    DECLARE v_severity_level   VARCHAR(20);
    DECLARE v_confidence_score DECIMAL(15,6);
    DECLARE v_issue_type       VARCHAR(255);
    DECLARE v_severity_weight  DECIMAL(15,6);
    DECLARE v_priority_score   DECIMAL(15,6);
    DECLARE v_decision_type    VARCHAR(50);
    DECLARE v_decision_reason  VARCHAR(255);
    DECLARE v_exists           INT;
    DECLARE v_issue_exists     BOOLEAN DEFAULT FALSE;

    -- [1] Fetch AI Context
    SELECT d.issue_type, a.severity_level, COALESCE(a.severity_ratio, 0.0) 
    INTO v_issue_type, v_severity_level, v_confidence_score
    FROM ai_analysis a
    JOIN detected_issues d ON a.issue_id = d.issue_id
    WHERE a.issue_id = p_issue_id LIMIT 1;

    IF v_issue_type IS NULL THEN LEAVE proc_label; END IF;

    -- [2] Calculate Priority Score (AI Only for ranking)
    CASE v_severity_level
        WHEN 'CRITICAL' THEN SET v_severity_weight = 1.0;
        WHEN 'HIGH'     THEN SET v_severity_weight = 0.7;
        ELSE                 SET v_severity_weight = 0.4;
    END CASE;
    
    SET v_priority_score = (v_severity_weight * 0.6) + (LEAST(v_confidence_score, 1.0) * 0.4);

    -- [3] High-Precision Authority Validation (Source of Truth)
    CALL validate_issue_state(p_issue_id, v_issue_exists);

    -- [4] Decision Routing
    IF v_issue_exists = TRUE THEN
        SET v_decision_type = 'AUTO_HEAL';
        SET v_decision_reason = CONCAT('AUTO_HEAL authorized: Validated impact (Priority: ', ROUND(v_priority_score, 2), ')');
    ELSE
        SET v_decision_type = 'ADMIN_REVIEW';
        SET v_decision_reason = CONCAT('ADMIN_REVIEW: DB state clean, AI prediction ignored (Priority: ', ROUND(v_priority_score, 2), ')');
    END IF;

    -- [5] Record Decision and Push to Reliable Queue
    SELECT COUNT(*) INTO v_exists FROM decision_log WHERE issue_id = p_issue_id;
    IF v_exists = 0 THEN
        INSERT INTO decision_log (issue_id, decision_type, decision_reason, confidence_at_decision)
        VALUES (p_issue_id, v_decision_type, v_decision_reason, v_priority_score);
        
        SET @last_decision_id = LAST_INSERT_ID();

        IF v_decision_type = 'AUTO_HEAL' THEN
            INSERT INTO execution_queue (decision_id, priority_score, status)
            VALUES (@last_decision_id, v_priority_score, 'PENDING')
            ON DUPLICATE KEY UPDATE status = 'PENDING', retry_count = 0;
        END IF;
    END IF;
END //

DELIMITER ;
