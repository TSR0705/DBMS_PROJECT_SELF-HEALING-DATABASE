/*!40101 SET NAMES utf8mb4 */;
USE dbms_self_healing;

CREATE TABLE IF NOT EXISTS debug_log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    step VARCHAR(50),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER //

DROP PROCEDURE IF EXISTS run_auto_heal_pipeline//
CREATE PROCEDURE run_auto_heal_pipeline()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_issue_id BIGINT;
    DECLARE v_lock INT DEFAULT 0;
    
    DECLARE issue_cursor CURSOR FOR 
        SELECT d.issue_id
        FROM detected_issues d
        LEFT JOIN ai_analysis a ON d.issue_id = a.issue_id
        WHERE a.issue_id IS NULL
        LIMIT 50;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO debug_log(step, message)
        VALUES ('error', 'Pipeline crashed');
        DO RELEASE_LOCK('auto_heal_pipeline_lock');
    END;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SELECT GET_LOCK('auto_heal_pipeline_lock', 1) INTO v_lock;

    IF v_lock = 1 THEN
        INSERT INTO debug_log(step, message) VALUES ('pipeline_start', 'Pipeline start');

        OPEN issue_cursor;
        read_loop: LOOP
            FETCH issue_cursor INTO v_issue_id;
            
            IF done THEN
                LEAVE read_loop;
            END IF;

            INSERT INTO debug_log(step, message) 
            VALUES ('pipeline', CONCAT('Processing issue_id: ', v_issue_id));

            CALL run_ai_analysis(v_issue_id);
            CALL make_decision(v_issue_id);
        END LOOP;
        
        CLOSE issue_cursor;

        INSERT INTO debug_log(step, message) VALUES ('pipeline_end', 'Pipeline end');

        DO RELEASE_LOCK('auto_heal_pipeline_lock');
    END IF;
END //

DELIMITER ;

SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS evt_auto_heal_pipeline;

CREATE EVENT evt_auto_heal_pipeline
ON SCHEDULE EVERY 10 SECOND
COMMENT 'Runs AI self-healing pipeline every 10 seconds'
DO
    CALL run_auto_heal_pipeline();
