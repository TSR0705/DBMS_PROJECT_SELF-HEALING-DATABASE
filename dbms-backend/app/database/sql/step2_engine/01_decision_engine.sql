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
    DECLARE v_impact_weight    DECIMAL(15,6) DEFAULT 0.0;
    DECLARE v_priority_score   DECIMAL(15,6);
    DECLARE v_decision_type    VARCHAR(50);
    DECLARE v_decision_reason  VARCHAR(255);
    DECLARE v_exists           INT;
    DECLARE v_issue_exists     BOOLEAN DEFAULT FALSE;
    DECLARE v_active_q         INT;
    DECLARE v_lock_w           INT;

    -- [1] Fetch AI Context
    SELECT d.issue_type, a.severity_level, COALESCE(a.severity_ratio, 0.0) 
    INTO v_issue_type, v_severity_level, v_confidence_score
    FROM ai_analysis a
    JOIN detected_issues d ON a.issue_id = d.issue_id
    WHERE a.issue_id = p_issue_id LIMIT 1;

    IF v_issue_type IS NULL THEN LEAVE proc_label; END IF;

    -- [2] [PHASE 7] Smart Prioritization Logic
    -- AI Weight (40%) + System Impact (60%)
    CASE v_severity_level
        WHEN 'CRITICAL' THEN SET v_severity_weight = 1.0;
        WHEN 'HIGH'     THEN SET v_severity_weight = 0.7;
        ELSE                 SET v_severity_weight = 0.4;
    END CASE;

    -- Fetch Current System Impact
    SELECT active_queries, lock_waits INTO v_active_q, v_lock_w 
    FROM system_metrics ORDER BY metric_id DESC LIMIT 1;
    
    SET v_impact_weight = (LEAST(v_active_q, 20) / 20.0 * 0.7) + (LEAST(v_lock_w, 10) / 10.0 * 0.3);
    
    -- Normalize AI confidence score (Z-score ratio) to [0, 1] range for weighting
    -- Z-score of 3.0 is considered 100% confidence in AI terms
    SET v_confidence_score = LEAST(1.0, ABS(v_confidence_score) / 3.0);
    
    -- Final Priority Formula (Now bounded [0, 1])
    SET v_priority_score = (v_severity_weight * 0.3) + (v_confidence_score * 0.2) + (v_impact_weight * 0.5);
    
    -- Ensure absolute ceiling for UI safety
    SET v_priority_score = LEAST(1.0, v_priority_score);

    -- [3] Authority Validation
    CALL validate_issue_state(p_issue_id, v_issue_exists);

    -- [4] Decision Routing
    IF v_issue_exists = TRUE THEN
        SET v_decision_type = 'AUTO_HEAL';
        SET v_decision_reason = CONCAT('AUTO_HEAL authorized: Phase 7 Smart Priority (', ROUND(v_priority_score, 2), ')');
    ELSE
        SET v_decision_type = 'ADMIN_REVIEW';
        SET v_decision_reason = CONCAT('ADMIN_REVIEW: DB state clean/ambiguous (Priority: ', ROUND(v_priority_score, 2), ')');
    END IF;

    -- [PHASE 7] Manual Override for specific types (Safe Demo Scenarios)
    IF v_issue_type IN ('SECURITY_POLICY_VIOLATION', 'OPTIMIZATION_SUGGESTION') THEN
        SET v_decision_type = 'ADMIN_REVIEW';
        SET v_decision_reason = 'ADMIN_REVIEW: Policy requires human sign-off for structural or security changes.';
    END IF;

    -- [5] Record Decision
    SELECT COUNT(*) INTO v_exists FROM decision_log WHERE issue_id = p_issue_id;
    IF v_exists = 0 THEN
        INSERT INTO decision_log (issue_id, decision_type, decision_reason, confidence_at_decision)
        VALUES (p_issue_id, v_decision_type, v_decision_reason, v_priority_score);
        SET @last_decision_id = LAST_INSERT_ID();

        -- [PHASE 7] Immediate Execution & Race Condition Guard
        IF v_decision_type = 'AUTO_HEAL' THEN
            SELECT detected_at INTO @v_det_at FROM detected_issues WHERE issue_id = p_issue_id;
            
            IF TIMESTAMPDIFF(SECOND, @v_det_at, NOW()) > 10 THEN
                INSERT INTO debug_log(step, message)
                VALUES ('timing', CONCAT(v_issue_type, ' skipped: Stale by ', TIMESTAMPDIFF(SECOND, @v_det_at, NOW()), 's'));
                
                UPDATE decision_log SET decision_reason = CONCAT(decision_reason, ' [SKIPPED: STALE]') WHERE decision_id = @last_decision_id;
            ELSE
                INSERT INTO debug_log(step, message)
                VALUES ('timing', CONCAT(v_issue_type, ' immediate execution. Delay: ', TIMESTAMPDIFF(SECOND, @v_det_at, NOW()), 's'));
                
                CALL execute_healing_action_v2(@last_decision_id);
            END IF;
        ELSE
            -- [PHASE 7] Fetch intended action for the review screen
            SELECT action_type INTO @v_intended_action FROM action_rules WHERE issue_type = v_issue_type LIMIT 1;
            
            INSERT INTO admin_reviews (issue_id, decision_id, review_status, issue_type, action_type)
            VALUES (p_issue_id, @last_decision_id, 'PENDING', v_issue_type, COALESCE(@v_intended_action, 'MANUAL_VERIFICATION'));
        END IF;
    END IF;
END //

DELIMITER ;
