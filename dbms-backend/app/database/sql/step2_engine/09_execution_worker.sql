/*!40101 SET NAMES utf8mb4 */;
DELIMITER //

DROP PROCEDURE IF EXISTS run_execution_worker//
CREATE PROCEDURE run_execution_worker(IN p_worker_id VARCHAR(100))
proc_label: BEGIN
    DECLARE v_queue_id    BIGINT DEFAULT NULL;
    DECLARE v_decision_id BIGINT;
    DECLARE v_issue_type  VARCHAR(255);
    DECLARE v_retry_count INT;
    DECLARE v_max_retries INT DEFAULT 3;
    DECLARE v_exec_status VARCHAR(10);
    DECLARE v_error_msg   TEXT;
    DECLARE v_cooldown    INT DEFAULT 30;
    DECLARE v_retry_safe   BOOLEAN DEFAULT TRUE;

    -- [1] WORKER HEARTBEAT
    INSERT INTO worker_registry (worker_id, status, last_heartbeat)
    VALUES (p_worker_id, 'ACTIVE', NOW())
    ON DUPLICATE KEY UPDATE last_heartbeat = NOW(), status = 'ACTIVE';

    -- [2] ATOMIC MULTI-WORKER TASK CLAIM
    START TRANSACTION;
        SELECT q.queue_id, q.decision_id, q.retry_count, di.issue_type
        INTO v_queue_id, v_decision_id, v_retry_count, v_issue_type
        FROM execution_queue q
        JOIN decision_log dl ON q.decision_id = dl.decision_id
        JOIN detected_issues di ON dl.issue_id = di.issue_id
        WHERE q.status IN ('PENDING', 'FAILED')
          AND q.retry_count < v_max_retries
        ORDER BY q.priority_score DESC, q.created_at ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED; -- [PHASE 7] Parallel-safe row locking

        IF v_queue_id IS NOT NULL THEN
            -- [3] ADAPTIVE THROTTLING CHECK
            SELECT cooldown_time INTO v_cooldown FROM throttle_state WHERE issue_type = v_issue_type;
            
            -- Check if same issue type triggered within dynamic cooldown
            IF EXISTS (
                SELECT 1 FROM healing_actions ha 
                JOIN decision_log dl2 ON ha.decision_id = dl2.decision_id
                JOIN detected_issues di2 ON dl2.issue_id = di2.issue_id
                WHERE di2.issue_type = v_issue_type 
                  AND ha.executed_at > (NOW() - INTERVAL COALESCE(v_cooldown, 30) SECOND)
            ) THEN
                -- Escalate cooldown if system metrics show no improvement
                UPDATE throttle_state 
                SET cooldown_time = LEAST(cooldown_time * 2, 300), escalation_level = escalation_level + 1
                WHERE issue_type = v_issue_type;
                
                UPDATE execution_queue SET status = 'FAILED', last_error = 'Throttled (Adaptive)', updated_at = NOW() WHERE queue_id = v_queue_id;
                SET v_queue_id = NULL;
            ELSE
                UPDATE execution_queue SET status = 'PROCESSING', last_attempt_time = NOW(), updated_at = NOW() WHERE queue_id = v_queue_id;
                
                -- [CONTEXT] Track execution start independently (Parallel-safe retry)
                INSERT INTO execution_context (queue_id, decision_id, status, worker_id, last_heartbeat, started_at, completed_at, error_message)
                VALUES (v_queue_id, v_decision_id, 'RUNNING', p_worker_id, NOW(), NOW(), NULL, NULL)
                ON DUPLICATE KEY UPDATE 
                    status = 'RUNNING', 
                    worker_id = p_worker_id, 
                    last_heartbeat = NOW(), 
                    started_at = NOW(),
                    completed_at = NULL,
                    error_message = NULL;
            END IF;
        END IF;
    COMMIT;

    -- [4] EXECUTION & FAILURE CLASSIFICATION
    IF v_queue_id IS NOT NULL THEN
        -- [CONTEXT] Final heartbeat before execution
        UPDATE execution_context SET last_heartbeat = NOW() WHERE queue_id = v_queue_id;
        
        CALL execute_healing_action_v2(v_decision_id);
        
        SELECT execution_status, error_message INTO v_exec_status, v_error_msg
        FROM healing_actions WHERE decision_id = v_decision_id ORDER BY action_id DESC LIMIT 1;

        IF v_exec_status = 'SUCCESS' OR v_exec_status = 'SKIPPED' THEN
            -- [CONTEXT] Mark context as success, but queue remains PROCESSING for verification
            UPDATE execution_context SET status = 'SUCCESS', completed_at = NOW() WHERE queue_id = v_queue_id;
            
            -- Reset throttling on success
            UPDATE throttle_state SET cooldown_time = 30, escalation_level = 0 WHERE issue_type = v_issue_type;
        ELSE
            -- [5] FAILURE CLASSIFICATION ENGINE
            SET v_retry_safe = TRUE;
            IF v_error_msg LIKE '%Access denied%' OR v_error_msg LIKE '%Unknown column%' THEN
                SET v_retry_safe = FALSE; -- Permanent failure
            END IF;

            INSERT INTO failure_log (decision_id, error_type, retry_safe)
            VALUES (v_decision_id, IF(v_retry_safe, 'TRANSIENT', 'PERMANENT'), v_retry_safe);

            IF v_retry_safe THEN
                UPDATE execution_queue 
                SET status = 'FAILED', retry_count = retry_count + 1, last_error = v_error_msg, updated_at = NOW()
                WHERE queue_id = v_queue_id;
            ELSE
                UPDATE execution_queue 
                SET status = 'FAILED', retry_count = v_max_retries, last_error = CONCAT('PERMANENT: ', v_error_msg), updated_at = NOW()
                WHERE queue_id = v_queue_id;
            END IF;

            -- [CONTEXT] Mark context as failed
            UPDATE execution_context 
            SET status = 'FAILED', completed_at = NOW(), error_message = v_error_msg 
            WHERE queue_id = v_queue_id;
        END IF;
    END IF;
END //

DELIMITER ;
