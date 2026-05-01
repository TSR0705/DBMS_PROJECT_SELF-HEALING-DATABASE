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

    -- [2] Re-validate before execution
    CALL validate_issue_state(v_issue_id, v_issue_exists);

    IF v_issue_exists = TRUE THEN
        -- [3] Fetch Action
        SELECT action_type INTO v_action_type FROM action_rules WHERE issue_type = v_issue_type LIMIT 1;
        
        -- Fallback to Admin Review proposed action if no rule found
        IF v_action_type IS NULL THEN
            SELECT action_type INTO v_action_type FROM admin_reviews WHERE decision_id = p_decision_id LIMIT 1;
        END IF;

        -- [4] Execution Logic
        IF v_action_type = 'KILL_CONNECTION' OR v_action_type = 'KILL_SLOW_QUERY' THEN
            -- [PHASE 7] Iterative Kill Loop for CONNECTION_OVERLOAD
            SET @kill_count = 0;
            SET @max_kills = 10; -- Safety break
            
            -- Re-check active queries
            SELECT COUNT(*) INTO @v_current_active 
            FROM information_schema.processlist 
            WHERE command = 'Query' AND info IS NOT NULL;

            WHILE @v_current_active > 5 AND @kill_count < @max_kills DO
                SELECT id INTO v_process_id FROM information_schema.processlist
                WHERE command = 'Query'
                  AND info IS NOT NULL
                  AND user NOT IN ('system user', 'event_scheduler')
                  AND id != CONNECTION_ID()
                ORDER BY time DESC LIMIT 1;
                
                IF v_process_id IS NOT NULL THEN
                    INSERT INTO debug_log(step, message)
                    VALUES ('overload_target', CONCAT('Killing PID: ', v_process_id, ' (Active: ', @v_current_active, ')'));

                    SET @sql = CONCAT('KILL ', v_process_id);
                    PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
                    
                    SET @kill_count = @kill_count + 1;
                    SET v_exec_status = 'SUCCESS';
                    
                    -- Re-fetch for next iteration
                    SELECT COUNT(*) INTO @v_current_active 
                    FROM information_schema.processlist 
                    WHERE command = 'Query' AND info IS NOT NULL;
                ELSE
                    SET @v_current_active = 0; -- Break loop if no more candidates
                END IF;
            END WHILE;
        ELSEIF v_action_type = 'ROLLBACK_TRANSACTION' THEN
            -- [PHASE 7] Targeted Deadlock Resolution
            -- 1. Extract blocking transaction details from sys view
            SELECT blocking_trx_id INTO v_blocking_trx
            FROM sys.innodb_lock_waits
            ORDER BY wait_age_secs DESC
            LIMIT 1;

            -- 2. Map transaction ID to MySQL thread ID (Process ID)
            IF v_blocking_trx IS NOT NULL THEN
                SELECT trx_mysql_thread_id INTO v_process_id
                FROM information_schema.innodb_trx
                WHERE trx_id = v_blocking_trx
                LIMIT 1;
            END IF;
            
            -- 3. Validate and Execute Kill
            IF v_process_id IS NOT NULL AND v_process_id != CONNECTION_ID() THEN
                -- Debug logging
                INSERT INTO debug_log(step, message)
                VALUES ('deadlock_target', CONCAT('Killing blocking PID: ', v_process_id, ' for TRX: ', v_blocking_trx));

                SET @sql = CONCAT('KILL ', v_process_id);
                PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
                SET v_exec_status = 'SUCCESS';
            ELSE
                SET v_error_msg = 'No valid blocking process found to kill';
                SET v_exec_status = 'FAILED';
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
        -- Set a descriptive action type for the log
        SET v_action_type = 'SKIPPED_STALE_ISSUE';
    END IF;

    -- [6] Record Result
    INSERT INTO healing_actions (decision_id, action_type, execution_mode, executed_by, execution_status, verification_status, process_id, error_message)
    VALUES (p_decision_id, COALESCE(v_action_type, 'UNKNOWN_ACTION'), v_mode, v_by, v_exec_status, v_verification, v_process_id, v_error_msg);
END //

DELIMITER ;
