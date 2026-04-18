DELIMITER //

DROP PROCEDURE IF EXISTS update_learning//
CREATE PROCEDURE update_learning(
    IN p_decision_id BIGINT,
    IN p_outcome VARCHAR(20)
)
BEGIN
    DECLARE v_issue_type VARCHAR(255);
    DECLARE v_action_type VARCHAR(255);
    DECLARE v_resolution_time INT;

    SELECT issue_type, action_type, TIMESTAMPDIFF(SECOND, created_at, NOW()) 
    INTO v_issue_type, v_action_type, v_resolution_time
    FROM decision_log
    WHERE decision_id = p_decision_id
    LIMIT 1;

    IF v_issue_type IS NOT NULL THEN
        INSERT INTO learning_history (
            decision_id, issue_type, action_type, outcome, resolution_time, created_at
        ) VALUES (
            p_decision_id, v_issue_type, v_action_type, p_outcome, v_resolution_time, NOW()
        );
    END IF;
END //

DELIMITER ;
