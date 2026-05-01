DELIMITER //

DROP PROCEDURE IF EXISTS run_verification_worker//
CREATE PROCEDURE run_verification_worker()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_queue_id BIGINT;
    DECLARE v_issue_id BIGINT;
    DECLARE v_issue_exists BOOLEAN;
    
    -- [1] Identify tasks awaiting verification
    -- Tasks where worker finished (SUCCESS in context) but queue is still PROCESSING
    DECLARE verify_cursor CURSOR FOR 
        SELECT q.queue_id, dl.issue_id
        FROM execution_queue q
        JOIN execution_context ec USING(queue_id)
        JOIN decision_log dl ON q.decision_id = dl.decision_id
        WHERE q.status = 'PROCESSING'
          AND ec.status = 'SUCCESS'
        LIMIT 10;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN verify_cursor;
    read_loop: LOOP
        FETCH verify_cursor INTO v_queue_id, v_issue_id;
        IF done THEN LEAVE read_loop; END IF;
        
        -- [2] JUDGE: Re-validate system state
        CALL validate_issue_state(v_issue_id, v_issue_exists);
        
        IF v_issue_exists = FALSE THEN
            -- Healing Verified!
            UPDATE execution_queue 
            SET status = 'COMPLETED', updated_at = NOW() 
            WHERE queue_id = v_queue_id;
        ELSE
            -- Healing Failed Verification (System still under stress)
            UPDATE execution_queue 
            SET status = 'FAILED', last_error = 'Verification failed: Issue still active', updated_at = NOW()
            WHERE queue_id = v_queue_id;
            
            UPDATE execution_context 
            SET status = 'FAILED', error_message = 'Verification failed: Root cause persists'
            WHERE queue_id = v_queue_id;
        END IF;
    END LOOP;
    CLOSE verify_cursor;
END //

DELIMITER ;
