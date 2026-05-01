/*!40101 SET NAMES utf8mb4 */;
DELIMITER //

DROP PROCEDURE IF EXISTS collect_system_metrics//
CREATE PROCEDURE collect_system_metrics()
BEGIN
    DECLARE v_active_queries INT;
    DECLARE v_lock_waits INT;
    DECLARE v_connections INT;
    DECLARE v_throughput DECIMAL(15,2);

    -- [1] Fetch High-Level System Stats
    SELECT COUNT(*) INTO v_active_queries 
    FROM information_schema.processlist 
    WHERE command = 'Query' AND info IS NOT NULL;

    SELECT COUNT(*) INTO v_lock_waits 
    FROM information_schema.innodb_trx 
    WHERE trx_state = 'LOCK WAIT';

    -- [2] Use Global Status for Connections and Throughput
    SELECT VARIABLE_VALUE INTO v_connections 
    FROM performance_schema.global_status 
    WHERE VARIABLE_NAME = 'Threads_connected';

    -- Estimated Throughput (Queries per second)
    -- We can calculate this better by comparing delta of Queries status
    INSERT INTO system_metrics (active_queries, lock_waits, connections, throughput)
    VALUES (v_active_queries, v_lock_waits, v_connections, 0.0);
END //

DELIMITER ;
