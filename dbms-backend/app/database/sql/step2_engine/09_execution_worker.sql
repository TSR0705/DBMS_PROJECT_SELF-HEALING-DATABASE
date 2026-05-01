/*!40101 SET NAMES utf8mb4 */;
DELIMITER //

DROP PROCEDURE IF EXISTS run_execution_worker//
CREATE PROCEDURE run_execution_worker()
proc_label: BEGIN
    DECLARE v_queue_id    BIGINT;
    DECLARE v_decision_id BIGINT;
    DECLARE v_retry_count INT;
    DECLARE v_max_retries INT;
    DECLARE v_exec_status VARCHAR(10);
    DECLARE v_error_msg   TEXT;
    DECLARE v_lock        INT DEFAULT 0;

    -- [1] CONCURRENCY SHIELD (Global Semaphore)
    -- We use GET_LOCK to prevent multiple workers from overlapping on heavy operations
    SELECT GET_LOCK('execution_worker_global_lock', 2) INTO v_lock;
    IF v_lock = 0 THEN 
        INSERT INTO debug_log(step, message) VALUES ('worker_skip', 'Another worker is active');
        LEAVE proc_label; 
    END IF;

    -- [2] ATOMIC TASK SELECTION
    -- Using FOR UPDATE SKIP LOCKED ensures no two threads pick the same task
    -- (Requires MySQL 8.0+)
    BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION 
        BEGIN 
            DO RELEASE_LOCK('execution_worker_global_lock');
        END;

        SELECT queue_id, decision_id, retry_count, max_retries
        INTO v_queue_id, v_decision_id, v_retry_count, v_max_retries
        FROM execution_queue
        WHERE status IN ('PENDING', 'FAILED') -- Allow retrying failed tasks
          AND retry_count < max_retries
        ORDER BY priority_score DESC, created_at ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED;

        IF v_queue_id IS NULL THEN
            DO RELEASE_LOCK('execution_worker_global_lock');
            LEAVE proc_label;
        END IF;

        -- [3] LIFECYCLE TRANSITION: PROCESSING
        UPDATE execution_queue 
        SET status = 'PROCESSING', updated_at = NOW() 
        WHERE queue_id = v_queue_id;

        -- [4] EXECUTION
        CALL execute_healing_action_v2(v_decision_id);
        CALL update_learning_v2(v_decision_id);

        -- [5] VERIFY OUTCOME FROM HEALING_ACTIONS
        SELECT execution_status, error_message 
        INTO v_exec_status, v_error_msg
        FROM healing_actions 
        WHERE decision_id = v_decision_id 
        ORDER BY action_id DESC LIMIT 1;

        -- [6] LIFECYCLE TRANSITION: COMPLETION/RETRY
        IF v_exec_status = 'SUCCESS' OR v_exec_status = 'SKIPPED' THEN
            -- Success or Clean Skip (Issue self-healed)
            UPDATE execution_queue 
            SET status = 'COMPLETED', updated_at = NOW() 
            WHERE queue_id = v_queue_id;
            
            -- Optional: Cleanup completed tasks older than 1 hour
            DELETE FROM execution_queue WHERE status = 'COMPLETED' AND updated_at < (NOW() - INTERVAL 1 HOUR);
        ELSE
            -- Failed: Increment retry or mark as FAILED
            IF v_retry_count + 1 < v_max_retries THEN
                UPDATE execution_queue 
                SET status = 'PENDING', 
                    retry_count = retry_count + 1,
                    last_error = v_error_msg,
                    updated_at = NOW()
                WHERE queue_id = v_queue_id;
            ELSE
                UPDATE execution_queue 
                SET status = 'FAILED',
                    retry_count = retry_count + 1,
                    last_error = CONCAT('Max retries exceeded: ', COALESCE(v_error_msg, 'Unknown error')),
                    updated_at = NOW()
                WHERE queue_id = v_queue_id;
            END IF;
        END IF;

        DO RELEASE_LOCK('execution_worker_global_lock');
    END;
END //

DELIMITER ;
