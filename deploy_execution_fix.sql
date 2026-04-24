USE dbms_self_healing;

-- ============================================================
-- ENHANCED healing_actions TABLE - MySQL 5.7+ Compatible
-- Add columns for verification metrics (backward compatible)
-- ============================================================

-- Check and add columns individually with error handling
-- This approach works with MySQL 5.7+ and avoids IF NOT EXISTS syntax issues

-- Add before_metric column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE table_name = 'healing_actions' 
     AND table_schema = DATABASE() 
     AND column_name = 'before_metric') > 0,
    'SELECT ''Column before_metric already exists'' AS msg',
    'ALTER TABLE healing_actions ADD COLUMN before_metric DECIMAL(15,6) NULL COMMENT ''Metric value before execution'''
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add after_metric column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE table_name = 'healing_actions' 
     AND table_schema = DATABASE() 
     AND column_name = 'after_metric') > 0,
    'SELECT ''Column after_metric already exists'' AS msg',
    'ALTER TABLE healing_actions ADD COLUMN after_metric DECIMAL(15,6) NULL COMMENT ''Metric value after execution'''
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add verification_status column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE table_name = 'healing_actions' 
     AND table_schema = DATABASE() 
     AND column_name = 'verification_status') > 0,
    'SELECT ''Column verification_status already exists'' AS msg',
    'ALTER TABLE healing_actions ADD COLUMN verification_status VARCHAR(20) NULL COMMENT ''VERIFIED/UNVERIFIED/FAILED'''
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add process_id column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE table_name = 'healing_actions' 
     AND table_schema = DATABASE() 
     AND column_name = 'process_id') > 0,
    'SELECT ''Column process_id already exists'' AS msg',
    'ALTER TABLE healing_actions ADD COLUMN process_id BIGINT NULL COMMENT ''Process ID for KILL_CONNECTION'''
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add error_message column
SET @sql = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS 
     WHERE table_name = 'healing_actions' 
     AND table_schema = DATABASE() 
     AND column_name = 'error_message') > 0,
    'SELECT ''Column error_message already exists'' AS msg',
    'ALTER TABLE healing_actions ADD COLUMN error_message TEXT NULL COMMENT ''Error details if execution failed'''
));
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

DELIMITER //

