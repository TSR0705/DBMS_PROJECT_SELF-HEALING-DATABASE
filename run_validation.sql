USE dbms_self_healing;

-- ==========================================
-- SETUP: SCHEMA AND PROCEDURES
-- ==========================================

-- Alter Table to include required columns
SET @exist := (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = 'admin_reviews' AND column_name = 'issue_type' AND table_schema = DATABASE());
SET @s = IF(@exist = 0, 'ALTER TABLE admin_reviews ADD COLUMN issue_type VARCHAR(255), ADD COLUMN action_type VARCHAR(255);', 'SELECT ''Columns already exist''');
PREPARE stmt FROM @s;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DELIMITER $$
DROP PROCEDURE IF EXISTS make_decision$$
CREATE PROCEDURE make_decision(IN p_issue_id BIGINT)
BEGIN
    DECLARE v_severity_level   VARCHAR(20)  CHARACTER SET utf8mb4;
    DECLARE v_confidence_score DECIMAL(15,6);
    DECLARE v_issue_type       VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_severity_weight  DECIMAL(15,6);
    DECLARE v_action_type      VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_success_rate     DECIMAL(15,6);
    DECLARE v_decision_score   DECIMAL(15,6);
    DECLARE v_decision_type    VARCHAR(50)  CHARACTER SET utf8mb4;
    DECLARE v_is_automatic     BOOLEAN;
    DECLARE v_decision_reason  VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_exists           INT;
    DECLARE v_anomaly_count    INT;
    DECLARE v_same_decisions   INT;
    DECLARE v_force_execution BOOLEAN DEFAULT FALSE;

    SELECT d.issue_type, a.severity_level, COALESCE(a.severity_ratio, 0.0)
    INTO   v_issue_type, v_severity_level, v_confidence_score
    FROM   ai_analysis a
    JOIN   detected_issues d ON a.issue_id = d.issue_id
    WHERE  a.issue_id = p_issue_id
    LIMIT  1;

    SET v_confidence_score = LEAST(1.0, ABS(v_confidence_score) / 3.0);

    IF v_issue_type IS NOT NULL THEN
        CASE v_severity_level
            WHEN 'CRITICAL' THEN SET v_severity_weight = 1.0;
            WHEN 'HIGH'     THEN SET v_severity_weight = 0.7;
            ELSE                 SET v_severity_weight = 0.4;
        END CASE;

        SELECT action_type, is_automatic
        INTO   v_action_type, v_is_automatic
        FROM   action_rules
        WHERE  issue_type = v_issue_type
        LIMIT  1;

        IF v_action_type IS NULL THEN
            SET v_action_type  = 'UNKNOWN';
            SET v_success_rate = 0.50;
        ELSE
            CALL compute_success_rate(v_issue_type, v_action_type, v_success_rate);
        END IF;

        SELECT COUNT(*) INTO v_anomaly_count
        FROM   detected_issues d
        JOIN   ai_analysis a ON d.issue_id = a.issue_id
        WHERE  d.issue_type = v_issue_type
          AND  a.severity_level IN ('HIGH','CRITICAL')
          AND  d.detected_at >= NOW() - INTERVAL 1 HOUR;

        IF v_anomaly_count > 5 THEN SET v_severity_weight = v_severity_weight + 0.1; END IF;

        SET v_decision_score = (v_severity_weight * 0.5) + (v_confidence_score * 0.3) + ((v_success_rate - 0.5) * 0.4);
        SET v_decision_score = LEAST(1.0, GREATEST(0.0, v_decision_score));

        SELECT COUNT(*) INTO v_same_decisions
        FROM (
            SELECT dl.decision_type
            FROM   decision_log dl
            JOIN   detected_issues di ON dl.issue_id = di.issue_id
            WHERE  di.issue_type = v_issue_type
            ORDER  BY dl.decision_id DESC
            LIMIT  3
        ) sub
        WHERE decision_type = (
            SELECT dl2.decision_type
            FROM   decision_log dl2
            JOIN   detected_issues di2 ON dl2.issue_id = di2.issue_id
            WHERE  di2.issue_type = v_issue_type
            ORDER  BY dl2.decision_id DESC
            LIMIT  1
        );

        IF v_same_decisions = 3 THEN SET v_decision_score = v_decision_score + 0.05; END IF;

        IF v_decision_score >= 0.5 THEN
            SET v_decision_type   = 'AUTO_HEAL';
            SET v_decision_reason = 'High confidence - automated execution approved';
        ELSE
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Insufficient history or logic bounds - manual override needed';
        END IF;

        IF v_action_type != 'UNKNOWN' AND v_is_automatic = FALSE AND v_decision_type = 'AUTO_HEAL' THEN
            SET v_decision_type = 'CONDITIONAL';
        END IF;

        IF v_success_rate < 0.3 THEN
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Historical action success rate too low, manual override enforced';
        END IF;

        IF v_severity_level = 'CRITICAL' AND v_success_rate < 0.2 THEN
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Critical severity action disabled due to high historical failure';
        END IF;

        IF v_action_type = 'UNKNOWN' THEN
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Unknown issue type forces safe fallback';
        END IF;

        IF v_decision_type = 'CONDITIONAL' THEN
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = CONCAT('[CONDITIONAL] ', v_decision_reason);
        END IF;

        IF v_decision_type = 'AUTO_HEAL' THEN
            SELECT COUNT(*) INTO @recent_auto_heals
            FROM decision_log
            WHERE decision_type = 'AUTO_HEAL'
              AND created_at >= NOW() - INTERVAL 1 MINUTE;

            IF @recent_auto_heals >= 5 THEN
                SET v_decision_type = 'ADMIN_REVIEW';
                SET v_decision_reason = 'AUTO_HEAL throttled: >5 automated actions executed globally in last 60 seconds';
            END IF;
        END IF;

        SELECT COUNT(*) INTO v_exists FROM decision_log WHERE issue_id = p_issue_id;
        IF v_exists = 0 THEN
            INSERT IGNORE INTO decision_log (issue_id, decision_type, decision_reason, confidence_at_decision)
            VALUES (p_issue_id, v_decision_type, v_decision_reason, v_confidence_score);

            SET @last_decision_id = LAST_INSERT_ID();
            
            INSERT INTO debug_log(step, message)
            VALUES ('make_decision', CONCAT('Decision: ', v_decision_type));

            IF v_decision_type = 'AUTO_HEAL' THEN
                CALL execute_healing_action(@last_decision_id);
                CALL update_learning(@last_decision_id);
            ELSEIF v_decision_type = 'ADMIN_REVIEW' THEN
                -- NEW IMPLEMENTATION AS PER PHASE 2
                INSERT IGNORE INTO admin_reviews(
                    decision_id,
                    issue_id,
                    issue_type,
                    action_type,
                    review_status
                )
                VALUES (
                    @last_decision_id,
                    p_issue_id,
                    v_issue_type,
                    v_action_type,
                    'PENDING'
                );
            END IF;
        END IF;
    END IF;
