/*!40101 SET NAMES utf8mb4 */;
USE dbms_self_healing;

-- P3: Admin Reviews unique constraint
-- Ensure table exists first just in case
CREATE TABLE IF NOT EXISTS admin_reviews (
    review_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    decision_id BIGINT NOT NULL,
    issue_id BIGINT NOT NULL,
    review_status VARCHAR(50) DEFAULT 'PENDING'
);

-- Clean duplicates before applying unique constraint
TRUNCATE TABLE admin_reviews;

-- Drop index if exists to avoid error, or just add it if fresh
SET @exist := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_name = 'admin_reviews' AND index_name = 'uk_decision_id' AND table_schema = 'dbms_self_healing');
SET @sqlstmt := if( @exist > 0, 'SELECT 1', 'ALTER TABLE admin_reviews ADD UNIQUE INDEX uk_decision_id (decision_id)');
PREPARE stmt FROM @sqlstmt;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
