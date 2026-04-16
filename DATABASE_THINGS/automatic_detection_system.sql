-- ============================================================================
-- AUTOMATIC DETECTION SYSTEM FOR AI-ASSISTED SELF-HEALING DATABASE
-- ============================================================================
-- This extends the existing manual detection system with real-time automation
-- WITHOUT modifying existing tables or breaking the workflow
-- ============================================================================

-- ============================================================================
-- STEP 1: ANALYZE EXISTING SYSTEM
-- ============================================================================
/*
CURRENT STATE:
- Detection is MANUAL via INSERT statements into detected_issues table
- Example: INSERT INTO detected_issues (issue_type, detection_source, ...) VALUES (...)
- This is unrealistic for production systems

PROBLEM:
- No real-time monitoring
- Requires manual intervention to detect issues
- Cannot catch issues as they happen
- Not scalable or practical

EXISTING WORKFLOW (MUST BE PRESERVED):
detected_issues → (trigger) → decision_log → (trigger) → healing_actions/admin_reviews → (trigger) → learning_history

SOLUTION:
- Use MySQL EVENT SCHEDULER to automatically detect issues
- Query information_schema.processlist for slow queries
- Insert detected issues into detected_issues table
- Existing triggers handle the rest automatically
*/

-- ============================================================================
-- STEP 2: DESIGN AUTOMATIC DETECTION STRATEGY
-- ============================================================================
/*
DETECTION SOURCES (MySQL-native only):
1. information_schema.processlist - Active queries and their execution time
2. information_schema.innodb_trx - Active transactions (for deadlocks)
3. SHOW STATUS - Connection counts

ISSUES TO DETECT:
1. SLOW_QUERY - Queries running longer than threshold (10 seconds)
2. CONNECTION_OVERLOAD - Too many active connections (>150)
3. TRANSACTION_FAILURE - Long-running transactions (>30 seconds)
4. DEADLOCK - Detected from InnoDB status (limited in MySQL)

THRESHOLDS:
- Slow query: TIME > 10 seconds
- Connection overload: Threads_connected > 150
- Transaction timeout: trx_started > 30 seconds ago
*/

-- ============================================================================
-- STEP 3: CREATE HELPER TABLE FOR DUPLICATE PREVENTION
-- ============================================================================
-- This table tracks recently detected issues to prevent duplicate logging

DROP TABLE IF EXISTS issue_detection_cache;

