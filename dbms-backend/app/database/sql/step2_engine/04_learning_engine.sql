/*!40101 SET NAMES utf8mb4 */;
SET collation_connection = 'utf8mb4_unicode_ci';
DELIMITER //

CREATE TABLE IF NOT EXISTS learning_history (
    learning_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    issue_type VARCHAR(64) NOT NULL,
    action_type VARCHAR(64) NOT NULL,
    outcome ENUM('RESOLVED', 'FAILED') NOT NULL,
    confidence_before DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    confidence_after DECIMAL(5,4) NOT NULL DEFAULT 0.0,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_learning_issue_action (issue_type, action_type)
) ENGINE=InnoDB;

DROP PROCEDURE IF EXISTS compute_success_rate//
CREATE PROCEDURE compute_success_rate(
    IN p_issue_type VARCHAR(255),
    IN p_action_type VARCHAR(255),
    OUT p_success_rate DECIMAL(15,6)
)
BEGIN
    DECLARE v_total DECIMAL(15,6);
    DECLARE v_success DECIMAL(15,6);

    -- Calculate temporally weighted success bounds (Last 7 Days)
    SELECT 
        SUM(EXP(-DATEDIFF(NOW(), recorded_at)/3)),
        SUM(CASE WHEN outcome = 'RESOLVED' THEN EXP(-DATEDIFF(NOW(), recorded_at)/3) ELSE 0 END)
    INTO v_total, v_success
    FROM learning_history
    WHERE issue_type COLLATE utf8mb4_unicode_ci = CONVERT(p_issue_type USING utf8mb4) COLLATE utf8mb4_unicode_ci
      AND action_type COLLATE utf8mb4_unicode_ci = CONVERT(p_action_type USING utf8mb4) COLLATE utf8mb4_unicode_ci
      AND recorded_at >= NOW() - INTERVAL 7 DAY;

    IF v_total IS NULL OR v_total < 5 THEN
        -- Force Bayesian shrinkage on low sample sizes to prevent single-iteration feedback loops
        SET p_success_rate = (v_success + 2.0) / (v_total + 4.0);
    ELSE
        SET p_success_rate = v_success / v_total;
    END IF;
END //

DELIMITER ;
