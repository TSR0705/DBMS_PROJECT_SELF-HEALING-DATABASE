CREATE TABLE IF NOT EXISTS action_rules (
    rule_id INT AUTO_INCREMENT PRIMARY KEY,
    issue_type VARCHAR(255) NOT NULL,
    action_type VARCHAR(255) NOT NULL,
    is_automatic BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_issue_action (issue_type, action_type)
) ENGINE=InnoDB;
