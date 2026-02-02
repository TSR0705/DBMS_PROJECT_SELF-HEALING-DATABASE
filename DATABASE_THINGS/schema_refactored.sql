DROP TABLE IF EXISTS learning_history;
DROP TABLE IF EXISTS admin_reviews;
DROP TABLE IF EXISTS healing_actions;
DROP TABLE IF EXISTS decision_log;
DROP TABLE IF EXISTS ai_analysis;
DROP TABLE IF EXISTS detected_issues;

CREATE TABLE detected_issues (
  issue_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  detected_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  detection_source ENUM ('PERFORMANCE_SCHEMA', 'SLOW_QUERY_LOG', 'INNODB_DEADLOCK', 'METRICS_OTHER') NOT NULL,
  target_resource_type VARCHAR(100) NOT NULL,
  target_resource_name VARCHAR(255) NOT NULL,
  severity_level ENUM ('WARNING', 'CRITICAL') NOT NULL,
  metric_value DECIMAL(20,4) NOT NULL CHECK (metric_value >= 0),
  description TEXT,
  INDEX idx_timestamp (detected_timestamp),
  INDEX idx_source (detection_source),
  INDEX idx_resource (target_resource_type, target_resource_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE ai_analysis (
  analysis_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  issue_id BIGINT UNSIGNED NOT NULL,
  analyzed_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  confidence_score DECIMAL(3,2) NOT NULL CHECK (confidence_score BETWEEN 0.00 AND 1.00),
  root_cause_hypothesis TEXT NOT NULL,
  suggested_action_category ENUM ('INDEX_TUNING', 'QUERY_OPTIMIZATION', 'CACHE_TUNING', 'CONNECTION_TUNING', 'NONE') NOT NULL,
  CONSTRAINT fk_analysis_issue FOREIGN KEY (issue_id) REFERENCES detected_issues(issue_id) ON DELETE RESTRICT,
  INDEX idx_issue (issue_id),
  INDEX idx_timestamp (analyzed_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE decision_log (
  decision_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  analysis_id BIGINT UNSIGNED NOT NULL,
  decision_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  decision_type ENUM ('AUTO_HEAL', 'ADMIN_REVIEW') NOT NULL,
  rationale TEXT,
  CONSTRAINT fk_decision_analysis FOREIGN KEY (analysis_id) REFERENCES ai_analysis(analysis_id) ON DELETE RESTRICT,
  INDEX idx_analysis (analysis_id),
  INDEX idx_timestamp (decision_timestamp),
  INDEX idx_type (decision_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE healing_actions (
  action_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  decision_id BIGINT UNSIGNED NOT NULL,
  action_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  action_description TEXT NOT NULL,
  action_type ENUM ('INDEX_CREATE', 'QUERY_HINT', 'CACHE_FLUSH', 'CONNECTION_LIMIT', 'NONE') NOT NULL,
  execution_status ENUM ('PENDING', 'EXECUTED', 'FAILED') NOT NULL DEFAULT 'PENDING',
  result_summary TEXT,
  CONSTRAINT fk_action_decision FOREIGN KEY (decision_id) REFERENCES decision_log(decision_id) ON DELETE RESTRICT,
  INDEX idx_decision (decision_id),
  INDEX idx_timestamp (action_timestamp),
  INDEX idx_status (execution_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE admin_reviews (
  review_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  decision_id BIGINT UNSIGNED NOT NULL,
  reviewer_name VARCHAR(255),
  review_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  approval_status ENUM ('APPROVED', 'REJECTED', 'DEFERRED') NOT NULL,
  review_comment TEXT,
  CONSTRAINT fk_review_decision FOREIGN KEY (decision_id) REFERENCES decision_log(decision_id) ON DELETE RESTRICT,
  INDEX idx_decision (decision_id),
  INDEX idx_timestamp (review_timestamp),
  INDEX idx_status (approval_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE learning_history (
  record_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  issue_id BIGINT UNSIGNED NOT NULL,
  action_id BIGINT UNSIGNED,
  learning_timestamp TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  was_resolved BOOLEAN,
  ai_confidence_at_time DECIMAL(3,2),
  outcome_notes TEXT,
  INDEX idx_issue (issue_id),
  INDEX idx_timestamp (learning_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
