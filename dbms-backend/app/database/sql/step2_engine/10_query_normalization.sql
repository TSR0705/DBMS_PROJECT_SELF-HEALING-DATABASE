/*!40101 SET NAMES utf8mb4 */;
DELIMITER //

DROP FUNCTION IF EXISTS normalize_query_pattern//
CREATE FUNCTION normalize_query_pattern(p_query TEXT) RETURNS TEXT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_normalized TEXT;
    
    -- [1] Basic Cleanup
    SET v_normalized = TRIM(p_query);
    
    -- [2] Replace numeric literals
    SET v_normalized = REGEXP_REPLACE(v_normalized, '[0-9]+', '?');
    
    -- [3] Replace string literals (single quotes)
    SET v_normalized = REGEXP_REPLACE(v_normalized, "'[^']*'", '?');
    
    -- [4] Replace string literals (double quotes)
    SET v_normalized = REGEXP_REPLACE(v_normalized, '"[^"]*"', '?');
    
    -- [5] Normalize whitespace
    SET v_normalized = REGEXP_REPLACE(v_normalized, '[[:space:]]+', ' ');
    
    RETURN v_normalized;
END //

DELIMITER ;
