/*!40101 SET NAMES utf8mb4 */;
SET collation_connection = 'utf8mb4_unicode_ci';

-- ============================================================
-- STEP 1: REMOVE ALL FAKE TRIGGERS
-- ============================================================
DROP TRIGGER IF EXISTS after_issue_insert;
DROP TRIGGER IF EXISTS after_autoheal_decision;
DROP TRIGGER IF EXISTS after_healing_action;
DROP TRIGGER IF EXISTS after_decision_insert;

-- ============================================================
-- STEP 2: EXECUTION ENGINE
-- execute_healing_action(p_decision_id)
-- ============================================================
DELIMITER //

DROP PROCEDURE IF EXISTS execute_healing_action//
CREATE PROCEDURE execute_healing_action(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_id         BIGINT;
    DECLARE v_issue_type       VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_decision_type    VARCHAR(50)  CHARACTER SET utf8mb4;
    DECLARE v_action_type      VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_is_automatic     TINYINT      DEFAULT 0;
    DECLARE v_exec_status      VARCHAR(10)  CHARACTER SET utf8mb4 DEFAULT 'SKIPPED';
    DECLARE v_already_exists   INT          DEFAULT 0;

    -- 1. Fetch decision context
    SELECT dl.issue_id, di.issue_type, dl.decision_type
    INTO   v_issue_id, v_issue_type, v_decision_type
    FROM   decision_log dl
    JOIN   detected_issues di ON dl.issue_id = di.issue_id
    WHERE  dl.decision_id = p_decision_id
    LIMIT  1;

    IF v_issue_type IS NULL THEN
        LEAVE proc_label;
    END IF;

    -- 2. Fetch action mapping dynamically from action_rules
    SELECT action_type, is_automatic
    INTO   v_action_type, v_is_automatic
    FROM   action_rules
    WHERE  issue_type = CONVERT(v_issue_type USING utf8mb4)
    LIMIT  1;

    -- 3. Skip conditions
    IF v_decision_type != 'AUTO_HEAL' THEN
        SET v_exec_status = 'SKIPPED';
    ELSEIF v_action_type IS NULL THEN
        SET v_exec_status = 'SKIPPED';
    ELSEIF v_is_automatic = 0 THEN
        SET v_exec_status = 'SKIPPED';
    ELSE
        -- 4. All conditions pass: execute
        -- Extension point: call real DB command here
        SET v_exec_status = 'SUCCESS';
    END IF;

    -- 5. Insert only for real executions (SUCCESS or FAILED), not SKIPPED
    IF v_exec_status != 'SKIPPED' THEN
        SELECT COUNT(*) INTO v_already_exists
        FROM   healing_actions
        WHERE  decision_id = p_decision_id;

        IF v_already_exists = 0 THEN
            INSERT INTO healing_actions (
                decision_id,
                action_type,
                execution_mode,
                executed_by,
                execution_status
            ) VALUES (
                p_decision_id,
                v_action_type,
                'AUTOMATIC',
                'SYSTEM',
                v_exec_status
            );
        END IF;
    END IF;
END //

-- ============================================================
-- STEP 3: LEARNING ENGINE
-- update_learning(p_decision_id)
-- ONLY reads from healing_actions
-- ============================================================
DROP PROCEDURE IF EXISTS update_learning//
CREATE PROCEDURE update_learning(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_type        VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_action_type       VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_exec_status       VARCHAR(10)  CHARACTER SET utf8mb4;
    DECLARE v_confidence_before DECIMAL(5,4) DEFAULT 0.0;
    DECLARE v_confidence_after  DECIMAL(5,4) DEFAULT 0.0;
    DECLARE v_already_learned   INT          DEFAULT 0;

    -- Source of truth: healing_actions only
    SELECT ha.action_type,
           ha.execution_status,
           LEAST(GREATEST(dl.confidence_at_decision, 0.0), 0.9999)
    INTO   v_action_type, v_exec_status, v_confidence_before
    FROM   healing_actions ha
    JOIN   decision_log dl ON ha.decision_id = dl.decision_id
    WHERE  ha.decision_id = p_decision_id
    LIMIT  1;

    IF v_action_type IS NULL OR v_exec_status IS NULL THEN
        LEAVE proc_label;
    END IF;

    IF v_exec_status = 'SKIPPED' THEN
        LEAVE proc_label;
    END IF;

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

    SELECT COUNT(*) INTO v_already_learned
    FROM   learning_history
    WHERE  issue_type  = CONVERT(v_issue_type  USING utf8mb4)
      AND  action_type = CONVERT(v_action_type USING utf8mb4)
      AND  recorded_at >= NOW() - INTERVAL 60 SECOND;

    IF v_already_learned = 0 THEN
        INSERT INTO learning_history (
            issue_type,
            action_type,
            outcome,
            confidence_before,
            confidence_after
        ) VALUES (
            CONVERT(v_issue_type  USING utf8mb4),
            CONVERT(v_action_type USING utf8mb4),
            IF(v_exec_status = 'SUCCESS', 'RESOLVED', 'FAILED'),
            v_confidence_before,
            v_confidence_after
        );
    END IF;
END //

DELIMITER ;
