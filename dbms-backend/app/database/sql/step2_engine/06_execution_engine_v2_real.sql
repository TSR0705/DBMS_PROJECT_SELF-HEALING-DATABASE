/*!40101 SET NAMES utf8mb4 */;
SET collation_connection = 'utf8mb4_unicode_ci';

-- ============================================================
-- PHASE 1: REAL EXECUTION WITH VERIFICATION
-- ============================================================
-- Columns before_metric, after_metric, verification_status,
-- process_id, error_message are defined in the base schema
-- (dbms_self_healing.sql). No ALTER TABLE needed here.
-- ============================================================

-- ============================================================
-- STEP 2: ENHANCED EXECUTION ENGINE
-- execute_healing_action_v2 - Real execution with verification
-- ============================================================
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

    -- ========================================
    -- PHASE 1: FETCH DECISION CONTEXT
    -- ========================================
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

    -- ========================================
    -- PHASE 2: FETCH ACTION MAPPING
    -- ========================================
    SELECT action_type, is_automatic
    INTO   v_action_type, v_is_automatic
    FROM   action_rules
    WHERE  issue_type = CONVERT(v_issue_type USING utf8mb4)
    LIMIT  1;

    -- ========================================
    -- PHASE 3: SKIP CONDITIONS (BACKWARD COMPATIBLE)
    -- ========================================
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

    -- ========================================
    -- PHASE 4: CAPTURE PRE-EXECUTION METRIC
    -- ========================================
    IF v_action_type = 'KILL_CONNECTION' THEN
        -- Count active connections before
        SELECT COUNT(*) INTO v_before_metric
        FROM information_schema.processlist
        WHERE command != 'Sleep' AND time > 10;
        
        INSERT INTO debug_log(step, message)
        VALUES ('metric_before', CONCAT('Active connections before: ', v_before_metric));
    
    ELSEIF v_action_type = 'ROLLBACK_TRANSACTION' THEN
        -- Count active transactions before
        SELECT COUNT(*) INTO v_before_metric
        FROM information_schema.innodb_trx;
        
        INSERT INTO debug_log(step, message)
        VALUES ('metric_before', CONCAT('Active transactions before: ', v_before_metric));
    END IF;

    -- ========================================
    -- PHASE 5: REAL EXECUTION LOGIC
    -- ========================================
    
    -- ========================================
    -- ACTION: KILL_CONNECTION
    -- ========================================
    IF v_action_type = 'KILL_CONNECTION' THEN
        
        -- Find the longest running non-system connection
        SELECT id, time, command
        INTO v_process_id, v_execution_time, v_thread_command
        FROM information_schema.processlist
        WHERE command != 'Sleep'
          AND command != 'Binlog Dump'
          AND command != 'Daemon'
          AND user != 'system user'
          AND user != 'event_scheduler'
          AND time > 10  -- Only kill connections running > 10 seconds
        ORDER BY time DESC
        LIMIT 1;
        
        -- Safety validation
        IF v_process_id IS NOT NULL THEN
            -- Additional safety: check it's not a replication thread
            SELECT COUNT(*) INTO v_is_system_thread
            FROM information_schema.processlist
            WHERE id = v_process_id
              AND (user = 'system user' OR command IN ('Binlog Dump', 'Daemon'));
            
            IF v_is_system_thread = 0 THEN
                SET v_can_execute = TRUE;
                
                INSERT INTO debug_log(step, message)
                VALUES ('exec_kill', CONCAT('Killing process_id: ', v_process_id, 
                                           ', time: ', v_execution_time, 
                                           's, command: ', v_thread_command));
                
                -- REAL EXECUTION: KILL CONNECTION
                SET @sql = CONCAT('KILL ', v_process_id);
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
                
                SET v_exec_status = 'SUCCESS';
                
                INSERT INTO debug_log(step, message)
                VALUES ('exec_success', CONCAT('Successfully killed process_id: ', v_process_id));
            ELSE
                SET v_exec_status = 'FAILED';
                SET v_error_msg = 'Target process is a system thread - execution blocked for safety';
                
                INSERT INTO debug_log(step, message)
                VALUES ('exec_blocked', v_error_msg);
            END IF;
        ELSE
            SET v_exec_status = 'FAILED';
            SET v_error_msg = 'No eligible process found to kill (all connections < 10s or system threads)';
            
            INSERT INTO debug_log(step, message)
            VALUES ('exec_failed', v_error_msg);
        END IF;
    
    -- ========================================
    -- ACTION: ROLLBACK_TRANSACTION
    -- ========================================
    ELSEIF v_action_type = 'ROLLBACK_TRANSACTION' THEN
        
        -- Find the oldest transaction
        SELECT trx_id, trx_started, TIMESTAMPDIFF(SECOND, trx_started, NOW())
        INTO @trx_id, @trx_started, v_execution_time
        FROM information_schema.innodb_trx
        ORDER BY trx_started ASC
        LIMIT 1;
        
        IF @trx_id IS NOT NULL THEN
            SET v_can_execute = TRUE;
            
            INSERT INTO debug_log(step, message)
            VALUES ('exec_rollback', CONCAT('Rolling back transaction: ', @trx_id, 
                                           ', age: ', v_execution_time, 's'));
            
            -- REAL EXECUTION: ROLLBACK (via KILL)
            -- Note: MySQL doesn't allow direct ROLLBACK of other transactions
            -- We need to kill the connection that owns the transaction
            SELECT processlist_id INTO v_process_id
            FROM information_schema.innodb_trx
            WHERE trx_id = @trx_id
            LIMIT 1;
            
            IF v_process_id IS NOT NULL THEN
                SET @sql = CONCAT('KILL ', v_process_id);
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
                
                SET v_exec_status = 'SUCCESS';
                
                INSERT INTO debug_log(step, message)
                VALUES ('exec_success', CONCAT('Successfully rolled back transaction via KILL ', v_process_id));
            ELSE
                SET v_exec_status = 'FAILED';
                SET v_error_msg = 'Could not find process_id for transaction';
            END IF;
        ELSE
            SET v_exec_status = 'FAILED';
            SET v_error_msg = 'No active transactions found to rollback';
            
            INSERT INTO debug_log(step, message)
            VALUES ('exec_failed', v_error_msg);
        END IF;
    
    -- ========================================
    -- UNSUPPORTED ACTIONS (FUTURE)
    -- ========================================
    ELSE
        SET v_exec_status = 'FAILED';
        SET v_error_msg = CONCAT('Action type not supported for real execution: ', v_action_type);
        
        INSERT INTO debug_log(step, message)
        VALUES ('exec_unsupported', v_error_msg);
    END IF;

    -- ========================================
    -- PHASE 6: POST-EXECUTION VERIFICATION
    -- ========================================
    IF v_exec_status = 'SUCCESS' THEN
        -- Small delay to allow metrics to update
        DO SLEEP(2);
        
        IF v_action_type = 'KILL_CONNECTION' THEN
            -- Count active connections after
            SELECT COUNT(*) INTO v_after_metric
            FROM information_schema.processlist
            WHERE command != 'Sleep' AND time > 10;
            
            INSERT INTO debug_log(step, message)
            VALUES ('metric_after', CONCAT('Active connections after: ', v_after_metric));
            
            -- Verify improvement
            IF v_after_metric < v_before_metric THEN
                SET v_verification = 'VERIFIED';
                INSERT INTO debug_log(step, message)
                VALUES ('verification', CONCAT('SUCCESS: Connections reduced from ', 
                                              v_before_metric, ' to ', v_after_metric));
            ELSE
                SET v_verification = 'FAILED';
                SET v_exec_status = 'FAILED';
                INSERT INTO debug_log(step, message)
                VALUES ('verification', CONCAT('FAILED: No improvement (', 
                                              v_before_metric, ' -> ', v_after_metric, ')'));
            END IF;
        
        ELSEIF v_action_type = 'ROLLBACK_TRANSACTION' THEN
            -- Count active transactions after
            SELECT COUNT(*) INTO v_after_metric
            FROM information_schema.innodb_trx;
            
            INSERT INTO debug_log(step, message)
            VALUES ('metric_after', CONCAT('Active transactions after: ', v_after_metric));
            
            -- Verify improvement
            IF v_after_metric < v_before_metric THEN
                SET v_verification = 'VERIFIED';
                INSERT INTO debug_log(step, message)
                VALUES ('verification', CONCAT('SUCCESS: Transactions reduced from ', 
                                              v_before_metric, ' to ', v_after_metric));
            ELSE
                SET v_verification = 'FAILED';
                SET v_exec_status = 'FAILED';
                INSERT INTO debug_log(step, message)
                VALUES ('verification', CONCAT('FAILED: No improvement (', 
                                              v_before_metric, ' -> ', v_after_metric, ')'));
            END IF;
        END IF;
    ELSE
        SET v_verification = 'FAILED';
    END IF;

    -- ========================================
    -- PHASE 7: RECORD HEALING ACTION
    -- ========================================
    INSERT INTO healing_actions (
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
                                   ', status: ', v_exec_status, 
                                   ', verification: ', v_verification));

