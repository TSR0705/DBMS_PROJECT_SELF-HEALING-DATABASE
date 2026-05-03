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
    DECLARE v_decision_type    VARCHAR(50);
    DECLARE v_mode             VARCHAR(50) DEFAULT 'AUTOMATIC';
    DECLARE v_by               VARCHAR(50) DEFAULT 'SYSTEM';
    DECLARE v_blocking_trx     BIGINT UNSIGNED DEFAULT NULL;

    -- [1] Fetch Context
    SELECT dl.issue_id, di.issue_type, dl.decision_type
    INTO   v_issue_id, v_issue_type, v_decision_type
    FROM   decision_log dl
    JOIN   detected_issues di ON dl.issue_id = di.issue_id
    WHERE  dl.decision_id = p_decision_id LIMIT 1;

    -- Set Mode based on Decision Type
    IF v_decision_type = 'ADMIN_REVIEW' THEN
        SET v_mode = 'ADMIN_APPROVED';
        SET v_by = 'ADMIN';
    END IF;

    -- [2] Action Resolution
    SELECT action_type INTO v_action_type FROM action_rules WHERE issue_type = v_issue_type LIMIT 1;
    IF v_action_type IS NULL THEN
        SELECT action_type INTO v_action_type FROM admin_reviews WHERE decision_id = p_decision_id LIMIT 1;
    END IF;

    -- [3] Pre-Execution Validation
    IF v_action_type IS NULL THEN
        SET v_exec_status = 'FAILED';
        SET v_error_msg = 'Critical: No action_type resolved for this decision.';
    ELSEIF v_action_type NOT IN ('KILL_CONNECTION', 'KILL_SLOW_QUERY', 'ROLLBACK_TRANSACTION', 'APPLY_OPTIMIZATION', 'LOG_SECURITY_INCIDENT', 'MANUAL_VERIFICATION') THEN
        SET v_exec_status = 'FAILED';
        SET v_error_msg = CONCAT('Critical: Unsupported action_type: ', v_action_type);
    ELSE
        -- [4] State Re-validation
        CALL validate_issue_state(v_issue_id, v_issue_exists);
        IF v_issue_exists = FALSE THEN
            SET v_exec_status = 'SKIPPED';
            SET v_error_msg = 'Issue no longer active at execution time';
            SET v_action_type = 'SKIPPED_STALE_ISSUE';
        ELSE
            -- [5] Execution Logic
            IF v_action_type = 'KILL_CONNECTION' THEN
                SET @kill_count = 0;
                SELECT COUNT(*) INTO @v_current_active FROM information_schema.processlist WHERE command = 'Query' AND info IS NOT NULL;
                WHILE @v_current_active > 2 AND @kill_count < 10 DO
                    SELECT id INTO v_process_id FROM information_schema.processlist WHERE command = 'Query' AND info IS NOT NULL AND user NOT IN ('system user', 'event_scheduler') AND id != CONNECTION_ID() ORDER BY time DESC LIMIT 1;
                    IF v_process_id IS NOT NULL THEN
                        SET @sql = CONCAT('KILL ', v_process_id);
                        PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
                        SET @kill_count = @kill_count + 1;
                        SET v_exec_status = 'SUCCESS';
                        SELECT COUNT(*) INTO @v_current_active FROM information_schema.processlist WHERE command = 'Query' AND info IS NOT NULL;
                    ELSE SET @v_current_active = 0; END IF;
                END WHILE;
            ELSEIF v_action_type = 'KILL_SLOW_QUERY' THEN
                SELECT id INTO v_process_id FROM information_schema.processlist WHERE command != 'Sleep' AND user NOT IN ('system user', 'event_scheduler') AND id != CONNECTION_ID() AND time >= 10 ORDER BY time DESC LIMIT 1;
                IF v_process_id IS NOT NULL THEN
                    SET @sql = CONCAT('KILL ', v_process_id);
                    PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
                    SET v_exec_status = 'SUCCESS';
                END IF;
            ELSEIF v_action_type = 'ROLLBACK_TRANSACTION' THEN
                SELECT blocking_trx_id INTO v_blocking_trx FROM sys.innodb_lock_waits ORDER BY wait_age_secs DESC LIMIT 1;
                IF v_blocking_trx IS NOT NULL THEN
                    SELECT trx_mysql_thread_id INTO v_process_id FROM information_schema.innodb_trx WHERE trx_id = v_blocking_trx LIMIT 1;
                END IF;
                IF v_process_id IS NOT NULL AND v_process_id != CONNECTION_ID() THEN
                    SET @sql = CONCAT('KILL ', v_process_id);
                    PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
                    SET v_exec_status = 'SUCCESS';
                ELSE
                    SET v_error_msg = 'No valid blocking process found to kill';
                    SET v_exec_status = 'FAILED';
                END IF;
            ELSEIF v_action_type = 'APPLY_OPTIMIZATION' THEN
                SELECT table_name INTO @target_table FROM information_schema.tables WHERE data_free > 10 * 1024 * 1024 AND table_schema = 'dbms_self_healing' ORDER BY data_free DESC LIMIT 1;
                IF @target_table IS NOT NULL THEN
                    SET @sql = CONCAT('OPTIMIZE TABLE dbms_self_healing.', @target_table);
                    PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
                    SET v_exec_status = 'SUCCESS';
                ELSE
                    SET v_exec_status = 'SKIPPED';
                END IF;
            ELSEIF v_action_type = 'LOG_SECURITY_INCIDENT' THEN
                INSERT INTO debug_log(step, message) SELECT 'security_audit', CONCAT('User: ', user, '@', host, ' has excessive privileges') FROM mysql.user WHERE host = '%' AND (Grant_priv = 'Y' OR Super_priv = 'Y');
                SET v_exec_status = 'SUCCESS';
            ELSEIF v_action_type = 'MANUAL_VERIFICATION' THEN
                INSERT INTO debug_log(step, message) VALUES ('verification', 'Manual verification logged');
                SET v_exec_status = 'SUCCESS';
            END IF;

            -- [6] Verification
            IF v_exec_status = 'SUCCESS' THEN
                IF v_issue_type IN ('SECURITY_POLICY_VIOLATION', 'OPTIMIZATION_SUGGESTION') THEN
                    SET v_verification = 'VERIFIED';
                ELSE
                    DO SLEEP(2);
                    CALL validate_issue_state(v_issue_id, v_issue_exists);
                    IF v_issue_exists = FALSE THEN SET v_verification = 'VERIFIED';
                    ELSE SET v_verification = 'FAILED'; SET v_exec_status = 'FAILED'; END IF;
                END IF;
            END IF;
        END IF;
    END IF;

    -- [7] Record Result
    INSERT INTO healing_actions (decision_id, action_type, execution_mode, executed_by, execution_status, verification_status, process_id, error_message)
    VALUES (p_decision_id, v_action_type, v_mode, v_by, v_exec_status, v_verification, v_process_id, v_error_msg);
END //

DELIMITER ;
