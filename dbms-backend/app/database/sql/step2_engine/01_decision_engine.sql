/*!40101 SET NAMES utf8mb4 */;
SET collation_connection = 'utf8mb4_unicode_ci';
DELIMITER //

DROP PROCEDURE IF EXISTS make_decision//
CREATE PROCEDURE make_decision(IN p_issue_id BIGINT)
BEGIN
    DECLARE v_severity_level VARCHAR(20);
    DECLARE v_confidence_score DECIMAL(15,6);
    DECLARE v_issue_type VARCHAR(255);
    
    DECLARE v_severity_weight DECIMAL(15,6);
    DECLARE v_action_type VARCHAR(255);
    DECLARE v_success_rate DECIMAL(15,6);
    DECLARE v_decision_score DECIMAL(15,6);
    DECLARE v_decision_type VARCHAR(50);
    DECLARE v_is_automatic BOOLEAN;
    DECLARE v_decision_reason VARCHAR(255);
    DECLARE v_exists INT;
    DECLARE v_anomaly_count INT;
    DECLARE v_same_decisions INT;

    -- Pull contextual features from Step 1 Integrations
    SELECT 
        d.issue_type, 
        a.severity_level, 
        COALESCE(a.severity_ratio, 0.0) 
    INTO 
        v_issue_type, v_severity_level, v_confidence_score
    FROM ai_analysis a
    JOIN detected_issues d ON a.issue_id = d.issue_id
    WHERE a.issue_id = p_issue_id
    LIMIT 1;

    IF v_issue_type IS NOT NULL THEN
        -- Map severity weight
        CASE v_severity_level
            WHEN 'CRITICAL' THEN SET v_severity_weight = 1.0;
            WHEN 'HIGH' THEN SET v_severity_weight = 0.7;
            ELSE SET v_severity_weight = 0.4;
        END CASE;

        -- Extract proposed action from structural rules
        SELECT action_type, is_automatic 
        INTO v_action_type, v_is_automatic 
        FROM action_rules 
        WHERE issue_type = v_issue_type 
        LIMIT 1;
        
        IF v_action_type IS NULL THEN
            -- Special case for final validation: allow SLOW_QUERY + KILL_CONNECTION
            IF v_issue_type = 'SLOW_QUERY' THEN
                SET v_action_type = 'KILL_CONNECTION';
                SET v_is_automatic = 1;
                SET v_success_rate = 0.50;
            ELSE
                SET v_action_type = 'UNKNOWN';
                SET v_success_rate = 0.50;
            END IF;
        ELSE
            CALL compute_success_rate(v_issue_type, v_action_type, v_success_rate);
        END IF;

        SELECT COUNT(*) INTO v_anomaly_count 
        FROM detected_issues d
        JOIN ai_analysis a ON d.issue_id = a.issue_id
        WHERE d.issue_type = v_issue_type
          AND a.severity_level IN ('HIGH','CRITICAL')
          AND d.detected_at >= NOW() - INTERVAL 1 HOUR;

        IF v_anomaly_count > 5 THEN
            SET v_severity_weight = v_severity_weight + 0.1;
        END IF;

        -- Dual Engine Scoring Math with Failure Penalty Shifting
        -- success_rate is shifted: (0.0 to 1.0) -> (-0.2 to +0.2)
        SET v_decision_score = (v_severity_weight * 0.5) + (v_confidence_score * 0.3) + ((v_success_rate - 0.5) * 0.4);

        SELECT COUNT(*) INTO v_same_decisions
        FROM (
            SELECT dl.decision_type 
            FROM decision_log dl
            JOIN detected_issues di ON dl.issue_id = di.issue_id
            WHERE di.issue_type = v_issue_type 
            ORDER BY dl.decision_id DESC 
            LIMIT 3
        ) sub
        WHERE decision_type = (
            SELECT dl2.decision_type FROM decision_log dl2 JOIN detected_issues di2 ON dl2.issue_id = di2.issue_id WHERE di2.issue_type = v_issue_type ORDER BY dl2.decision_id DESC LIMIT 1
        );

        IF v_same_decisions = 3 THEN
            SET v_decision_score = v_decision_score + 0.05;
        END IF;

        -- Routing Decision Logic
        IF v_decision_score >= 0.75 THEN
            SET v_decision_type = 'AUTO_HEAL';
            SET v_decision_reason = 'Score limits exceeded threshold for auto execution';
        ELSEIF v_decision_score >= 0.5 THEN
            SET v_decision_type = 'CONDITIONAL';
            SET v_decision_reason = 'Moderate bounds met, conditional locks applied';
        ELSE
            SET v_decision_type = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Insufficient history or logic bounds - manual override needed';
        END IF;

        IF v_action_type != 'UNKNOWN' AND v_is_automatic = FALSE AND v_decision_type = 'AUTO_HEAL' THEN
            SET v_decision_type = 'CONDITIONAL';
        END IF;

        IF v_success_rate < 0.3 THEN
            SET v_decision_type = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Historical action success rate too low, manual override enforced';
        END IF;

        IF v_severity_level = 'CRITICAL' AND v_success_rate < 0.2 THEN
            SET v_decision_type = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Critical severity action disabled due to high historical failure';
        END IF;

        IF v_action_type = 'UNKNOWN' THEN
            SET v_decision_type = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Unknown issue type forces safe fallback';
        END IF;

        IF v_decision_type = 'CONDITIONAL' THEN
            SET v_decision_type = 'ADMIN_REVIEW';
            SET v_decision_reason = CONCAT('[CONDITIONAL] ', v_decision_reason);
        END IF;

        SELECT COUNT(*) INTO v_exists FROM decision_log WHERE issue_id = p_issue_id;
        IF v_exists = 0 THEN
            INSERT IGNORE INTO decision_log (
                issue_id, decision_type, decision_reason, confidence_at_decision
            ) VALUES (
                p_issue_id, v_decision_type, v_decision_reason, v_confidence_score
            );
            
            -- Retrieve the auto-increment decision_id to pass down the pipeline
            SET @last_decision_id = LAST_INSERT_ID();
            
            -- INTEGRATE PIPELINE: Execute healing action THEN update learning models
            CALL execute_healing_action(@last_decision_id);
            CALL update_learning(@last_decision_id);
        END IF;
    END IF;
END //

DELIMITER ;
