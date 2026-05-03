/*!40101 SET NAMES utf8mb4 */;
DELIMITER //

DROP PROCEDURE IF EXISTS validate_issue_state//
CREATE PROCEDURE validate_issue_state(
    IN  p_issue_id     BIGINT,
    OUT p_issue_exists BOOLEAN
)
BEGIN
    DECLARE v_issue_type       VARCHAR(255);
    DECLARE v_active_queries   INT DEFAULT 0;
    DECLARE v_lock_waits       INT DEFAULT 0;
    DECLARE v_dummy_id         BIGINT DEFAULT NULL;
    DECLARE v_dynamic_thresh   DECIMAL(10,2) DEFAULT 20;
    DECLARE v_query_pattern    TEXT;
    DECLARE v_pattern_hash     VARCHAR(64);

    SET p_issue_exists = FALSE;

    -- [1] Capture Current System Snapshot
    CALL collect_system_metrics();

    -- [2] Fetch Context
    SELECT issue_type, raw_metric_value 
    INTO v_issue_type, v_dynamic_thresh
    FROM detected_issues
    WHERE issue_id = p_issue_id LIMIT 1;

    CASE v_issue_type
        WHEN 'SLOW_QUERY' THEN
            -- [FIXED] Simple existence check - any slow query is an issue
            -- Use 50% of threshold or minimum 15 seconds to avoid false positives
            SELECT COUNT(*) INTO v_active_queries
            FROM information_schema.processlist
            WHERE command = 'Query' 
              AND time >= GREATEST(15, v_dynamic_thresh * 0.5)
              AND info IS NOT NULL
              AND user NOT IN ('system user', 'event_scheduler');

            -- Debug logging
            INSERT INTO debug_log(step, message) 
            VALUES ('slow_query_validation', CONCAT('Active slow queries: ', v_active_queries, ', threshold: ', v_dynamic_thresh));

            -- SIMPLE RULE: If slow query exists, it's an issue
            IF v_active_queries >= 1 THEN 
                SET p_issue_exists = TRUE; 
            END IF;

        WHEN 'CONNECTION_OVERLOAD' THEN
            -- [PHASE 7] Burst Detection via Query Normalization
            SELECT normalize_query_pattern(info) INTO v_query_pattern
            FROM information_schema.processlist
            WHERE command = 'Query' AND info IS NOT NULL
              AND user NOT IN ('system user', 'event_scheduler')
            GROUP BY normalize_query_pattern(info)
            ORDER BY COUNT(*) DESC LIMIT 1;

            SET v_pattern_hash = SHA2(v_query_pattern, 256);

            -- Count occurrences of the SAME pattern
            SELECT COUNT(*) INTO v_active_queries
            FROM information_schema.processlist
            WHERE normalize_query_pattern(info) = v_query_pattern
              AND command = 'Query';

            IF v_active_queries >= 3 THEN SET p_issue_exists = TRUE; END IF;

        WHEN 'DEADLOCK' THEN
            -- [PHASE 7] Simple Truth: Direct check on system lock table
            -- Previous logic using system_metrics was too stale or indirect
            SELECT COUNT(*) INTO v_lock_waits
            FROM sys.innodb_lock_waits;

            -- Debug logging
            INSERT INTO debug_log(step, message)
            VALUES ('deadlock_validation', CONCAT('Lock waits detected: ', v_lock_waits));

            IF v_lock_waits > 0 THEN
                SET p_issue_exists = TRUE;
            ELSE
                SET p_issue_exists = FALSE;
            END IF;
        
        WHEN 'SECURITY_POLICY_VIOLATION' THEN
            -- DYNAMIC: Check for any user with '%' (wildcard) host and GRANT privileges
            -- This is a real security risk in many DBMS environments
            SELECT COUNT(*) INTO v_active_queries
            FROM mysql.user 
            WHERE host = '%' AND (Grant_priv = 'Y' OR Super_priv = 'Y');
            
            IF v_active_queries > 0 THEN SET p_issue_exists = TRUE; END IF;
            
        WHEN 'OPTIMIZATION_SUGGESTION' THEN
            -- DYNAMIC: Check for tables with significant fragmentation (> 10MB data_free)
            -- This is a real performance metric that requires OPTIMIZE TABLE
            SELECT COUNT(*) INTO v_active_queries
            FROM information_schema.tables
            WHERE data_free > 10 * 1024 * 1024 -- 10MB fragmentation
              AND table_schema = 'dbms_self_healing';
            
            IF v_active_queries > 0 THEN SET p_issue_exists = TRUE; END IF;

        ELSE
            SET p_issue_exists = FALSE;
    END CASE;
END //

DELIMITER ;
