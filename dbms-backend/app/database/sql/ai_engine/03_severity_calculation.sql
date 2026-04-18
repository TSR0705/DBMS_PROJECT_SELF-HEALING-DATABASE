/*!40101 SET NAMES utf8mb4 */;
SET collation_connection = 'utf8mb4_unicode_ci';
DELIMITER //

DROP PROCEDURE IF EXISTS compute_severity//
CREATE PROCEDURE compute_severity(
    IN p_raw_metric DECIMAL(15,6),
    IN p_avg DECIMAL(15,6),
    IN p_std DECIMAL(15,6),
    IN p_recent_anomalies INT,
    IN p_q1 DECIMAL(15,6),
    IN p_q3 DECIMAL(15,6),
    OUT p_z_score DECIMAL(15,6),
    OUT p_severity VARCHAR(20)
)
BEGIN
    DECLARE v_coef_variation DECIMAL(15,6);
    DECLARE v_crit_threshold DECIMAL(15,6);
    DECLARE v_high_threshold DECIMAL(15,6);
    DECLARE v_raw_z DECIMAL(15,6);

    DECLARE v_iqr DECIMAL(15,6);
    DECLARE v_iqr_lower DECIMAL(15,6);
    DECLARE v_iqr_upper DECIMAL(15,6);
    DECLARE v_is_iqr_anomaly INT DEFAULT 0;
    DECLARE v_is_z_anomaly INT DEFAULT 0;
    DECLARE v_median DECIMAL(15,6);
    DECLARE v_iqr_distance DECIMAL(15,6);
    DECLARE v_confidence DECIMAL(15,6);

    -- IQR Logic
    SET v_iqr = p_q3 - p_q1;
    SET v_iqr_lower = p_q1 - (1.5 * v_iqr);
    SET v_iqr_upper = p_q3 + (1.5 * v_iqr);

    IF p_raw_metric < v_iqr_lower OR p_raw_metric > v_iqr_upper THEN
        SET v_is_iqr_anomaly = 1;
    END IF;

    -- Z-score logic
    SET v_raw_z = (p_raw_metric - p_avg) / p_std;

    IF v_raw_z >= 0 THEN
        SET p_z_score = LOG(1.0 + v_raw_z);
    ELSE
        SET p_z_score = -LOG(1.0 + ABS(v_raw_z));
    END IF;

    SET v_coef_variation = p_std / p_avg;

    IF v_coef_variation < 0.05 THEN
        SET v_crit_threshold = 1.2;
        SET v_high_threshold = 0.8;
    ELSEIF v_coef_variation > 0.5 THEN
        SET v_crit_threshold = 2.5;
        SET v_high_threshold = 1.5;
    ELSE
        SET v_crit_threshold = 2.0;
        SET v_high_threshold = 1.0;
    END IF;

    IF p_recent_anomalies >= 3 AND p_recent_anomalies <= 10 THEN
        SET v_crit_threshold = v_crit_threshold * 1.5;
        SET v_high_threshold = v_high_threshold * 1.5;
    ELSEIF p_recent_anomalies > 10 THEN
        SET v_crit_threshold = 1.0; 
    END IF;

    -- Calculate Symmetric Median Base
    SET v_median = (p_q1 + p_q3) / 2.0;

    -- Isolate IQR Ratio (safeguard against division by zero on flatlines)
    IF v_iqr > 0 THEN
        SET v_iqr_distance = ABS(p_raw_metric - v_median) / v_iqr;
    ELSE
        SET v_iqr_distance = 0;
    END IF;

    -- Produce Normalized Confidence Aggregate (0.0 to ∞)
    IF v_crit_threshold > 0 THEN
        SET v_confidence = (ABS(p_z_score) / v_crit_threshold) * 0.5 + (v_iqr_distance * 0.5);
    ELSE
        SET v_confidence = 0;
    END IF;

    -- Output Discretization 
    IF v_confidence > 0.8 THEN
        SET p_severity = 'CRITICAL';
    ELSEIF v_confidence > 0.5 THEN
        SET p_severity = 'HIGH';
    ELSE
        SET p_severity = 'MEDIUM';
    END IF;
END //

DELIMITER ;