CREATE TABLE issue_detection_cache (
    cache_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    issue_signature VARCHAR(255) NOT NULL,
    last_detected_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY idx_signature (issue_signature),
    KEY idx_time (last_detected_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================================
-- STEP 4: CREATE DETECTION PROCEDURES
-- ============================================================================

-- ----------------------------------------------------------------------------
-- PROCEDURE 1: Detect Slow Queries
-- ----------------------------------------------------------------------------
DELIMITER $$

DROP PROCEDURE IF EXISTS detect_slow_queries$$

CREATE PROCEDURE detect_slow_queries()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_process_id BIGINT;
    DECLARE v_query_time INT;
    DECLARE v_query_text TEXT;
    DECLARE v_signature VARCHAR(255);
    
    -- Cursor to find slow queries
    DECLARE slow_query_cursor CURSOR FOR
        SELECT 
            ID,
            TIME,
            SUBSTRING(INFO, 1, 100) as query_snippet
        FROM information_schema.processlist
        WHERE 
            COMMAND != 'Sleep'                    -- Exclude idle connections
            AND COMMAND != 'Daemon'               -- Exclude system processes
            AND TIME > 10                         -- Queries running > 10 seconds
            AND INFO IS NOT NULL                  -- Must have query text
            AND INFO NOT LIKE '%detect_slow_queries%'  -- Exclude this procedure
            AND INFO NOT LIKE '%information_schema%'   -- Exclude monitoring queries
            AND USER != 'event_scheduler'         -- Exclude event scheduler
        ORDER BY TIME DESC
        LIMIT 5;                                  -- Limit to top 5 slow queries
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN slow_query_cursor;
    
    read_loop: LOOP
        FETCH slow_query_cursor INTO v_process_id, v_query_time, v_query_text;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Create unique signature for this issue
        SET v_signature = CONCAT('SLOW_QUERY_', v_process_id, '_', v_query_time);
        
        -- Check if this issue was detected recently (within last 5 minutes)
        IF NOT EXISTS (
            SELECT 1 FROM issue_detection_cache
            WHERE issue_signature = v_signature
            AND last_detected_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
        ) THEN
            -- Insert into detected_issues (triggers will handle the rest)
            INSERT INTO detected_issues 
                (issue_type, detection_source, raw_metric_value, raw_metric_unit)
            VALUES 
                ('SLOW_QUERY', 'PERFORMANCE_SCHEMA', v_query_time, 'seconds');
            
            -- Cache this detection
            INSERT INTO issue_detection_cache (issue_signature, last_detected_at)
            VALUES (v_signature, NOW())
            ON DUPLICATE KEY UPDATE last_detected_at = NOW();
        END IF;
        
    END LOOP;
    
    CLOSE slow_query_cursor;
    
    -- Cleanup old cache entries (older than 1 hour)
    DELETE FROM issue_detection_cache 
    WHERE last_detected_at < DATE_SUB(NOW(), INTERVAL 1 HOUR);
    
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCEDURE 2: Detect Connection Overload
-- ----------------------------------------------------------------------------
DELIMITER $$

DROP PROCEDURE IF EXISTS detect_connection_overload$$

CREATE PROCEDURE detect_connection_overload()
BEGIN
    DECLARE v_connection_count INT;
    DECLARE v_max_connections INT;
    DECLARE v_signature VARCHAR(255);
    
    -- Get current connection count
    SELECT VARIABLE_VALUE INTO v_connection_count
    FROM performance_schema.global_status
    WHERE VARIABLE_NAME = 'Threads_connected';
    
    -- Get max connections setting
    SELECT VARIABLE_VALUE INTO v_max_connections
    FROM performance_schema.global_variables
    WHERE VARIABLE_NAME = 'max_connections';
    
    -- Threshold: 75% of max_connections or absolute 150
    IF v_connection_count > LEAST(v_max_connections * 0.75, 150) THEN
        
        SET v_signature = CONCAT('CONNECTION_OVERLOAD_', DATE_FORMAT(NOW(), '%Y%m%d%H%i'));
        
        -- Check if detected recently (within last 5 minutes)
        IF NOT EXISTS (
            SELECT 1 FROM issue_detection_cache
            WHERE issue_signature = v_signature
            AND last_detected_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
        ) THEN
            -- Insert detection
            INSERT INTO detected_issues 
                (issue_type, detection_source, raw_metric_value, raw_metric_unit)
            VALUES 
                ('CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', v_connection_count, 'connections');
            
            -- Cache detection
            INSERT INTO issue_detection_cache (issue_signature, last_detected_at)
            VALUES (v_signature, NOW())
            ON DUPLICATE KEY UPDATE last_detected_at = NOW();
        END IF;
    END IF;
    
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCEDURE 3: Detect Long-Running Transactions
-- ----------------------------------------------------------------------------
DELIMITER $$

DROP PROCEDURE IF EXISTS detect_long_transactions$$

CREATE PROCEDURE detect_long_transactions()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_trx_id VARCHAR(50);
    DECLARE v_trx_duration INT;
    DECLARE v_signature VARCHAR(255);
    
    -- Cursor for long-running transactions
    DECLARE trx_cursor CURSOR FOR
        SELECT 
            trx_id,
            TIMESTAMPDIFF(SECOND, trx_started, NOW()) as duration_seconds
        FROM information_schema.innodb_trx
        WHERE TIMESTAMPDIFF(SECOND, trx_started, NOW()) > 30  -- Transactions > 30 seconds
        ORDER BY trx_started ASC
        LIMIT 5;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN trx_cursor;
    
    read_loop: LOOP
        FETCH trx_cursor INTO v_trx_id, v_trx_duration;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET v_signature = CONCAT('TRANSACTION_', v_trx_id);
        
        -- Check if detected recently
        IF NOT EXISTS (
            SELECT 1 FROM issue_detection_cache
            WHERE issue_signature = v_signature
            AND last_detected_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
        ) THEN
            -- Insert detection
            INSERT INTO detected_issues 
                (issue_type, detection_source, raw_metric_value, raw_metric_unit)
            VALUES 
                ('TRANSACTION_FAILURE', 'INNODB', v_trx_duration, 'seconds');
            
            -- Cache detection
            INSERT INTO issue_detection_cache (issue_signature, last_detected_at)
            VALUES (v_signature, NOW())
            ON DUPLICATE KEY UPDATE last_detected_at = NOW();
        END IF;
        
    END LOOP;
    
    CLOSE trx_cursor;
    
END$$

DELIMITER ;

-- ----------------------------------------------------------------------------
-- PROCEDURE 4: Master Detection Procedure (calls all detectors)
-- ----------------------------------------------------------------------------
DELIMITER $$

DROP PROCEDURE IF EXISTS run_automatic_detection$$

CREATE PROCEDURE run_automatic_detection()
BEGIN
    -- Run all detection procedures
    CALL detect_slow_queries();
    CALL detect_connection_overload();
    CALL detect_long_transactions();
END$$

DELIMITER ;

-- ============================================================================
-- STEP 5: ENABLE EVENT SCHEDULER
-- ============================================================================

-- Check if event scheduler is enabled
SET GLOBAL event_scheduler = ON;

-- Verify event scheduler status
SHOW VARIABLES LIKE 'event_scheduler';

-- ============================================================================
-- STEP 6: CREATE AUTOMATED EVENT
-- ============================================================================

-- Drop existing event if it exists
DROP EVENT IF EXISTS auto_detect_issues;

-- Create event that runs every 1 minute
DELIMITER $$

CREATE EVENT auto_detect_issues
ON SCHEDULE EVERY 1 MINUTE
STARTS CURRENT_TIMESTAMP
DO
BEGIN
    -- Call master detection procedure
    CALL run_automatic_detection();
END$$

DELIMITER ;

-- Verify event was created
SHOW EVENTS WHERE Name = 'auto_detect_issues';

-- ============================================================================
-- STEP 7: VERIFICATION & TESTING
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TEST CASE 1: Simulate Slow Query
-- ----------------------------------------------------------------------------
/*
-- Run this in a separate MySQL session to test slow query detection:

SELECT SLEEP(15), 'This is a test slow query' as test_query;

-- Wait 1-2 minutes, then check:
SELECT * FROM detected_issues 
WHERE issue_type = 'SLOW_QUERY' 
ORDER BY detected_at DESC 
LIMIT 5;
*/

-- ----------------------------------------------------------------------------
-- TEST CASE 2: Simulate Long Transaction
-- ----------------------------------------------------------------------------
/*
-- Run this in a separate session:

START TRANSACTION;
SELECT * FROM test_table WHERE id = 1 FOR UPDATE;
-- Don't commit, wait 35+ seconds

-- In another session, check:
SELECT * FROM information_schema.innodb_trx;

-- Wait for detection event to run, then check:
SELECT * FROM detected_issues 
WHERE issue_type = 'TRANSACTION_FAILURE' 
ORDER BY detected_at DESC 
LIMIT 5;

-- Don't forget to ROLLBACK or COMMIT the transaction
*/

-- ----------------------------------------------------------------------------
-- TEST CASE 3: Check Detection Cache
-- ----------------------------------------------------------------------------
/*
-- View what's been detected recently:
SELECT * FROM issue_detection_cache ORDER BY last_detected_at DESC;

-- View detection statistics:
SELECT 
    issue_type,
    COUNT(*) as detection_count,
    MAX(detected_at) as last_detected,
    AVG(raw_metric_value) as avg_metric
FROM detected_issues
WHERE detected_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY issue_type;
*/

-- ============================================================================
-- STEP 8: MONITORING & MAINTENANCE QUERIES
-- ============================================================================

-- Check if event scheduler is running
SELECT @@event_scheduler;

-- View all events
SELECT * FROM information_schema.events 
WHERE event_schema = 'dbms_self_healing';

-- Check recent detections
SELECT 
    di.issue_id,
    di.issue_type,
    di.detection_source,
    di.raw_metric_value,
    di.raw_metric_unit,
    di.detected_at,
    dl.decision_type,
    ha.execution_status
FROM detected_issues di
LEFT JOIN decision_log dl ON di.issue_id = dl.issue_id
LEFT JOIN healing_actions ha ON dl.decision_id = ha.decision_id
WHERE di.detected_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY di.detected_at DESC;

-- View detection rate (issues per minute)
SELECT 
    DATE_FORMAT(detected_at, '%Y-%m-%d %H:%i') as minute_bucket,
    COUNT(*) as issues_detected
FROM detected_issues
WHERE detected_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
GROUP BY minute_bucket
ORDER BY minute_bucket DESC;

-- ============================================================================
-- STEP 9: SAFETY CONTROLS
-- ============================================================================

-- To temporarily disable automatic detection:
-- ALTER EVENT auto_detect_issues DISABLE;

-- To re-enable:
-- ALTER EVENT auto_detect_issues ENABLE;

-- To stop event scheduler completely:
-- SET GLOBAL event_scheduler = OFF;

-- To adjust detection frequency (e.g., every 2 minutes):
/*
ALTER EVENT auto_detect_issues
ON SCHEDULE EVERY 2 MINUTE;
*/

-- ============================================================================
-- STEP 10: PERFORMANCE IMPACT ANALYSIS
-- ============================================================================

-- Check event execution history (MySQL 8.0+)
SELECT 
    event_name,
    status,
    last_executed,
    TIMESTAMPDIFF(SECOND, last_executed, NOW()) as seconds_since_last_run
FROM information_schema.events
WHERE event_schema = 'dbms_self_healing';

-- Monitor detection procedure performance
-- (Run this before and after to measure impact)
SHOW PROCESSLIST;

-- ============================================================================
-- DOCUMENTATION
-- ============================================================================
/*
WHAT WAS ADDED:
1. issue_detection_cache table - Prevents duplicate detections
2. detect_slow_queries() - Detects queries running > 10 seconds
3. detect_connection_overload() - Detects when connections > 150
4. detect_long_transactions() - Detects transactions > 30 seconds
5. run_automatic_detection() - Master procedure calling all detectors
6. auto_detect_issues event - Runs every 1 minute automatically

WHAT WAS NOT MODIFIED:
- detected_issues table structure (unchanged)
- ai_analysis table (unchanged)
- decision_log table (unchanged)
- healing_actions table (unchanged)
- admin_reviews table (unchanged)
- learning_history table (unchanged)
- All existing triggers (unchanged)

HOW IT WORKS:
1. Event scheduler runs every 1 minute
2. Calls run_automatic_detection()
3. Each detector queries system tables
4. If issue found and not recently detected:
   - Inserts into detected_issues
   - Existing triggers handle rest of workflow
5. Detection cached to prevent duplicates

SAFETY FEATURES:
- Duplicate prevention (5-minute window)
- Limited to top 5 issues per type
- Excludes monitoring queries from detection
- Automatic cache cleanup (1-hour retention)
- Can be disabled without breaking system

THRESHOLDS (CONFIGURABLE):
- Slow query: 10 seconds
- Connection overload: 150 connections or 75% of max
- Long transaction: 30 seconds
- Duplicate window: 5 minutes
- Cache retention: 1 hour

TESTING:
- Use SELECT SLEEP(15) to test slow query detection
- Use long transactions to test transaction detection
- Monitor issue_detection_cache for duplicate prevention
- Check detected_issues table for automatic insertions
*/

-- ============================================================================
-- END OF AUTOMATIC DETECTION SYSTEM
-- ============================================================================
