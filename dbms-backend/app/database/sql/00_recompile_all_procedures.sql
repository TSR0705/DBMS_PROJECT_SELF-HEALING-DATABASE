/*!40101 SET NAMES utf8mb4 */;

DELIMITER //

-- ============================================================
-- AI ENGINE PROCEDURES (all use utf8mb4_0900_ai_ci — server default)
-- ============================================================

DROP PROCEDURE IF EXISTS get_issue_features//
CREATE PROCEDURE get_issue_features(
    IN  p_issue_id     BIGINT,
    OUT p_issue_type   VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_raw_metric   DECIMAL(15,6),
    OUT p_metric_group VARCHAR(20)  CHARACTER SET utf8mb4
)
BEGIN
    SELECT issue_type,
           COALESCE(raw_metric_value, 0),
           CASE
               WHEN COALESCE(raw_metric_value, 0) < 100  THEN 'LOW'
               WHEN COALESCE(raw_metric_value, 0) < 1000 THEN 'MEDIUM'
               ELSE 'HIGH'
           END
    INTO p_issue_type, p_raw_metric, p_metric_group
    FROM detected_issues
    WHERE issue_id = p_issue_id
    LIMIT 1;
END //

DROP PROCEDURE IF EXISTS compute_baseline//
CREATE PROCEDURE compute_baseline(
    IN  p_issue_id     BIGINT,
    IN  p_issue_type   VARCHAR(255) CHARACTER SET utf8mb4,
    IN  p_metric_group VARCHAR(20)  CHARACTER SET utf8mb4,
    OUT p_avg   DECIMAL(15,6),
    OUT p_std   DECIMAL(15,6),
    OUT p_min   DECIMAL(15,6),
    OUT p_max   DECIMAL(15,6),
    OUT p_recent_anomalies INT,
    OUT p_q1    DECIMAL(15,6),
    OUT p_q3    DECIMAL(15,6)
)
BEGIN
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
    LEFT JOIN ai_analysis a ON d.issue_id = a.issue_id
    WHERE d.issue_type = p_issue_type
      AND d.detected_at >= (NOW() - INTERVAL 24 HOUR)
      AND d.issue_id != p_issue_id
      AND (a.severity_level != 'CRITICAL' OR a.severity_level IS NULL)
      AND (
            (p_metric_group = 'LOW'    AND COALESCE(d.raw_metric_value, 0) < 100) OR
            (p_metric_group = 'MEDIUM' AND COALESCE(d.raw_metric_value, 0) >= 100 AND COALESCE(d.raw_metric_value, 0) < 1000) OR
            (p_metric_group = 'HIGH'   AND COALESCE(d.raw_metric_value, 0) >= 1000)
      );

    WITH RankedValues AS (
        SELECT COALESCE(d.raw_metric_value, 0) AS val,
               PERCENT_RANK() OVER (ORDER BY COALESCE(d.raw_metric_value, 0)) AS pct
        FROM detected_issues d
        LEFT JOIN ai_analysis a ON d.issue_id = a.issue_id
        WHERE d.issue_type = p_issue_type
          AND d.detected_at >= (NOW() - INTERVAL 24 HOUR)
          AND d.issue_id != p_issue_id
          AND (a.severity_level != 'CRITICAL' OR a.severity_level IS NULL)
          AND (
                (p_metric_group = 'LOW'    AND COALESCE(d.raw_metric_value, 0) < 100) OR
                (p_metric_group = 'MEDIUM' AND COALESCE(d.raw_metric_value, 0) >= 100 AND COALESCE(d.raw_metric_value, 0) < 1000) OR
                (p_metric_group = 'HIGH'   AND COALESCE(d.raw_metric_value, 0) >= 1000)
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
    WHERE d.issue_type = p_issue_type
      AND d.detected_at >= (NOW() - INTERVAL 2 HOUR)
      AND a.severity_level IN ('HIGH', 'CRITICAL');

    SET p_avg = COALESCE(p_avg, 0.000001);
    SET p_std = COALESCE(p_std, 1.0);
    SET p_min = COALESCE(p_min, 0);
    SET p_max = COALESCE(p_max, 0);
    SET p_q1  = COALESCE(p_q1, p_avg);
    SET p_q3  = COALESCE(p_q3, p_avg);
    SET p_recent_anomalies = COALESCE(p_recent_anomalies, 0);
END //

DROP PROCEDURE IF EXISTS compute_severity//
CREATE PROCEDURE compute_severity(
    IN  p_raw_metric       DECIMAL(15,6),
    IN  p_avg              DECIMAL(15,6),
    IN  p_std              DECIMAL(15,6),
    IN  p_recent_anomalies INT,
    IN  p_q1               DECIMAL(15,6),
    IN  p_q3               DECIMAL(15,6),
    OUT p_z_score          DECIMAL(15,6),
    OUT p_severity         VARCHAR(20) CHARACTER SET utf8mb4
)
BEGIN
    SET p_z_score = CASE
        WHEN p_std > 0 THEN ABS(p_raw_metric - p_avg) / p_std
        WHEN p_avg > 0 THEN ABS(p_raw_metric - p_avg) / p_avg
        ELSE ABS(p_raw_metric) + 0.01
    END;

    SET p_severity = CASE
        WHEN p_z_score >= 3.0 OR p_recent_anomalies >= 5 THEN 'CRITICAL'
        WHEN p_z_score >= 2.0 OR p_recent_anomalies >= 3 THEN 'HIGH'
        WHEN p_z_score >= 1.0 OR p_recent_anomalies >= 1 THEN 'MEDIUM'
        ELSE 'LOW'
    END;
END //

DROP PROCEDURE IF EXISTS run_ai_analysis//
CREATE PROCEDURE run_ai_analysis(IN p_issue_id BIGINT)
BEGIN
    DECLARE v_issue_type   VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_raw_metric   DECIMAL(15,6);
    DECLARE v_metric_group VARCHAR(20)  CHARACTER SET utf8mb4;
    DECLARE v_avg          DECIMAL(15,6);
    DECLARE v_std          DECIMAL(15,6);
    DECLARE v_min          DECIMAL(15,6);
    DECLARE v_max          DECIMAL(15,6);
    DECLARE v_recent       INT;
    DECLARE v_q1           DECIMAL(15,6);
    DECLARE v_q3           DECIMAL(15,6);
    DECLARE v_z_score      DECIMAL(15,6);
    DECLARE v_severity     VARCHAR(20) CHARACTER SET utf8mb4;
    DECLARE v_exists       INT DEFAULT 0;

    CALL get_issue_features(p_issue_id, v_issue_type, v_raw_metric, v_metric_group);

    IF v_issue_type IS NOT NULL THEN
        CALL compute_baseline(p_issue_id, v_issue_type, v_metric_group, v_avg, v_std, v_min, v_max, v_recent, v_q1, v_q3);
        CALL compute_severity(v_raw_metric, v_avg, v_std, v_recent, v_q1, v_q3, v_z_score, v_severity);

        SELECT COUNT(*) INTO v_exists FROM ai_analysis WHERE issue_id = p_issue_id;
        IF v_exists = 0 THEN
            INSERT IGNORE INTO ai_analysis (issue_id, severity_level, baseline_metric, severity_ratio)
            VALUES (p_issue_id, v_severity, v_avg, v_z_score);
        END IF;
    END IF;
END //

-- ============================================================
-- STEP 2 ENGINE
-- ============================================================

DROP PROCEDURE IF EXISTS compute_success_rate//
CREATE PROCEDURE compute_success_rate(
    IN  p_issue_type   VARCHAR(255) CHARACTER SET utf8mb4,
    IN  p_action_type  VARCHAR(255) CHARACTER SET utf8mb4,
    OUT p_success_rate DECIMAL(15,6)
)
BEGIN
    DECLARE v_total   DECIMAL(15,6);
    DECLARE v_success DECIMAL(15,6);

    SELECT
        SUM(EXP(-DATEDIFF(NOW(), recorded_at)/3)),
        SUM(CASE WHEN outcome = 'RESOLVED' THEN EXP(-DATEDIFF(NOW(), recorded_at)/3) ELSE 0 END)
    INTO v_total, v_success
    FROM learning_history
    WHERE issue_type  = p_issue_type
      AND action_type = p_action_type
      AND recorded_at >= NOW() - INTERVAL 7 DAY;

    IF v_total IS NULL OR v_total < 5 THEN
        SET p_success_rate = (COALESCE(v_success, 0) + 2.0) / (COALESCE(v_total, 0) + 4.0);
    ELSE
        SET p_success_rate = v_success / v_total;
    END IF;
END //

DROP PROCEDURE IF EXISTS execute_healing_action//
CREATE PROCEDURE execute_healing_action(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_id      BIGINT;
    DECLARE v_issue_type    VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_decision_type VARCHAR(50)  CHARACTER SET utf8mb4;
    DECLARE v_action_type   VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_is_automatic  TINYINT      DEFAULT 0;
    DECLARE v_exec_status   VARCHAR(10)  CHARACTER SET utf8mb4 DEFAULT 'SKIPPED';
    DECLARE v_already_exists INT         DEFAULT 0;

    SELECT dl.issue_id, di.issue_type, dl.decision_type
    INTO   v_issue_id, v_issue_type, v_decision_type
    FROM   decision_log dl
    JOIN   detected_issues di ON dl.issue_id = di.issue_id
    WHERE  dl.decision_id = p_decision_id
    LIMIT  1;

    IF v_issue_type IS NULL THEN LEAVE proc_label; END IF;

    SELECT action_type, is_automatic
    INTO   v_action_type, v_is_automatic
    FROM   action_rules
    WHERE  issue_type = v_issue_type
    LIMIT  1;

    IF v_decision_type != 'AUTO_HEAL'  THEN SET v_exec_status = 'SKIPPED';
    ELSEIF v_action_type IS NULL       THEN SET v_exec_status = 'SKIPPED';
    ELSEIF v_is_automatic = 0          THEN SET v_exec_status = 'SKIPPED';
    ELSE                                    SET v_exec_status = 'SUCCESS';
    END IF;

    IF v_exec_status != 'SKIPPED' THEN
        SELECT COUNT(*) INTO v_already_exists FROM healing_actions WHERE decision_id = p_decision_id;
        IF v_already_exists = 0 THEN
            INSERT INTO healing_actions (decision_id, action_type, execution_mode, executed_by, execution_status)
            VALUES (p_decision_id, v_action_type, 'AUTOMATIC', 'SYSTEM', v_exec_status);
        END IF;
    END IF;
END //

DROP PROCEDURE IF EXISTS update_learning//
CREATE PROCEDURE update_learning(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_type        VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_action_type       VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_exec_status       VARCHAR(10)  CHARACTER SET utf8mb4;
    DECLARE v_confidence_before DECIMAL(5,4) DEFAULT 0.0;
    DECLARE v_confidence_after  DECIMAL(5,4) DEFAULT 0.0;
    DECLARE v_already_learned   INT          DEFAULT 0;

    SELECT ha.action_type,
           ha.execution_status,
           LEAST(GREATEST(dl.confidence_at_decision, 0.0), 0.9999)
    INTO   v_action_type, v_exec_status, v_confidence_before
    FROM   healing_actions ha
    JOIN   decision_log dl ON ha.decision_id = dl.decision_id
    WHERE  ha.decision_id = p_decision_id
    LIMIT  1;

    IF v_action_type IS NULL OR v_exec_status IS NULL THEN LEAVE proc_label; END IF;
    IF v_exec_status = 'SKIPPED' THEN LEAVE proc_label; END IF;

    SELECT di.issue_type
    INTO   v_issue_type
    FROM   decision_log dl
    JOIN   detected_issues di ON dl.issue_id = di.issue_id
    WHERE  dl.decision_id = p_decision_id
    LIMIT  1;

    IF v_exec_status = 'SUCCESS' THEN
        SET v_confidence_after = LEAST(v_confidence_before + 0.05, 0.9999);
    ELSE
        SET v_confidence_after = GREATEST(v_confidence_before - 0.05, 0.0);
    END IF;

    SELECT COUNT(*) INTO v_already_learned
    FROM   learning_history
    WHERE  issue_type  = v_issue_type
      AND  action_type = v_action_type
      AND  recorded_at >= NOW() - INTERVAL 60 SECOND;

    IF v_already_learned = 0 THEN
        INSERT INTO learning_history (issue_type, action_type, outcome, confidence_before, confidence_after)
        VALUES (
            v_issue_type,
            v_action_type,
            IF(v_exec_status = 'SUCCESS', 'RESOLVED', 'FAILED'),
            v_confidence_before,
            v_confidence_after
        );
    END IF;
END //

DROP PROCEDURE IF EXISTS make_decision//
CREATE PROCEDURE make_decision(IN p_issue_id BIGINT)
BEGIN
    DECLARE v_severity_level   VARCHAR(20)  CHARACTER SET utf8mb4;
    DECLARE v_confidence_score DECIMAL(15,6);
    DECLARE v_issue_type       VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_severity_weight  DECIMAL(15,6);
    DECLARE v_action_type      VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_success_rate     DECIMAL(15,6);
    DECLARE v_decision_score   DECIMAL(15,6);
    DECLARE v_decision_type    VARCHAR(50)  CHARACTER SET utf8mb4;
    DECLARE v_is_automatic     BOOLEAN;
    DECLARE v_decision_reason  VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_exists           INT;
    DECLARE v_anomaly_count    INT;
    DECLARE v_same_decisions   INT;

    SELECT d.issue_type, a.severity_level, COALESCE(a.severity_ratio, 0.0)
    INTO   v_issue_type, v_severity_level, v_confidence_score
    FROM   ai_analysis a
    JOIN   detected_issues d ON a.issue_id = d.issue_id
    WHERE  a.issue_id = p_issue_id
    LIMIT  1;

    IF v_issue_type IS NOT NULL THEN
        CASE v_severity_level
            WHEN 'CRITICAL' THEN SET v_severity_weight = 1.0;
            WHEN 'HIGH'     THEN SET v_severity_weight = 0.7;
            ELSE                 SET v_severity_weight = 0.4;
        END CASE;

        SELECT action_type, is_automatic
        INTO   v_action_type, v_is_automatic
        FROM   action_rules
        WHERE  issue_type = v_issue_type
        LIMIT  1;

        IF v_action_type IS NULL THEN
            SET v_action_type  = 'UNKNOWN';
            SET v_success_rate = 0.50;
        ELSE
            CALL compute_success_rate(v_issue_type, v_action_type, v_success_rate);
        END IF;

        SELECT COUNT(*) INTO v_anomaly_count
        FROM   detected_issues d
        JOIN   ai_analysis a ON d.issue_id = a.issue_id
        WHERE  d.issue_type = v_issue_type
          AND  a.severity_level IN ('HIGH','CRITICAL')
          AND  d.detected_at >= NOW() - INTERVAL 1 HOUR;

        IF v_anomaly_count > 5 THEN SET v_severity_weight = v_severity_weight + 0.1; END IF;

        SET v_decision_score = (v_severity_weight * 0.5) + (v_confidence_score * 0.3) + ((v_success_rate - 0.5) * 0.4);

        SELECT COUNT(*) INTO v_same_decisions
        FROM (
            SELECT dl.decision_type
            FROM   decision_log dl
            JOIN   detected_issues di ON dl.issue_id = di.issue_id
            WHERE  di.issue_type = v_issue_type
            ORDER  BY dl.decision_id DESC
            LIMIT  3
        ) sub
        WHERE decision_type = (
            SELECT dl2.decision_type
            FROM   decision_log dl2
            JOIN   detected_issues di2 ON dl2.issue_id = di2.issue_id
            WHERE  di2.issue_type = v_issue_type
            ORDER  BY dl2.decision_id DESC
            LIMIT  1
        );

        IF v_same_decisions = 3 THEN SET v_decision_score = v_decision_score + 0.05; END IF;

        IF v_decision_score >= 0.75 THEN
            SET v_decision_type   = 'AUTO_HEAL';
            SET v_decision_reason = 'Score limits exceeded threshold for auto execution';
        ELSEIF v_decision_score >= 0.5 THEN
            SET v_decision_type   = 'CONDITIONAL';
            SET v_decision_reason = 'Moderate bounds met, conditional locks applied';
        ELSE
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Insufficient history or logic bounds - manual override needed';
        END IF;

        IF v_action_type != 'UNKNOWN' AND v_is_automatic = FALSE AND v_decision_type = 'AUTO_HEAL' THEN
            SET v_decision_type = 'CONDITIONAL';
        END IF;

        IF v_success_rate < 0.3 THEN
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Historical action success rate too low, manual override enforced';
        END IF;

        IF v_severity_level = 'CRITICAL' AND v_success_rate < 0.2 THEN
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Critical severity action disabled due to high historical failure';
        END IF;

        IF v_action_type = 'UNKNOWN' THEN
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = 'Unknown issue type forces safe fallback';
        END IF;

        IF v_decision_type = 'CONDITIONAL' THEN
            SET v_decision_type   = 'ADMIN_REVIEW';
            SET v_decision_reason = CONCAT('[CONDITIONAL] ', v_decision_reason);
        END IF;

        SELECT COUNT(*) INTO v_exists FROM decision_log WHERE issue_id = p_issue_id;
        IF v_exists = 0 THEN
            INSERT IGNORE INTO decision_log (issue_id, decision_type, decision_reason, confidence_at_decision)
            VALUES (p_issue_id, v_decision_type, v_decision_reason, v_confidence_score);

            SET @last_decision_id = LAST_INSERT_ID();
            CALL execute_healing_action(@last_decision_id);
            CALL update_learning(@last_decision_id);
        END IF;
    END IF;
END //

DELIMITER ;
