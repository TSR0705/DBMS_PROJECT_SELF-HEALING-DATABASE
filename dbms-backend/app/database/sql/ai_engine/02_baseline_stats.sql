/*!40101 SET NAMES utf8mb4 */;
SET collation_connection = 'utf8mb4_unicode_ci';

DELIMITER //

DROP PROCEDURE IF EXISTS compute_baseline//
CREATE PROCEDURE compute_baseline(
    IN p_issue_id BIGINT,
    IN p_issue_type VARCHAR(255),
    IN p_metric_group VARCHAR(20),
    OUT p_avg DECIMAL(15,6),
    OUT p_std DECIMAL(15,6),
    OUT p_min DECIMAL(15,6),
    OUT p_max DECIMAL(15,6),
    OUT p_recent_anomalies INT,
    OUT p_q1 DECIMAL(15,6),
    OUT p_q3 DECIMAL(15,6)
)
BEGIN
    -- Calculate baseline from historical data (include all severity levels for better baseline)
    SELECT 
        COALESCE(
            SUM(COALESCE(d.raw_metric_value, 0) * (25 - TIMESTAMPDIFF(HOUR, d.detected_at, NOW()))) / 
            NULLIF(SUM(25 - TIMESTAMPDIFF(HOUR, d.detected_at, NOW())), 0), 
            0
        ),
        STDDEV(COALESCE(d.raw_metric_value, 0)),
        MIN(COALESCE(d.raw_metric_value, 0)),
        MAX(COALESCE(d.raw_metric_value, 0))
    INTO p_avg, p_std, p_min, p_max
    FROM detected_issues d
    WHERE d.issue_type COLLATE utf8mb4_unicode_ci = CONVERT(p_issue_type USING utf8mb4) COLLATE utf8mb4_unicode_ci
      AND d.detected_at >= (NOW() - INTERVAL 24 HOUR)
      AND d.issue_id != p_issue_id
      AND (
            (p_metric_group = 'LOW' AND COALESCE(d.raw_metric_value, 0) < 100) OR
            (p_metric_group = 'MEDIUM' AND COALESCE(d.raw_metric_value, 0) >= 100 AND COALESCE(d.raw_metric_value, 0) < 1000) OR
            (p_metric_group = 'HIGH' AND COALESCE(d.raw_metric_value, 0) >= 1000)
      );

    -- Quartiles (IQR) Detection Base (include all historical data)
    WITH RankedValues AS (
        SELECT COALESCE(d.raw_metric_value, 0) as val,
               PERCENT_RANK() OVER (ORDER BY COALESCE(d.raw_metric_value, 0)) as pct
        FROM detected_issues d
        WHERE d.issue_type COLLATE utf8mb4_unicode_ci = CONVERT(p_issue_type USING utf8mb4) COLLATE utf8mb4_unicode_ci
          AND d.detected_at >= (NOW() - INTERVAL 24 HOUR)
          AND d.issue_id != p_issue_id
          AND (
                (p_metric_group = 'LOW' AND COALESCE(d.raw_metric_value, 0) < 100) OR
                (p_metric_group = 'MEDIUM' AND COALESCE(d.raw_metric_value, 0) >= 100 AND COALESCE(d.raw_metric_value, 0) < 1000) OR
                (p_metric_group = 'HIGH' AND COALESCE(d.raw_metric_value, 0) >= 1000)
          )
    )
    SELECT 
        COALESCE(MIN(CASE WHEN pct >= 0.25 THEN val END), p_avg),
        COALESCE(MIN(CASE WHEN pct >= 0.75 THEN val END), p_avg)
    INTO p_q1, p_q3
    FROM RankedValues;

    SELECT COUNT(*) INTO p_recent_anomalies
    FROM detected_issues d
    INNER JOIN ai_analysis a ON d.issue_id = a.issue_id
    WHERE d.issue_type COLLATE utf8mb4_unicode_ci = CONVERT(p_issue_type USING utf8mb4) COLLATE utf8mb4_unicode_ci
      AND d.detected_at >= (NOW() - INTERVAL 2 HOUR)
      AND a.severity_level IN ('HIGH', 'CRITICAL');

    IF p_avg IS NULL OR p_avg = 0 THEN
        SET p_avg = 0.000001; 
    END IF;

    IF p_std IS NULL OR p_std = 0 THEN
        SET p_std = 1.0;
    END IF;
END //

DELIMITER ;
