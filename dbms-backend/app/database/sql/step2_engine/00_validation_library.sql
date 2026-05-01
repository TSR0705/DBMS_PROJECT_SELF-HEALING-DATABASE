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
    DECLARE v_lock_count       INT DEFAULT 0;
    DECLARE v_dummy_id         BIGINT DEFAULT NULL;
    DECLARE v_dynamic_thresh   DECIMAL(10,2) DEFAULT 20;

    SET p_issue_exists = FALSE;

    -- [1] Fetch Contextual Detection Data
    SELECT issue_type, raw_metric_value 
    INTO v_issue_type, v_dynamic_thresh
    FROM detected_issues
    WHERE issue_id = p_issue_id
    LIMIT 1;

    CASE v_issue_type
        WHEN 'SLOW_QUERY' THEN
            -- [STRICT] Dynamic threshold + System User Exclusion
            SELECT id INTO v_dummy_id
            FROM information_schema.processlist
            WHERE command = 'Query' 
              AND time > GREATEST(15, v_dynamic_thresh * 0.7)
              AND user NOT IN ('system user', 'event_scheduler', 'root')
              AND info IS NOT NULL
              AND info NOT LIKE '%validate_issue_state%'
            LIMIT 1;
            IF v_dummy_id IS NOT NULL THEN SET p_issue_exists = TRUE; END IF;

        WHEN 'CONNECTION_OVERLOAD' THEN
            -- [STRICT] Query Signature Signature (Query Grouping)
            SELECT COUNT(*) INTO v_active_queries
            FROM information_schema.processlist p1
            JOIN (
                -- Identify the exact query pattern causing the burst
                SELECT SUBSTRING(info, 1, 60) as signature
                FROM information_schema.processlist
                WHERE command = 'Query' AND info IS NOT NULL
                  AND user NOT IN ('system user', 'event_scheduler')
                GROUP BY signature
                ORDER BY COUNT(*) DESC
                LIMIT 1
            ) p2 ON SUBSTRING(p1.info, 1, 60) = p2.signature
            WHERE p1.command = 'Query' AND p1.time >= 2;
            
            IF v_active_queries >= 2 THEN SET p_issue_exists = TRUE; END IF;

        WHEN 'DEADLOCK' THEN
            -- [STRICT] Blocking Chain Grouping
            SELECT COUNT(waiting_trx_id) INTO v_lock_count
            FROM sys.innodb_lock_waits
            WHERE blocking_trx_id IS NOT NULL
            GROUP BY blocking_trx_id
            ORDER BY COUNT(waiting_trx_id) DESC
            LIMIT 1;
            
            IF v_lock_count >= 1 THEN SET p_issue_exists = TRUE; END IF;

        ELSE
            SET p_issue_exists = FALSE;
    END CASE;
END //

DELIMITER ;
