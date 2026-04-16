-- ============================================================================
-- FIX: DUPLICATE PREVENTION FOR SLOW QUERY DETECTION
-- ============================================================================
-- Bug: Signature includes TIME which changes every second
-- Fix: Use only process_id as stable identifier
-- ============================================================================

DELIMITER $

DROP PROCEDURE IF EXISTS detect_slow_queries$

CREATE PROCEDURE detect_slow_queries()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_process_id BIGINT;
    DECLARE v_query_time INT;
    DECLARE v_query_text TEXT;
    DECLARE v_signature VARCHAR(255);
    
    DECLARE slow_query_cursor CURSOR FOR
        SELECT 
            ID,
            TIME,
            SUBSTRING(INFO, 1, 100) as query_snippet
        FROM information_schema.processlist
        WHERE 
            COMMAND != 'Sleep'
            AND COMMAND != 'Daemon'
            AND TIME > 10
            AND INFO IS NOT NULL
            AND INFO NOT LIKE '%detect_slow_queries%'
            AND INFO NOT LIKE '%information_schema%'
            AND USER != 'event_scheduler'
        ORDER BY TIME DESC
        LIMIT 5;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN slow_query_cursor;
    
    read_loop: LOOP
        FETCH slow_query_cursor INTO v_process_id, v_query_time, v_query_text;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- FIXED: Use only process_id for signature (stable identifier)
        -- BEFORE: SET v_signature = CONCAT('SLOW_QUERY_', v_process_id, '_', v_query_time);
        -- AFTER:
        SET v_signature = CONCAT('SLOW_QUERY_', v_process_id);
        
        -- Check if this process was detected recently (within last 5 minutes)
        IF NOT EXISTS (
            SELECT 1 FROM issue_detection_cache
            WHERE issue_signature = v_signature
            AND last_detected_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
        ) THEN
            INSERT INTO detected_issues 
                (issue_type, detection_source, raw_metric_value, raw_metric_unit)
            VALUES 
                ('SLOW_QUERY', 'PERFORMANCE_SCHEMA', v_query_time, 'seconds');
            
            INSERT INTO issue_detection_cache (issue_signature, last_detected_at)
            VALUES (v_signature, NOW())
            ON DUPLICATE KEY UPDATE last_detected_at = NOW();
        END IF;
        
    END LOOP;
    
    CLOSE slow_query_cursor;
    
    DELETE FROM issue_detection_cache 
    WHERE last_detected_at < DATE_SUB(NOW(), INTERVAL 1 HOUR);
    
END$

DELIMITER ;
