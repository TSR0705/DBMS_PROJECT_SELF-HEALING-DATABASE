DELIMITER //

DROP PROCEDURE IF EXISTS get_issue_features//
CREATE PROCEDURE get_issue_features(
    IN p_issue_id BIGINT,
    OUT p_issue_type VARCHAR(255),
    OUT p_raw_metric DECIMAL(15,6),
    OUT p_metric_group VARCHAR(20)
)
BEGIN
    SELECT 
        CAST(issue_type AS CHAR), 
        COALESCE(NULLIF(raw_metric_value, 0), 0.000001)
    INTO 
        p_issue_type, 
        p_raw_metric
    FROM detected_issues
    WHERE issue_id = p_issue_id
    LIMIT 1;

    CASE
        WHEN p_raw_metric < 100 THEN SET p_metric_group = 'LOW';
        WHEN p_raw_metric < 1000 THEN SET p_metric_group = 'MEDIUM';
        ELSE SET p_metric_group = 'HIGH';
    END CASE;
END //

DELIMITER ;
