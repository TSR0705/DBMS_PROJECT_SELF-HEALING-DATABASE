/*!40101 SET NAMES utf8mb4 */;
SET collation_connection = 'utf8mb4_unicode_ci';
DELIMITER //

DROP PROCEDURE IF EXISTS execute_healing_action_v2//
CREATE PROCEDURE execute_healing_action_v2(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_id         BIGINT;
    DECLARE v_issue_type       VARCHAR(255);
    DECLARE v_action_type      VARCHAR(255);
    DECLARE v_exec_status      VARCHAR(10) DEFAULT 'PENDING';
    DECLARE v_verification     VARCHAR(20) DEFAULT 'UNVERIFIED';
    DECLARE v_process_id       BIGINT      DEFAULT NULL;
    DECLARE v_issue_exists     BOOLEAN     DEFAULT FALSE;
    DECLARE v_error_msg        TEXT        DEFAULT NULL;

    -- [EXCEPTION HANDLER]
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
    BEGIN
        GET DIAGNOSTICS CONDITION 1 v_error_msg = MESSAGE_TEXT;
        SET v_exec_status = 'FAILED';
        INSERT INTO healing_actions (decision_id, action_type, execution_mode, executed_by, execution_status, verification_status, error_message)
        VALUES (p_decision_id, v_action_type, 'AUTOMATIC', 'SYSTEM', 'FAILED', 'FAILED', v_error_msg);
    END;

    -- [1] Fetch Context
    SELECT dl.issue_id, di.issue_type
    INTO   v_issue_id, v_issue_type
    FROM   decision_log dl
    JOIN   detected_issues di ON dl.issue_id = di.issue_id
    WHERE  dl.decision_id = p_decision_id LIMIT 1;

    -- [2] Re-validate
    CALL validate_issue_state(v_issue_id, v_issue_exists);

    IF v_issue_exists = TRUE THEN
        -- [3] Fetch Action
        SELECT action_type INTO v_action_type FROM action_rules WHERE issue_type = v_issue_type LIMIT 1;

        -- [4] Execution
        IF v_action_type = 'KILL_CONNECTION' THEN
            SELECT id INTO v_process_id FROM information_schema.processlist
            WHERE command != 'Sleep' AND user NOT IN ('system user', 'event_scheduler')
            ORDER BY time DESC LIMIT 1;
            
            IF v_process_id IS NOT NULL THEN
                SET @sql = CONCAT('KILL ', v_process_id);
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
                SET v_exec_status = 'SUCCESS';
            END IF;
        ELSEIF v_action_type = 'ROLLBACK_TRANSACTION' THEN
            SELECT processlist_id INTO v_process_id FROM information_schema.innodb_trx
            ORDER BY trx_started ASC LIMIT 1;
            
            IF v_process_id IS NOT NULL THEN
                SET @sql = CONCAT('KILL ', v_process_id);
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
                SET v_exec_status = 'SUCCESS';
            END IF;
        END IF;

        -- [5] Verification
        IF v_exec_status = 'SUCCESS' THEN
            DO SLEEP(2);
            CALL validate_issue_state(v_issue_id, v_issue_exists);
            IF v_issue_exists = FALSE THEN SET v_verification = 'VERIFIED';
            ELSE SET v_verification = 'FAILED'; SET v_exec_status = 'FAILED'; END IF;
        END IF;
    ELSE
        SET v_exec_status = 'SKIPPED';
        SET v_error_msg = 'Issue no longer active at execution time';
    END IF;

    -- [6] Record Result
    INSERT INTO healing_actions (decision_id, action_type, execution_mode, executed_by, execution_status, verification_status, process_id, error_message)
    VALUES (p_decision_id, v_action_type, 'AUTOMATIC', 'SYSTEM', v_exec_status, v_verification, v_process_id, v_error_msg);
END //

DELIMITER ;