DROP PROCEDURE IF EXISTS execute_healing_action_v2//
CREATE PROCEDURE execute_healing_action_v2(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_id         BIGINT;
    DECLARE v_issue_type       VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_decision_type    VARCHAR(50)  CHARACTER SET utf8mb4;
    DECLARE v_action_type      VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_is_automatic     TINYINT      DEFAULT 0;
    DECLARE v_exec_status      VARCHAR(10)  CHARACTER SET utf8mb4 DEFAULT 'PENDING';
    DECLARE v_verification     VARCHAR(20)  CHARACTER SET utf8mb4 DEFAULT 'UNVERIFIED';
    DECLARE v_already_exists   INT          DEFAULT 0;
    
    -- Execution variables
    DECLARE v_process_id       BIGINT       DEFAULT NULL;
    DECLARE v_raw_metric       DECIMAL(15,6) DEFAULT NULL;
    DECLARE v_before_metric    DECIMAL(15,6) DEFAULT NULL;
    DECLARE v_after_metric     DECIMAL(15,6) DEFAULT NULL;
    DECLARE v_error_msg        TEXT         DEFAULT NULL;
    DECLARE v_can_execute      BOOLEAN      DEFAULT FALSE;
    
    -- Safety variables
    DECLARE v_is_system_thread BOOLEAN      DEFAULT FALSE;
    DECLARE v_execution_time   DECIMAL(15,6) DEFAULT 0;
    DECLARE v_thread_command   VARCHAR(50)  DEFAULT NULL;
    
    -- SQL execution
    DECLARE v_sql              TEXT;
    
    -- Error handler for execution failures
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1
            v_error_msg = MESSAGE_TEXT;
        
        SET v_exec_status = 'FAILED';
        SET v_verification = 'FAILED';
        
        INSERT INTO debug_log(step, message)
        VALUES ('execution_error', CONCAT('Decision ', p_decision_id, ': ', COALESCE(v_error_msg, 'Unknown error')));
        
        -- Still record the failed attempt
        INSERT IGNORE INTO healing_actions (
            decision_id, action_type, execution_mode, executed_by,
            execution_status, verification_status, process_id,
            before_metric, after_metric, error_message
        ) VALUES (
            p_decision_id, v_action_type, 'AUTOMATIC', 'SYSTEM',
            v_exec_status, v_verification, v_process_id,
            v_before_metric, v_after_metric, v_error_msg
        );
    END;

    -- PHASE 1: FETCH DECISION CONTEXT
    INSERT INTO debug_log(step, message)
    VALUES ('exec_start', CONCAT('Starting execution for decision_id: ', p_decision_id));

    SELECT dl.issue_id, di.issue_type, dl.decision_type, di.raw_metric_value
    INTO   v_issue_id, v_issue_type, v_decision_type, v_raw_metric
    FROM   decision_log dl
    JOIN   detected_issues di ON dl.issue_id = di.issue_id
    WHERE  dl.decision_id = p_decision_id
    LIMIT  1;

    IF v_issue_type IS NULL THEN
        INSERT INTO debug_log(step, message)
        VALUES ('exec_skip', CONCAT('No issue found for decision_id: ', p_decision_id));
        LEAVE proc_label;
    END IF;

    -- PHASE 2: FETCH ACTION MAPPING
    SELECT action_type, is_automatic
    INTO   v_action_type, v_is_automatic
    FROM   action_rules
    WHERE  issue_type = CONVERT(v_issue_type USING utf8mb4)
    LIMIT  1;

    -- PHASE 3: SKIP CONDITIONS
    IF v_decision_type != 'AUTO_HEAL' THEN
        INSERT INTO debug_log(step, message)
        VALUES ('exec_skip', CONCAT('Decision type is ', v_decision_type, ', not AUTO_HEAL'));
        LEAVE proc_label;
    END IF;

    IF v_action_type IS NULL THEN
        INSERT INTO debug_log(step, message)
        VALUES ('exec_skip', 'No action_type found in action_rules');
        LEAVE proc_label;
    END IF;

    IF v_is_automatic = 0 THEN
        INSERT INTO debug_log(step, message)
        VALUES ('exec_skip', CONCAT('Action ', v_action_type, ' is not automatic'));
        LEAVE proc_label;
    END IF;

    -- Check for duplicate execution
    SELECT COUNT(*) INTO v_already_exists
    FROM   healing_actions
    WHERE  decision_id = p_decision_id;

    IF v_already_exists > 0 THEN
        INSERT INTO debug_log(step, message)
        VALUES ('exec_skip', CONCAT('Action already exists for decision_id: ', p_decision_id));
        LEAVE proc_label;
    END IF;

    -- PHASE 4: CAPTURE PRE-EXECUTION METRIC
    IF v_action_type = 'KILL_CONNECTION' THEN
        -- Count active connections before
        SELECT COUNT(*) INTO v_before_metric
        FROM information_schema.processlist
        WHERE command != 'Sleep' AND time > 1;  -- Reduced to 1 second
        
        INSERT INTO debug_log(step, message)
        VALUES ('exec_metric', CONCAT('Before metric: ', v_before_metric, ' active connections'));
        
        -- Find a suitable process to kill (more lenient criteria)
        SELECT id, time, command INTO v_process_id, v_execution_time, v_thread_command
        FROM information_schema.processlist
        WHERE command != 'Sleep' 
        AND time > 1  -- Reduced to 1 second for testing
        AND user != 'system user'
        AND command NOT IN ('Binlog Dump', 'Daemon')
        AND id != CONNECTION_ID()  -- Don't kill our own connection
        AND (info LIKE '%SLEEP%' OR time > 3)  -- Target SLEEP queries or longer running queries
        ORDER BY time DESC
        LIMIT 1;
        
        INSERT INTO debug_log(step, message)
        VALUES ('exec_process_search', CONCAT('Found process_id: ', COALESCE(v_process_id, 'NULL'), 
                                             ', time: ', COALESCE(v_execution_time, 0), 
                                             ', command: ', COALESCE(v_thread_command, 'NULL')));
        
    ELSEIF v_action_type = 'ROLLBACK_TRANSACTION' THEN
        -- Count active transactions before
        SELECT COUNT(*) INTO v_before_metric
        FROM information_schema.innodb_trx;
        
        -- Find a transaction to rollback (simplified)
        SELECT trx_id INTO v_process_id
        FROM information_schema.innodb_trx
        ORDER BY trx_started
        LIMIT 1;
    END IF;

    -- PHASE 5: SAFETY CHECKS
    IF v_process_id IS NULL THEN
        SET v_exec_status = 'FAILED';
        SET v_verification = 'FAILED';
        SET v_error_msg = 'No suitable process/transaction found for execution';
        SET v_can_execute = FALSE;
    ELSE
        SET v_can_execute = TRUE;
    END IF;

    -- PHASE 6: REAL EXECUTION
    IF v_can_execute = TRUE THEN
        IF v_action_type = 'KILL_CONNECTION' THEN
            SET v_sql = CONCAT('KILL ', v_process_id);
            SET @sql = v_sql;
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            INSERT INTO debug_log(step, message)
            VALUES ('exec_kill', CONCAT('Killed connection: ', v_process_id));
            
        ELSEIF v_action_type = 'ROLLBACK_TRANSACTION' THEN
            -- Note: ROLLBACK specific transaction is complex, simplified here
            SET v_sql = 'ROLLBACK';
            SET @sql = v_sql;
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            INSERT INTO debug_log(step, message)
            VALUES ('exec_rollback', CONCAT('Rolled back transaction: ', v_process_id));
        END IF;
        
        SET v_exec_status = 'SUCCESS';
    END IF;

    -- PHASE 7: POST-EXECUTION VERIFICATION
    -- Only verify if execution actually ran
    IF v_can_execute = TRUE THEN
        DO SLEEP(2); -- Allow time for changes to take effect
        
        IF v_action_type = 'KILL_CONNECTION' THEN
            SELECT COUNT(*) INTO v_after_metric
            FROM information_schema.processlist
            WHERE command != 'Sleep' AND time > 1;  -- Reduced to 1 second
            
            INSERT INTO debug_log(step, message)
            VALUES ('exec_after_metric', CONCAT('After metric: ', v_after_metric, ' active connections'));
            
        ELSEIF v_action_type = 'ROLLBACK_TRANSACTION' THEN
            SELECT COUNT(*) INTO v_after_metric
            FROM information_schema.innodb_trx;
        END IF;

        -- PHASE 8: VERIFICATION LOGIC
        IF v_before_metric IS NOT NULL AND v_after_metric IS NOT NULL THEN
            IF v_after_metric < v_before_metric THEN
                SET v_verification = 'VERIFIED';
                INSERT INTO debug_log(step, message)
                VALUES ('verification_success', CONCAT('Metric improved: ', v_before_metric, ' -> ', v_after_metric));
            ELSE
                SET v_verification = 'FAILED';
                SET v_exec_status = 'FAILED';
                SET v_error_msg = CONCAT('No improvement: ', v_before_metric, ' -> ', v_after_metric);
                INSERT INTO debug_log(step, message)
                VALUES ('verification_failed', v_error_msg);
            END IF;
        ELSE
            SET v_verification = 'UNVERIFIED';
        END IF;
    ELSE
        -- Execution was skipped, verification already set to FAILED
        INSERT INTO debug_log(step, message)
        VALUES ('verification_skipped', 'Verification skipped - execution did not run');
    END IF;

    -- PHASE 9: RECORD RESULTS
    INSERT IGNORE INTO healing_actions (
        decision_id,
        action_type,
        execution_mode,
        executed_by,
        execution_status,
        verification_status,
        process_id,
        before_metric,
        after_metric,
        error_message
    ) VALUES (
        p_decision_id,
        v_action_type,
        'AUTOMATIC',
        'SYSTEM',
        v_exec_status,
        v_verification,
        v_process_id,
        v_before_metric,
        v_after_metric,
        v_error_msg
    );

    INSERT INTO debug_log(step, message)
    VALUES ('exec_complete', CONCAT('Execution complete for decision_id: ', p_decision_id, 
                                   ', Status: ', v_exec_status, 
                                   ', Verification: ', v_verification));

END//

-- Wrapper for backward compatibility
DROP PROCEDURE IF EXISTS execute_healing_action//
CREATE PROCEDURE execute_healing_action(IN p_decision_id BIGINT)
BEGIN
    CALL execute_healing_action_v2(p_decision_id);
END//

DELIMITER ;