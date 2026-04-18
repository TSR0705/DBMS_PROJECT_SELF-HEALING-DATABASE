CREATE TABLE IF NOT EXISTS decision_log (
    decision_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    issue_id BIGINT NOT NULL,
    issue_type VARCHAR(255) NOT NULL,
    action_type VARCHAR(255) NULL,
    severity_level VARCHAR(20) NOT NULL,
    confidence_score DECIMAL(15,6) NULL,
    decision_type VARCHAR(50) NOT NULL,
    decision_score DECIMAL(15,6) NOT NULL,
    decision_reason VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_issue_decision (issue_id)
) ENGINE=InnoDB;
