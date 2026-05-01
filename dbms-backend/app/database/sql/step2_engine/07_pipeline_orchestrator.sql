/*!40101 SET NAMES utf8mb4 */;
DELIMITER //

DROP PROCEDURE IF EXISTS run_auto_heal_pipeline//
CREATE PROCEDURE run_auto_heal_pipeline()
proc_label: BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_issue_id BIGINT;
    DECLARE v_lock INT DEFAULT 0;
    
    DECLARE issue_cursor CURSOR FOR 
        SELECT d.issue_id
        FROM detected_issues d
        LEFT JOIN ai_analysis a ON d.issue_id = a.issue_id
        WHERE a.issue_id IS NULL
        ORDER BY d.detected_at ASC
        LIMIT 20;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        IF v_lock = 1 THEN DO RELEASE_LOCK('auto_heal_pipeline_lock'); END IF;
    END;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SELECT GET_LOCK('auto_heal_pipeline_lock', 0) INTO v_lock;

    IF v_lock = 1 THEN
        -- [1] ANALYSIS & DECISION PHASE (Populates execution_queue)
        OPEN issue_cursor;
        read_loop: LOOP
            FETCH issue_cursor INTO v_issue_id;
            IF done THEN LEAVE read_loop; END IF;
            
            CALL run_ai_analysis(v_issue_id);
            CALL make_decision(v_issue_id);
        END LOOP;
        CLOSE issue_cursor;

        -- [2] EXECUTION PHASE (Drains execution_queue)
        CALL run_execution_worker();

        DO RELEASE_LOCK('auto_heal_pipeline_lock');
    END IF;
END //

DELIMITER ;