END$$

DROP PROCEDURE IF EXISTS process_admin_review$$
CREATE PROCEDURE process_admin_review(IN p_decision_id BIGINT, IN p_action VARCHAR(50))
BEGIN
    DECLARE v_exists INT;
    SELECT COUNT(*) INTO v_exists FROM admin_reviews WHERE decision_id = p_decision_id AND review_status = 'PENDING';
    
    IF v_exists > 0 THEN
        IF p_action = 'APPROVE' THEN
            UPDATE admin_reviews SET review_status = 'APPROVED', reviewed_at = NOW() WHERE decision_id = p_decision_id;
            CALL execute_healing_action(p_decision_id);
            CALL update_learning(p_decision_id);
        ELSEIF p_action = 'REJECT' THEN
            UPDATE admin_reviews SET review_status = 'REJECTED', reviewed_at = NOW() WHERE decision_id = p_decision_id;
        END IF;
    END IF;
END$$

DROP PROCEDURE IF EXISTS execute_healing_action$$
CREATE PROCEDURE execute_healing_action(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_id      BIGINT;
    DECLARE v_issue_type    VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_decision_type VARCHAR(50)  CHARACTER SET utf8mb4;
    DECLARE v_action_type   VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_is_automatic  TINYINT      DEFAULT 0;
    DECLARE v_exec_status   VARCHAR(10)  CHARACTER SET utf8mb4 DEFAULT 'SKIPPED';
    DECLARE v_exec_mode     VARCHAR(20)  CHARACTER SET utf8mb4 DEFAULT 'AUTOMATIC';
    DECLARE v_is_approved   INT          DEFAULT 0;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO debug_log(step, message)
        VALUES ('execution_error', 'Execution failed');
    END;

    INSERT INTO debug_log(step, message)
    VALUES ('execution', CONCAT('Decision ID: ', p_decision_id));

    SELECT dl.issue_id, di.issue_type, dl.decision_type
    INTO   v_issue_id, v_issue_type, v_decision_type
    FROM   decision_log dl
    JOIN   detected_issues di ON dl.issue_id = di.issue_id
    WHERE  dl.decision_id = p_decision_id
    LIMIT  1;

    IF v_issue_type IS NULL THEN LEAVE proc_label; END IF;

    SELECT action_type, is_automatic
    INTO   v_action_type, v_is_automatic
    FROM   action_rules
    WHERE  issue_type = v_issue_type
    LIMIT  1;

    -- NEW: Check for Admin Approval override
    SELECT COUNT(*) INTO v_is_approved FROM admin_reviews WHERE decision_id = p_decision_id AND review_status = 'APPROVED';

    IF v_is_approved > 0 THEN
        SET v_exec_status = 'SUCCESS';
        SET v_exec_mode   = 'MANUAL';
    ELSEIF v_decision_type = 'AUTO_HEAL' AND v_action_type IS NOT NULL AND v_is_automatic = 1 THEN
        SET v_exec_status = 'SUCCESS';
        SET v_exec_mode   = 'AUTOMATIC';
    ELSE
        SET v_exec_status = 'SKIPPED';
    END IF;

    IF v_exec_status = 'SUCCESS' THEN
        -- Dummy execution logic: verify rule still applies or simulate action
        IF v_action_type IS NULL THEN SET v_action_type = 'MANUAL_RESOLUTION'; END IF;
    END IF;

    IF v_exec_status != 'SKIPPED' THEN
        INSERT IGNORE INTO healing_actions (decision_id, action_type, execution_mode, executed_by, execution_status)
        VALUES (p_decision_id, v_action_type, v_exec_mode, IF(v_is_approved > 0, 'ADMIN', 'SYSTEM'), v_exec_status);
        
        INSERT INTO debug_log(step, message)
        VALUES ('execution_success', CONCAT('Executed: ', v_action_type, ' Mode: ', v_exec_mode));
    END IF;
END$$

DROP PROCEDURE IF EXISTS update_learning$$
CREATE PROCEDURE update_learning(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_type        VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_action_type       VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_exec_status       VARCHAR(10)  CHARACTER SET utf8mb4;
    DECLARE v_confidence_before DECIMAL(5,4) DEFAULT 0.0;
    DECLARE v_confidence_after  DECIMAL(5,4) DEFAULT 0.0;

    INSERT INTO debug_log(step, message)
    VALUES ('learning', 'Learning triggered');

    SELECT ha.action_type,
           ha.execution_status,
           LEAST(GREATEST(dl.confidence_at_decision, 0.0), 0.9999)
    INTO   v_action_type, v_exec_status, v_confidence_before
    FROM   healing_actions ha
    JOIN   decision_log dl ON ha.decision_id = dl.decision_id
    WHERE  ha.decision_id = p_decision_id
    LIMIT  1;

    IF v_action_type IS NULL OR v_exec_status IS NULL THEN LEAVE proc_label; END IF;
    IF v_exec_status = 'SKIPPED' THEN LEAVE proc_label; END IF;

    SELECT di.issue_type
    INTO   v_issue_type
    FROM   decision_log dl
    JOIN   detected_issues di ON dl.issue_id = di.issue_id
    WHERE  dl.decision_id = p_decision_id
    LIMIT  1;

    IF v_exec_status = 'SUCCESS' THEN
        SET v_confidence_after = LEAST(v_confidence_before + 0.05, 0.9999);
    ELSE
        SET v_confidence_after = GREATEST(v_confidence_before - 0.05, 0.0);
    END IF;

    INSERT IGNORE INTO learning_history (decision_id, issue_type, action_type, outcome, confidence_before, confidence_after)
    VALUES (
        p_decision_id,
        v_issue_type,
        v_action_type,
        IF(v_exec_status = 'SUCCESS', 'RESOLVED', 'FAILED'),
        v_confidence_before,
        v_confidence_after
    );
END$$
DELIMITER ;

-- ==========================================
-- TESTING PREPARATION
-- ==========================================
-- We will write a python script to verify assertions after.
