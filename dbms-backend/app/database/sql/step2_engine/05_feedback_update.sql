DELIMITER //

DROP PROCEDURE IF EXISTS update_learning//
CREATE PROCEDURE update_learning(
    IN p_decision_id BIGINT,
    IN p_outcome VARCHAR(20)
)
proc_label: BEGIN
    DECLARE v_issue_type        VARCHAR(255);
    DECLARE v_action_type       VARCHAR(255);
    DECLARE v_confidence_before DECIMAL(5,4) DEFAULT 0.80;
    DECLARE v_confidence_after  DECIMAL(5,4);

    -- Fetch Context
    SELECT di.issue_type, COALESCE(h.action_type, 'MANUAL_REVIEW'), dl.confidence_at_decision
    INTO v_issue_type, v_action_type, v_confidence_before
    FROM decision_log dl
    JOIN detected_issues di ON dl.issue_id = di.issue_id
    LEFT JOIN healing_actions h ON dl.decision_id = h.decision_id
    WHERE dl.decision_id = p_decision_id
    LIMIT 1;

    IF v_issue_type IS NULL THEN LEAVE proc_label; END IF;

    -- Adjust confidence based on outcome
    IF p_outcome = 'RESOLVED' OR p_outcome = 'SUCCESS' THEN
        SET v_confidence_after = LEAST(v_confidence_before + 0.05, 0.9999);
    ELSE
        SET v_confidence_after = GREATEST(v_confidence_before - 0.05, 0.0001);
    END IF;

    -- Map p_outcome to ENUM('RESOLVED', 'FAILED')
    SET @mapped_outcome = IF(p_outcome IN ('RESOLVED', 'SUCCESS', 'APPROVED'), 'RESOLVED', 'FAILED');

    INSERT INTO learning_history (
        decision_id, issue_type, action_type, outcome, confidence_before, confidence_after
    ) VALUES (
        p_decision_id, v_issue_type, v_action_type, @mapped_outcome, v_confidence_before, v_confidence_after
    ) ON DUPLICATE KEY UPDATE outcome = @mapped_outcome, confidence_after = v_confidence_after;
    
END //

DELIMITER ;
