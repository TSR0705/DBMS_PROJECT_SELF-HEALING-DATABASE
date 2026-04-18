/*!40101 SET NAMES utf8mb4 */;
USE dbms_self_healing;

-- P1: Fix ENUM
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE healing_actions;
TRUNCATE TABLE decision_log;
TRUNCATE TABLE learning_history;

-- Clean duplicates out of action_rules so we can apply UNIQUE index to action_type.
DELETE FROM action_rules WHERE issue_type = 'SLOW_QUERY' AND action_type = 'KILL_CONNECTION';
INSERT IGNORE INTO action_rules (issue_type, action_type, is_automatic) VALUES ('SLOW_QUERY', 'ADD_INDEX', 1);

SET FOREIGN_KEY_CHECKS = 1;

ALTER TABLE action_rules ADD UNIQUE INDEX idx_action_type (action_type);

ALTER TABLE healing_actions 
  MODIFY COLUMN action_type VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  ADD CONSTRAINT fk_healing_action_type FOREIGN KEY (action_type) REFERENCES action_rules(action_type) ON UPDATE CASCADE;

-- P2: Add decision_id to learning_history
ALTER TABLE learning_history 
  ADD COLUMN decision_id BIGINT,
  ADD CONSTRAINT uq_learning_decision UNIQUE (decision_id);

-- P6: Add multi-metric grouping ID
ALTER TABLE detected_issues ADD COLUMN issue_group_id BIGINT DEFAULT NULL;
ALTER TABLE detected_issues ADD INDEX idx_issue_group (issue_group_id);
