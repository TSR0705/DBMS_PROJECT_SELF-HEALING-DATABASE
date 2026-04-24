-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: localhost    Database: dbms_self_healing
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `action_rules`
--

DROP TABLE IF EXISTS `action_rules`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `action_rules` (
  `rule_id` int NOT NULL AUTO_INCREMENT,
  `issue_type` varchar(255) NOT NULL,
  `action_type` varchar(255) NOT NULL,
  `is_automatic` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`rule_id`),
  UNIQUE KEY `uk_issue_action` (`issue_type`,`action_type`),
  UNIQUE KEY `idx_action_type` (`action_type`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `admin_reviews`
--

DROP TABLE IF EXISTS `admin_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_reviews` (
  `review_id` bigint NOT NULL AUTO_INCREMENT,
  `decision_id` bigint NOT NULL,
  `issue_id` bigint NOT NULL,
  `review_status` varchar(50) DEFAULT 'PENDING',
  `admin_action` varchar(255) DEFAULT NULL,
  `admin_comment` text,
  `override_flag` tinyint(1) DEFAULT '0',
  `reviewed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `issue_type` varchar(255) DEFAULT NULL,
  `action_type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`review_id`),
  UNIQUE KEY `uk_decision_id` (`decision_id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ai_analysis`
--

DROP TABLE IF EXISTS `ai_analysis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_analysis` (
  `analysis_id` bigint NOT NULL AUTO_INCREMENT,
  `issue_id` bigint NOT NULL,
  `predicted_issue_class` varchar(64) DEFAULT 'RULE_BASED',
  `severity_level` enum('LOW','MEDIUM','HIGH','CRITICAL') NOT NULL,
  `risk_type` varchar(64) DEFAULT 'DYNAMIC',
  `confidence_score` decimal(5,4) DEFAULT '1.0000',
  `model_version` varchar(32) DEFAULT 'SP_v1',
  `analyzed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `baseline_metric` decimal(15,6) DEFAULT '0.000000',
  `severity_ratio` decimal(15,6) DEFAULT '0.000000',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`analysis_id`),
  KEY `idx_ai_issue_id` (`issue_id`),
  CONSTRAINT `fk_ai_issue` FOREIGN KEY (`issue_id`) REFERENCES `detected_issues` (`issue_id`) ON DELETE CASCADE,
  CONSTRAINT `ai_analysis_chk_1` CHECK ((`confidence_score` between 0 and 1))
) ENGINE=InnoDB AUTO_INCREMENT=80 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `debug_log`
--

DROP TABLE IF EXISTS `debug_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `debug_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `step` varchar(50) DEFAULT NULL,
  `message` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4746 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `decision_log`
--

DROP TABLE IF EXISTS `decision_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `decision_log` (
  `decision_id` bigint NOT NULL AUTO_INCREMENT,
  `issue_id` bigint NOT NULL,
  `decision_type` enum('AUTO_HEAL','ADMIN_REVIEW') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `decision_reason` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `confidence_at_decision` decimal(5,4) NOT NULL,
  `decided_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`decision_id`),
  KEY `idx_decision_issue_id` (`issue_id`),
  CONSTRAINT `fk_decision_issue` FOREIGN KEY (`issue_id`) REFERENCES `detected_issues` (`issue_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `detected_issues`
--

DROP TABLE IF EXISTS `detected_issues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detected_issues` (
  `issue_id` bigint NOT NULL AUTO_INCREMENT,
  `issue_type` varchar(255) NOT NULL,
  `detection_source` enum('INNODB','PERFORMANCE_SCHEMA','SLOW_QUERY_LOG') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `raw_metric_value` decimal(10,2) DEFAULT NULL,
  `raw_metric_unit` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `detected_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `issue_group_id` bigint DEFAULT NULL,
  PRIMARY KEY (`issue_id`),
  KEY `idx_detected_issues_time` (`detected_at`),
  KEY `idx_issue_group` (`issue_group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3006 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `healing_actions`
--

DROP TABLE IF EXISTS `healing_actions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `healing_actions` (
  `action_id` bigint NOT NULL AUTO_INCREMENT,
  `decision_id` bigint NOT NULL,
  `action_type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `execution_mode` enum('AUTOMATIC','ADMIN_APPROVED') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `executed_by` enum('SYSTEM','ADMIN') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `execution_status` enum('SUCCESS','FAILED') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `executed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `before_metric` decimal(15,6) DEFAULT NULL COMMENT 'Metric value before execution',
  `after_metric` decimal(15,6) DEFAULT NULL COMMENT 'Metric value after execution',
  `verification_status` varchar(20) DEFAULT NULL COMMENT 'VERIFIED/UNVERIFIED/FAILED',
  `process_id` bigint DEFAULT NULL COMMENT 'Process ID for KILL_CONNECTION',
  `error_message` text COMMENT 'Error details if execution failed',
  PRIMARY KEY (`action_id`),
  KEY `idx_action_decision_id` (`decision_id`),
  KEY `idx_healing_actions_time` (`executed_at`),
  KEY `fk_healing_action_type` (`action_type`),
  CONSTRAINT `fk_action_decision` FOREIGN KEY (`decision_id`) REFERENCES `decision_log` (`decision_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_healing_action_type` FOREIGN KEY (`action_type`) REFERENCES `action_rules` (`action_type`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `issue_detection_cache`
--

DROP TABLE IF EXISTS `issue_detection_cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `issue_detection_cache` (
  `cache_id` bigint NOT NULL AUTO_INCREMENT,
  `issue_signature` varchar(255) NOT NULL,
  `last_detected_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cache_id`),
  UNIQUE KEY `idx_signature` (`issue_signature`),
  KEY `idx_time` (`last_detected_at`)
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `learning_history`
--

DROP TABLE IF EXISTS `learning_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `learning_history` (
  `learning_id` bigint NOT NULL AUTO_INCREMENT,
  `issue_type` varchar(255) NOT NULL,
  `action_type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `outcome` enum('RESOLVED','FAILED') CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `confidence_before` decimal(5,4) NOT NULL,
  `confidence_after` decimal(5,4) NOT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `decision_id` bigint DEFAULT NULL,
  PRIMARY KEY (`learning_id`),
  UNIQUE KEY `uq_learning_decision` (`decision_id`),
  KEY `idx_learning_issue_action` (`issue_type`,`action_type`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'dbms_self_healing'
--
/*!50003 DROP PROCEDURE IF EXISTS `compute_ai_features` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `compute_ai_features`(IN p_issue_id BIGINT)
BEGIN
    DECLARE v_issue_type VARCHAR(255);
    DECLARE v_raw_metric_value DECIMAL(15, 6);
    DECLARE v_avg_metric DECIMAL(15, 6);
    DECLARE v_std DECIMAL(15, 6);
    DECLARE v_z_score DECIMAL(15, 6);
    DECLARE v_severity VARCHAR(50);
    DECLARE v_exists INT DEFAULT 0;

    SELECT CAST(issue_type AS CHAR), COALESCE(NULLIF(raw_metric_value, 0), 0.000001)
    INTO v_issue_type, v_raw_metric_value
    FROM detected_issues
    WHERE issue_id = p_issue_id
    LIMIT 1;

    IF v_issue_type IS NOT NULL THEN
        SELECT 
            AVG(COALESCE(d.raw_metric_value, 0)),
            STDDEV(COALESCE(d.raw_metric_value, 0))
        INTO v_avg_metric, v_std
        FROM detected_issues d
        LEFT JOIN ai_analysis a ON d.issue_id = a.issue_id
        WHERE BINARY d.issue_type = BINARY v_issue_type
          AND d.detected_at >= (NOW() - INTERVAL 24 HOUR)
          AND d.issue_id != p_issue_id
          AND (a.severity_level != 'CRITICAL' OR a.severity_level IS NULL);

        IF v_avg_metric IS NULL OR v_avg_metric = 0 THEN
            SET v_avg_metric = COALESCE(NULLIF(v_raw_metric_value, 0), 0.000001);
        END IF;

        IF v_std IS NULL OR v_std < ABS(v_avg_metric * 0.05) THEN
            SET v_std = GREATEST(1.0, ABS(v_avg_metric * 0.05));
        END IF;

        SET v_z_score = (v_raw_metric_value - v_avg_metric) / v_std;

        CASE
            WHEN v_z_score >= 2.0 THEN SET v_severity = 'CRITICAL';
            WHEN v_z_score >= 1.0 THEN SET v_severity = 'HIGH';
            ELSE SET v_severity = 'MEDIUM';
        END CASE;

        SELECT COUNT(*)
        INTO v_exists
        FROM ai_analysis
        WHERE issue_id = p_issue_id;

        IF v_exists = 0 THEN
            INSERT INTO ai_analysis (
                issue_id,
                severity_level,
                baseline_metric,
                severity_ratio,
                created_at
            ) VALUES (
                p_issue_id,
                v_severity,
                v_avg_metric,
                v_z_score,
                NOW()
            );
        END IF;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `compute_baseline` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `compute_baseline`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `compute_severity` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `compute_severity`(
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
    
    IF p_avg <= 0 THEN
        SET p_avg = 1.0;
    END IF;

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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `compute_success_rate` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `compute_success_rate`(
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

    IF v_total IS NULL OR v_total = 0 THEN
        SET p_success_rate = 0.30;
    ELSEIF v_total < 5 THEN
        SET p_success_rate = (COALESCE(v_success, 0) + 2.0) / (COALESCE(v_total, 0) + 4.0);
    ELSE
        SET p_success_rate = v_success / v_total;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `detect_connection_overload` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `detect_connection_overload`()
BEGIN
    DECLARE v_connection_count INT;
    DECLARE v_max_connections INT;
    DECLARE v_signature VARCHAR(255);
    
    
    SELECT VARIABLE_VALUE INTO v_connection_count
    FROM performance_schema.global_status
    WHERE VARIABLE_NAME = 'Threads_connected';
    
    
    SELECT VARIABLE_VALUE INTO v_max_connections
    FROM performance_schema.global_variables
    WHERE VARIABLE_NAME = 'max_connections';
    
    
    IF v_connection_count > LEAST(v_max_connections * 0.75, 150) THEN
        
        SET v_signature = CONCAT('CONNECTION_OVERLOAD_', DATE_FORMAT(NOW(), '%Y%m%d%H%i'));
        
        
        IF NOT EXISTS (
            SELECT 1 FROM issue_detection_cache
            WHERE issue_signature = v_signature
            AND last_detected_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
        ) THEN
            
            INSERT INTO detected_issues 
                (issue_type, detection_source, raw_metric_value, raw_metric_unit)
            VALUES 
                ('CONNECTION_OVERLOAD', 'PERFORMANCE_SCHEMA', v_connection_count, 'connections');
            
            
            INSERT INTO issue_detection_cache (issue_signature, last_detected_at)
            VALUES (v_signature, NOW())
            ON DUPLICATE KEY UPDATE last_detected_at = NOW();
        END IF;
    END IF;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `detect_long_transactions` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `detect_long_transactions`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_trx_id VARCHAR(50);
    DECLARE v_trx_duration INT;
    DECLARE v_signature VARCHAR(255);
    
    
    DECLARE trx_cursor CURSOR FOR
        SELECT 
            trx_id,
            TIMESTAMPDIFF(SECOND, trx_started, NOW()) as duration_seconds
        FROM information_schema.innodb_trx
        WHERE TIMESTAMPDIFF(SECOND, trx_started, NOW()) > 30  
        ORDER BY trx_started ASC
        LIMIT 5;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN trx_cursor;
    
    read_loop: LOOP
        FETCH trx_cursor INTO v_trx_id, v_trx_duration;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET v_signature = CONCAT('TRANSACTION_', v_trx_id);
        
        
        IF NOT EXISTS (
            SELECT 1 FROM issue_detection_cache
            WHERE issue_signature = v_signature
            AND last_detected_at > DATE_SUB(NOW(), INTERVAL 5 MINUTE)
        ) THEN
            
            INSERT INTO detected_issues 
                (issue_type, detection_source, raw_metric_value, raw_metric_unit)
            VALUES 
                ('TRANSACTION_FAILURE', 'INNODB', v_trx_duration, 'seconds');
            
            
            INSERT INTO issue_detection_cache (issue_signature, last_detected_at)
            VALUES (v_signature, NOW())
            ON DUPLICATE KEY UPDATE last_detected_at = NOW();
        END IF;
        
    END LOOP;
    
    CLOSE trx_cursor;
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `detect_slow_queries` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `detect_slow_queries`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_process_id BIGINT;
    DECLARE v_query_time INT;
    DECLARE v_query_text TEXT;
    DECLARE v_signature VARCHAR(255);
    DECLARE v_time_bucket INT;
    
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
        
        
        
        
        
        SET v_time_bucket = FLOOR(v_query_time / 10);
        
        
        
        SET v_signature = CONCAT('SLOW_QUERY_', v_process_id, '_', v_time_bucket);
        
        
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
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `execute_healing_action` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `execute_healing_action`(IN p_decision_id BIGINT)
proc_label: BEGIN
        DECLARE v_issue_id      BIGINT;
        DECLARE v_issue_type    VARCHAR(255) CHARACTER SET utf8mb4;
        DECLARE v_decision_type VARCHAR(50)  CHARACTER SET utf8mb4;
        DECLARE v_action_type   VARCHAR(255) CHARACTER SET utf8mb4;
        DECLARE v_is_automatic  TINYINT      DEFAULT 0;
        DECLARE v_exec_status   VARCHAR(10)  CHARACTER SET utf8mb4 DEFAULT 'SKIPPED';
        DECLARE v_exec_mode     VARCHAR(20)  CHARACTER SET utf8mb4 DEFAULT 'AUTOMATIC';
        DECLARE v_is_approved   INT          DEFAULT 0;
        
        DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            INSERT INTO debug_log(step, message)
            VALUES ('execution_error', 'Execution failed');
        END;

        SELECT dl.issue_id, di.issue_type, dl.decision_type
        INTO   v_issue_id, v_issue_type, v_decision_type
        FROM   decision_log dl
        JOIN   detected_issues di ON dl.issue_id = di.issue_id
        WHERE  dl.decision_id = p_decision_id
        LIMIT  1;

        IF v_issue_id IS NULL THEN LEAVE proc_label; END IF;

        SELECT action_type, is_automatic
        INTO   v_action_type, v_is_automatic
        FROM   action_rules
        WHERE  issue_type = v_issue_type
        LIMIT  1;

        SELECT COUNT(*) INTO v_is_approved FROM admin_reviews WHERE decision_id = p_decision_id AND review_status = 'APPROVED';

        IF v_is_approved > 0 THEN
            SET v_exec_status = 'SUCCESS';
            SET v_exec_mode   = 'ADMIN_APPROVED';
        ELSEIF v_decision_type = 'AUTO_HEAL' AND v_action_type IS NOT NULL AND v_is_automatic = 1 THEN
            SET v_exec_status = 'SUCCESS';
            SET v_exec_mode   = 'AUTOMATIC';
        ELSE
            SET v_exec_status = 'SKIPPED';
        END IF;

        IF v_exec_status = 'SUCCESS' THEN
            IF v_action_type IS NULL THEN SET v_action_type = 'MANUAL_RESOLUTION'; END IF;
        END IF;

        IF v_exec_status != 'SKIPPED' THEN
            INSERT IGNORE INTO healing_actions (decision_id, action_type, execution_mode, executed_by, execution_status)
            VALUES (p_decision_id, v_action_type, v_exec_mode, IF(v_is_approved > 0, 'ADMIN', 'SYSTEM'), v_exec_status);
        END IF;
    END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `get_issue_features` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `get_issue_features`(
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

    
    IF p_issue_type LIKE '%_SECONDS' THEN
        SET p_raw_metric = p_raw_metric * 1000.0;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `make_decision` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `make_decision`(IN p_issue_id BIGINT)
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
    DECLARE v_force_execution BOOLEAN DEFAULT FALSE;

    SELECT d.issue_type, a.severity_level, COALESCE(a.severity_ratio, 0.0)
    INTO   v_issue_type, v_severity_level, v_confidence_score
    FROM   ai_analysis a
    JOIN   detected_issues d ON a.issue_id = d.issue_id
    WHERE  a.issue_id = p_issue_id
    LIMIT  1;

    SET v_confidence_score = LEAST(1.0, ABS(v_confidence_score) / 3.0);

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
        SET v_decision_score = LEAST(1.0, GREATEST(0.0, v_decision_score));

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

        IF v_decision_score >= 0.5 THEN
            SET v_decision_type   = 'AUTO_HEAL';
            SET v_decision_reason = 'High confidence - automated execution approved';
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

        IF v_decision_type = 'AUTO_HEAL' THEN
            SELECT COUNT(*) INTO @recent_auto_heals
            FROM decision_log
            WHERE decision_type = 'AUTO_HEAL'
              AND created_at >= NOW() - INTERVAL 1 MINUTE;

            IF @recent_auto_heals >= 5 THEN
                SET v_decision_type = 'ADMIN_REVIEW';
                SET v_decision_reason = 'AUTO_HEAL throttled: >5 automated actions executed globally in last 60 seconds';
            END IF;
        END IF;

        SELECT COUNT(*) INTO v_exists FROM decision_log WHERE issue_id = p_issue_id;
        IF v_exists = 0 THEN
            INSERT IGNORE INTO decision_log (issue_id, decision_type, decision_reason, confidence_at_decision)
            VALUES (p_issue_id, v_decision_type, v_decision_reason, v_confidence_score);

            SET @last_decision_id = LAST_INSERT_ID();
            
            INSERT INTO debug_log(step, message)
            VALUES ('make_decision', CONCAT('Decision: ', v_decision_type));

            IF v_decision_type = 'AUTO_HEAL' THEN
                CALL execute_healing_action(@last_decision_id);
                CALL update_learning(@last_decision_id);
            ELSEIF v_decision_type = 'ADMIN_REVIEW' THEN
                
                INSERT IGNORE INTO admin_reviews(
                    decision_id,
                    issue_id,
                    issue_type,
                    action_type,
                    review_status
                )
                VALUES (
                    @last_decision_id,
                    p_issue_id,
                    v_issue_type,
                    v_action_type,
                    'PENDING'
                );
            END IF;
        END IF;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `process_admin_review` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `process_admin_review`(IN p_decision_id BIGINT, IN p_action VARCHAR(50))
BEGIN
    DECLARE v_exists INT;
    SELECT COUNT(*) INTO v_exists FROM admin_reviews WHERE decision_id = p_decision_id AND review_status = 'PENDING';
    
    IF v_exists > 0 THEN
        IF p_action = 'APPROVE' THEN
            UPDATE admin_reviews SET review_status = 'APPROVED', reviewed_at = NOW() WHERE decision_id = p_decision_id;
            CALL execute_healing_action(p_decision_id);
            CALL update_learning(p_decision_id);
        ELSEIF p_action = 'REJECT' THEN
            UPDATE admin_reviews SET review_status = 'REJECTED', reviewed_at = NOW() WHERE decision_id = p_decision_id;
        END IF;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `run_ai_analysis` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `run_ai_analysis`(IN p_issue_id BIGINT)
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `run_automatic_detection` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `run_automatic_detection`()
BEGIN
    
    CALL detect_slow_queries();
    CALL detect_connection_overload();
    CALL detect_long_transactions();
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `run_auto_heal_pipeline` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `run_auto_heal_pipeline`()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_issue_id BIGINT;
    DECLARE v_lock INT DEFAULT 0;
    
    DECLARE issue_cursor CURSOR FOR 
        SELECT d.issue_id
        FROM detected_issues d
        LEFT JOIN ai_analysis a ON d.issue_id = a.issue_id
        WHERE a.issue_id IS NULL
        LIMIT 50;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        INSERT INTO debug_log(step, message)
        VALUES ('error', 'Pipeline crashed');
        DO RELEASE_LOCK('auto_heal_pipeline_lock');
    END;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    SELECT GET_LOCK('auto_heal_pipeline_lock', 1) INTO v_lock;

    IF v_lock = 1 THEN
        INSERT INTO debug_log(step, message) VALUES ('pipeline_start', 'Pipeline start');

        OPEN issue_cursor;
        read_loop: LOOP
            FETCH issue_cursor INTO v_issue_id;
            
            IF done THEN
                LEAVE read_loop;
            END IF;

            INSERT INTO debug_log(step, message) 
            VALUES ('pipeline', CONCAT('Processing issue_id: ', v_issue_id));

            CALL run_ai_analysis(v_issue_id);
            CALL make_decision(v_issue_id);
        END LOOP;
        
        CLOSE issue_cursor;

        INSERT INTO debug_log(step, message) VALUES ('pipeline_end', 'Pipeline end');

        DO RELEASE_LOCK('auto_heal_pipeline_lock');
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `update_learning` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = cp850 */ ;
/*!50003 SET character_set_results = cp850 */ ;
/*!50003 SET collation_connection  = cp850_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_learning`(IN p_decision_id BIGINT)
proc_label: BEGIN
    DECLARE v_issue_type        VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_action_type       VARCHAR(255) CHARACTER SET utf8mb4;
    DECLARE v_exec_status       VARCHAR(10)  CHARACTER SET utf8mb4;
    DECLARE v_confidence_before DECIMAL(5,4) DEFAULT 0.0;
    DECLARE v_confidence_after  DECIMAL(5,4) DEFAULT 0.0;

    INSERT INTO debug_log(step, message)
    VALUES ('learning', 'Learning triggered');

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

    INSERT IGNORE INTO learning_history (decision_id, issue_type, action_type, outcome, confidence_before, confidence_after)
    VALUES (
        p_decision_id,
        v_issue_type,
        v_action_type,
        IF(v_exec_status = 'SUCCESS', 'RESOLVED', 'FAILED'),
        v_confidence_before,
        v_confidence_after
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-19 11:42:12

-- Seed Data for action_rules
LOCK TABLES `action_rules` WRITE;
INSERT INTO `action_rules` (rule_id, issue_type, action_type, is_automatic) VALUES 
(2, 'DEADLOCK', 'ROLLBACK_TRANSACTION', 1),
(3, 'CONNECTION_OVERLOAD', 'KILL_CONNECTION', 1),
(4, 'SLOW_QUERY', 'ADD_INDEX', 0),
(5, 'UNKNOWN_BUG', 'RESTART_SERVICE', 1);
UNLOCK TABLES;
