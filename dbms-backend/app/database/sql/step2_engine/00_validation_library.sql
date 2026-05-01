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
            -- Advanced Impact Analysis: Check if threads_running is also high
            SELECT COUNT(*) INTO v_active_queries
            FROM information_schema.processlist
            WHERE command = 'Query' AND time > v_dynamic_thresh;

            IF v_active_queries >= 1 THEN
                -- Also check system pressure (Load factor)
                SELECT connections INTO v_lock_waits FROM system_metrics ORDER BY metric_id DESC LIMIT 1;
                IF v_lock_waits > 10 OR v_active_queries > 3 THEN SET p_issue_exists = TRUE; END IF;
            END IF;

        WHEN 'CONNECTION_OVERLOAD' THEN
            -- [PHASE 7] Burst Detection via Query Normalization
            SELECT normalize_query_pattern(info) INTO v_query_pattern
            FROM information_schema.processlist
            WHERE command = 'Query' AND info IS NOT NULL
              AND user NOT IN ('system user', 'event_scheduler')
            ORDER BY time DESC LIMIT 1;

            SET v_pattern_hash = SHA2(v_query_pattern, 256);

            -- Count occurrences of the SAME pattern
            SELECT COUNT(*) INTO v_active_queries
            FROM information_schema.processlist
            WHERE normalize_query_pattern(info) = v_query_pattern
              AND command = 'Query';

            IF v_active_queries >= 3 THEN SET p_issue_exists = TRUE; END IF;

        WHEN 'DEADLOCK' THEN
            -- Use system_metrics for multi-source verification
            SELECT lock_waits INTO v_lock_waits FROM system_metrics ORDER BY metric_id DESC LIMIT 1;
            IF v_lock_waits >= 1 THEN SET p_issue_exists = TRUE; END IF;

        ELSE
            SET p_issue_exists = FALSE;
    END CASE;
END //

DELIMITER ;