END //

DELIMITER ;

-- ============================================================
-- STEP 3: ENHANCED LEARNING ENGINE
-- update_learning_v2 - Real learning from verified outcomes
-- ============================================================
DELIMITER //

DROP PROCEDURE IF EXISTS update_learning_v2//
CREATE PROCEDURE update_learning_v2(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_type        VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_action_type       VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_exec_status       VARCHAR(10)  CHARACTER SET utf8mb4;
    DECLARE v_verification      VARCHAR(20)  CHARACTER SET utf8mb4;
    DECLARE v_confidence_before DECIMAL(5,4) DEFAULT 0.0;
    DECLARE v_confidence_after  DECIMAL(5,4) DEFAULT 0.0;
    DECLARE v_already_learned   INT          DEFAULT 0;
    DECLARE v_outcome           VARCHAR(20)  CHARACTER SET utf8mb4;
    DECLARE v_before_metric     DECIMAL(15,6) DEFAULT NULL;
    DECLARE v_after_metric      DECIMAL(15,6) DEFAULT NULL;

    INSERT INTO debug_log(step, message)
    VALUES ('learning_start', CONCAT('Starting learning for decision_id: ', p_decision_id));

    -- ========================================
    -- PHASE 1: FETCH VERIFIED EXECUTION RESULTS
    -- ========================================
    SELECT ha.action_type,
           ha.execution_status,
           ha.verification_status,
           ha.before_metric,
           ha.after_metric,
           LEAST(GREATEST(dl.confidence_at_decision, 0.0), 0.9999)
    INTO   v_action_type, v_exec_status, v_verification, 
           v_before_metric, v_after_metric, v_confidence_before
    FROM   healing_actions ha
    JOIN   decision_log dl ON ha.decision_id = dl.decision_id
    WHERE  ha.decision_id = p_decision_id
    LIMIT  1;

    IF v_action_type IS NULL THEN
        INSERT INTO debug_log(step, message)
        VALUES ('learning_skip', CONCAT('No healing action found for decision_id: ', p_decision_id));
        LEAVE proc_label;
    END IF;

    -- Skip if execution was skipped (backward compatible)
    IF v_exec_status = 'SKIPPED' THEN
        INSERT INTO debug_log(step, message)
        VALUES ('learning_skip', 'Execution was skipped, no learning needed');
        LEAVE proc_label;
    END IF;

    -- ========================================
    -- PHASE 2: DETERMINE REAL OUTCOME
    -- ========================================
    -- CRITICAL: Use VERIFIED status, not just execution_status
    IF v_verification = 'VERIFIED' AND v_exec_status = 'SUCCESS' THEN
        SET v_outcome = 'RESOLVED';
        SET v_confidence_after = LEAST(v_confidence_before + 0.05, 0.9999);
        
        INSERT INTO debug_log(step, message)
        VALUES ('learning_outcome', CONCAT('VERIFIED SUCCESS: confidence ', 
                                          v_confidence_before, ' -> ', v_confidence_after));
    ELSE
        SET v_outcome = 'FAILED';
        SET v_confidence_after = GREATEST(v_confidence_before - 0.05, 0.0);
        
        INSERT INTO debug_log(step, message)
        VALUES ('learning_outcome', CONCAT('FAILED/UNVERIFIED: confidence ', 
                                          v_confidence_before, ' -> ', v_confidence_after));
    END IF;

    -- ========================================
    -- PHASE 3: FETCH ISSUE TYPE
    -- ========================================
    SELECT di.issue_type
    INTO   v_issue_type
    FROM   decision_log dl
    JOIN   detected_issues di ON dl.issue_id = di.issue_id
    WHERE  dl.decision_id = p_decision_id
    LIMIT  1;

    IF v_issue_type IS NULL THEN
        INSERT INTO debug_log(step, message)
        VALUES ('learning_skip', 'Could not find issue_type');
        LEAVE proc_label;
    END IF;

    -- ========================================
    -- PHASE 4: PREVENT DUPLICATE LEARNING
    -- ========================================
    SELECT COUNT(*) INTO v_already_learned
    FROM   learning_history
    WHERE  issue_type  = CONVERT(v_issue_type  USING utf8mb4)
      AND  action_type = CONVERT(v_action_type USING utf8mb4)
      AND  recorded_at >= NOW() - INTERVAL 60 SECOND;

    IF v_already_learned > 0 THEN
        INSERT INTO debug_log(step, message)
        VALUES ('learning_skip', 'Duplicate learning record within 60 seconds');
        LEAVE proc_label;
    END IF;

    -- ========================================
    -- PHASE 5: RECORD REAL LEARNING
    -- ========================================
    INSERT INTO learning_history (
        issue_type,
        action_type,
        outcome,
        confidence_before,
        confidence_after
    ) VALUES (
        CONVERT(v_issue_type  USING utf8mb4),
        CONVERT(v_action_type USING utf8mb4),
        v_outcome,
        v_confidence_before,
        v_confidence_after
    );

    INSERT INTO debug_log(step, message)
    VALUES ('learning_complete', CONCAT('Learning recorded: ', v_issue_type, 
                                       ' + ', v_action_type, 
                                       ' = ', v_outcome,
                                       ' (metrics: ', v_before_metric, ' -> ', v_after_metric, ')'));

END //

DELIMITER ;

-- ============================================================
-- STEP 4: BACKWARD COMPATIBLE WRAPPERS
-- Keep old procedure names pointing to new versions
-- ============================================================
DELIMITER //

DROP PROCEDURE IF EXISTS execute_healing_action//
CREATE PROCEDURE execute_healing_action(IN p_decision_id BIGINT)
BEGIN
    -- Redirect to new version
    CALL execute_healing_action_v2(p_decision_id);
END //

DROP PROCEDURE IF EXISTS update_learning//
CREATE PROCEDURE update_learning(IN p_decision_id BIGINT)
BEGIN
    -- Redirect to new version
    CALL update_learning_v2(p_decision_id);
END //

DELIMITER ;

-- ============================================================
-- STEP 5: VALIDATION QUERIES
-- ============================================================

-- Verify new columns exist
SELECT 
    COLUMN_NAME, 
    DATA_TYPE, 
    COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'healing_actions'
  AND COLUMN_NAME IN ('before_metric', 'after_metric', 'verification_status', 'process_id', 'error_message');

-- Verify procedures exist
SELECT 
    ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE()
  AND ROUTINE_NAME IN ('execute_healing_action_v2', 'update_learning_v2', 'execute_healing_action', 'update_learning')
ORDER BY ROUTINE_NAME;

-- ============================================================
-- COMPLETION LOG
-- ============================================================
INSERT INTO debug_log(step, message)
VALUES ('phase1_complete', 'PHASE 1: Real Execution with Verification - DEPLOYED');

SELECT 'PHASE 1 DEPLOYMENT COMPLETE' AS status,
       'Real execution enabled for KILL_CONNECTION and ROLLBACK_TRANSACTION' AS message,
       'All existing procedures remain backward compatible' AS compatibility,
       'Verification layer active' AS verification,
       'Real learning from verified outcomes' AS learning;
