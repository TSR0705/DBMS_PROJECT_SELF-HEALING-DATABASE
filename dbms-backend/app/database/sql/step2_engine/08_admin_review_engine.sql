/*!40101 SET NAMES utf8mb4 */;
DELIMITER //

DROP PROCEDURE IF EXISTS process_admin_review//
CREATE PROCEDURE process_admin_review(
    IN p_decision_id BIGINT,
    IN p_status VARCHAR(20)
)
proc_label: BEGIN
    DECLARE v_review_id BIGINT;
    DECLARE v_issue_id  BIGINT;
    DECLARE v_exists    INT;

    -- [1] Find Review Record
    SELECT review_id, issue_id INTO v_review_id, v_issue_id
    FROM admin_reviews
    WHERE decision_id = p_decision_id
    ORDER BY review_id DESC LIMIT 1;

    IF v_review_id IS NULL THEN LEAVE proc_label; END IF;

    -- [2] Process Approval/Rejection
    IF p_status = 'APPROVE' THEN
        -- Update Review Record
        UPDATE admin_reviews 
        SET review_status = 'APPROVED', 
            reviewed_at = NOW(),
            admin_comment = 'Approved by AI Demo System (Auto-Triggered)'
        WHERE review_id = v_review_id;

        -- Update Decision Log with Approved Status
        UPDATE decision_log 
        SET decision_reason = CONCAT(decision_reason, ' [ADMIN_APPROVED]')
        WHERE decision_id = p_decision_id;

        -- Trigger Execution
        CALL execute_healing_action_v2(p_decision_id);
    ELSE
        -- Process Rejection
        UPDATE admin_reviews 
        SET review_status = 'REJECTED', 
            reviewed_at = NOW(),
            admin_comment = 'Rejected by AI Demo System (Auto-Triggered)'
        WHERE review_id = v_review_id;

        -- Update Decision Log
        UPDATE decision_log 
        SET decision_reason = CONCAT(decision_reason, ' [ADMIN_REJECTED]')
        WHERE decision_id = p_decision_id;
        
        -- Insert into learning history as REJECTED
        CALL update_learning(p_decision_id, 'REJECTED');
    END IF;
END //

DELIMITER ;
