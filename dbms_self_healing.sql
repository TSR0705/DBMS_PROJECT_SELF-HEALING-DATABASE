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
-- Table structure for table `admin_reviews`
--

DROP TABLE IF EXISTS `admin_reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin_reviews` (
  `review_id` bigint NOT NULL AUTO_INCREMENT,
  `decision_id` bigint NOT NULL,
  `admin_action` enum('PENDING','APPROVED','REJECTED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `admin_comment` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `override_flag` tinyint(1) NOT NULL DEFAULT '0',
  `reviewed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`review_id`),
  KEY `idx_review_decision_id` (`decision_id`),
  CONSTRAINT `fk_review_decision` FOREIGN KEY (`decision_id`) REFERENCES `decision_log` (`decision_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `admin_reviews`
--

LOCK TABLES `admin_reviews` WRITE;
/*!40000 ALTER TABLE `admin_reviews` DISABLE KEYS */;
INSERT INTO `admin_reviews` VALUES (1,2,'PENDING',NULL,0,'2026-03-10 04:04:22'),(2,4,'PENDING',NULL,0,'2026-03-10 04:05:31'),(3,7,'PENDING',NULL,0,'2026-03-20 05:32:36'),(4,9,'PENDING',NULL,0,'2026-03-20 05:32:36'),(5,11,'PENDING',NULL,0,'2026-03-20 05:32:36'),(6,13,'PENDING',NULL,0,'2026-03-20 05:32:36'),(7,15,'PENDING',NULL,0,'2026-03-20 05:32:36'),(10,2,'APPROVED','Looks fine',0,'2026-03-20 05:33:16'),(11,4,'REJECTED','Issue unclear',1,'2026-03-20 05:33:16'),(12,6,'APPROVED','Proceed',0,'2026-03-20 05:33:16'),(13,8,'REJECTED','Needs more data',1,'2026-03-20 05:33:16'),(14,10,'APPROVED','OK',0,'2026-03-20 05:33:16'),(15,2,'APPROVED','Rechecked',0,'2026-03-20 05:33:16'),(16,4,'REJECTED','Still invalid',1,'2026-03-20 05:33:16'),(17,6,'APPROVED','Confirmed',0,'2026-03-20 05:33:16'),(18,8,'REJECTED','Retry later',1,'2026-03-20 05:33:16'),(19,10,'APPROVED','Final approval',0,'2026-03-20 05:33:16');
/*!40000 ALTER TABLE `admin_reviews` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ai_analysis`
--

DROP TABLE IF EXISTS `ai_analysis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ai_analysis` (
  `analysis_id` bigint NOT NULL AUTO_INCREMENT,
  `issue_id` bigint NOT NULL,
  `predicted_issue_class` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `severity_level` enum('LOW','MEDIUM','HIGH') COLLATE utf8mb4_unicode_ci NOT NULL,
  `risk_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `confidence_score` decimal(5,4) NOT NULL,
  `model_version` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL,
  `analyzed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`analysis_id`),
  KEY `idx_ai_issue_id` (`issue_id`),
  CONSTRAINT `fk_ai_issue` FOREIGN KEY (`issue_id`) REFERENCES `detected_issues` (`issue_id`) ON DELETE CASCADE,
  CONSTRAINT `ai_analysis_chk_1` CHECK ((`confidence_score` between 0 and 1))
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ai_analysis`
--

LOCK TABLES `ai_analysis` WRITE;
/*!40000 ALTER TABLE `ai_analysis` DISABLE KEYS */;
INSERT INTO `ai_analysis` VALUES (1,1,'TRANSACTION_CONFLICT','HIGH','CONSISTENCY_RISK',0.9200,'v1.0','2026-02-12 05:32:02'),(13,2,'SLOW_QUERY','MEDIUM','PERFORMANCE',0.8500,'v1','2026-03-20 05:38:25'),(14,3,'CONNECTION_OVERLOAD','HIGH','NETWORK',0.9200,'v1','2026-03-20 05:38:25'),(15,4,'TRANSACTION_FAILURE','MEDIUM','TRANSACTION',0.8000,'v1','2026-03-20 05:38:25'),(16,6,'DEADLOCK','HIGH','TRANSACTION',0.9500,'v2','2026-03-20 05:38:25'),(17,7,'SLOW_QUERY','LOW','PERFORMANCE',0.7000,'v2','2026-03-20 05:38:25'),(18,8,'CONNECTION_OVERLOAD','HIGH','NETWORK',0.9300,'v2','2026-03-20 05:38:25'),(19,9,'TRANSACTION_FAILURE','MEDIUM','TRANSACTION',0.8200,'v2','2026-03-20 05:38:25'),(20,10,'DEADLOCK','HIGH','TRANSACTION',0.9600,'v3','2026-03-20 05:38:25'),(21,11,'SLOW_QUERY','MEDIUM','PERFORMANCE',0.8800,'v3','2026-03-20 05:38:25');
/*!40000 ALTER TABLE `ai_analysis` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `decision_log`
--

DROP TABLE IF EXISTS `decision_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `decision_log` (
  `decision_id` bigint NOT NULL AUTO_INCREMENT,
  `issue_id` bigint NOT NULL,
  `decision_type` enum('AUTO_HEAL','ADMIN_REVIEW') COLLATE utf8mb4_unicode_ci NOT NULL,
  `decision_reason` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `confidence_at_decision` decimal(5,4) NOT NULL,
  `decided_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`decision_id`),
  KEY `idx_decision_issue_id` (`issue_id`),
  CONSTRAINT `fk_decision_issue` FOREIGN KEY (`issue_id`) REFERENCES `detected_issues` (`issue_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `decision_log`
--

LOCK TABLES `decision_log` WRITE;
/*!40000 ALTER TABLE `decision_log` DISABLE KEYS */;
INSERT INTO `decision_log` VALUES (1,1,'AUTO_HEAL','Deadlock resolved automatically',0.9000,'2026-03-10 04:03:32'),(2,2,'ADMIN_REVIEW','Requires manual review',0.7000,'2026-03-10 04:04:22'),(3,3,'AUTO_HEAL','Connection overload resolved',0.8500,'2026-03-10 04:04:59'),(4,4,'ADMIN_REVIEW','Requires manual review',0.7000,'2026-03-10 04:05:31'),(6,6,'AUTO_HEAL','Deadlock resolved automatically',0.9000,'2026-03-20 05:32:36'),(7,7,'ADMIN_REVIEW','Requires manual review',0.7000,'2026-03-20 05:32:36'),(8,8,'AUTO_HEAL','Connection overload resolved',0.8500,'2026-03-20 05:32:36'),(9,9,'ADMIN_REVIEW','Requires manual review',0.7000,'2026-03-20 05:32:36'),(10,10,'AUTO_HEAL','Deadlock resolved automatically',0.9000,'2026-03-20 05:32:36'),(11,11,'ADMIN_REVIEW','Requires manual review',0.7000,'2026-03-20 05:32:36'),(12,12,'AUTO_HEAL','Connection overload resolved',0.8500,'2026-03-20 05:32:36'),(13,13,'ADMIN_REVIEW','Requires manual review',0.7000,'2026-03-20 05:32:36'),(14,14,'AUTO_HEAL','Deadlock resolved automatically',0.9000,'2026-03-20 05:32:36'),(15,15,'ADMIN_REVIEW','Requires manual review',0.7000,'2026-03-20 05:32:36'),(26,1,'AUTO_HEAL','Test FK working',0.9500,'2026-03-20 05:42:03'),(28,16,'AUTO_HEAL','Deadlock resolved automatically',0.9000,'2026-03-20 05:42:28'),(29,17,'AUTO_HEAL','Deadlock resolved automatically',0.9000,'2026-03-20 05:56:35'),(30,18,'AUTO_HEAL','Deadlock resolved automatically',0.9000,'2026-03-20 05:57:37'),(31,19,'AUTO_HEAL','Connection overload resolved',0.8500,'2026-03-20 05:57:46'),(32,20,'AUTO_HEAL','Connection overload resolved',0.8500,'2026-03-22 06:51:59');
/*!40000 ALTER TABLE `decision_log` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_decision_insert` AFTER INSERT ON `decision_log` FOR EACH ROW BEGIN

IF NEW.decision_type = 'ADMIN_REVIEW' THEN

INSERT INTO admin_reviews
(decision_id, admin_action, reviewed_at)
VALUES
(NEW.decision_id, 'PENDING', NOW());

END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_autoheal_decision` AFTER INSERT ON `decision_log` FOR EACH ROW BEGIN

IF NEW.decision_type = 'AUTO_HEAL' THEN

INSERT INTO healing_actions
(decision_id, action_type, execution_mode, executed_by, execution_status)
VALUES
(
NEW.decision_id,
'ROLLBACK_TRANSACTION',
'AUTOMATIC',
'SYSTEM',
'SUCCESS'
);

END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `detected_issues`
--

DROP TABLE IF EXISTS `detected_issues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detected_issues` (
  `issue_id` bigint NOT NULL AUTO_INCREMENT,
  `issue_type` enum('DEADLOCK','SLOW_QUERY','CONNECTION_OVERLOAD','TRANSACTION_FAILURE') COLLATE utf8mb4_unicode_ci NOT NULL,
  `detection_source` enum('INNODB','PERFORMANCE_SCHEMA','SLOW_QUERY_LOG') COLLATE utf8mb4_unicode_ci NOT NULL,
  `raw_metric_value` decimal(10,2) DEFAULT NULL,
  `raw_metric_unit` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `detected_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`issue_id`),
  KEY `idx_detected_issues_time` (`detected_at`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detected_issues`
--

LOCK TABLES `detected_issues` WRITE;
/*!40000 ALTER TABLE `detected_issues` DISABLE KEYS */;
INSERT INTO `detected_issues` VALUES (1,'DEADLOCK','INNODB',1.00,'transaction','2026-03-10 04:03:32'),(2,'SLOW_QUERY','SLOW_QUERY_LOG',5.00,'seconds','2026-03-10 04:04:22'),(3,'CONNECTION_OVERLOAD','PERFORMANCE_SCHEMA',200.00,'connections','2026-03-10 04:04:59'),(4,'TRANSACTION_FAILURE','INNODB',3.00,'count','2026-03-10 04:05:31'),(6,'DEADLOCK','INNODB',1.00,'transaction','2026-03-20 05:32:36'),(7,'SLOW_QUERY','SLOW_QUERY_LOG',4.00,'seconds','2026-03-20 05:32:36'),(8,'CONNECTION_OVERLOAD','PERFORMANCE_SCHEMA',180.00,'connections','2026-03-20 05:32:36'),(9,'TRANSACTION_FAILURE','INNODB',2.00,'count','2026-03-20 05:32:36'),(10,'DEADLOCK','INNODB',3.00,'transaction','2026-03-20 05:32:36'),(11,'SLOW_QUERY','SLOW_QUERY_LOG',6.00,'seconds','2026-03-20 05:32:36'),(12,'CONNECTION_OVERLOAD','PERFORMANCE_SCHEMA',220.00,'connections','2026-03-20 05:32:36'),(13,'TRANSACTION_FAILURE','INNODB',5.00,'count','2026-03-20 05:32:36'),(14,'DEADLOCK','INNODB',2.00,'transaction','2026-03-20 05:32:36'),(15,'SLOW_QUERY','SLOW_QUERY_LOG',7.00,'seconds','2026-03-20 05:32:36'),(16,'DEADLOCK','INNODB',NULL,NULL,'2026-03-20 05:42:28'),(17,'DEADLOCK','INNODB',5.00,'transaction','2026-03-20 05:56:35'),(18,'DEADLOCK','INNODB',NULL,NULL,'2026-03-20 05:57:37'),(19,'CONNECTION_OVERLOAD','PERFORMANCE_SCHEMA',300.00,'connections','2026-03-20 05:57:46'),(20,'CONNECTION_OVERLOAD','INNODB',NULL,NULL,'2026-03-22 06:51:59');
/*!40000 ALTER TABLE `detected_issues` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_issue_insert` AFTER INSERT ON `detected_issues` FOR EACH ROW BEGIN

IF NEW.issue_type = 'DEADLOCK' THEN

INSERT INTO decision_log
(issue_id, decision_type, decision_reason, confidence_at_decision)
VALUES
(NEW.issue_id,'AUTO_HEAL','Deadlock resolved automatically',0.90);

ELSEIF NEW.issue_type = 'CONNECTION_OVERLOAD' THEN

INSERT INTO decision_log
(issue_id, decision_type, decision_reason, confidence_at_decision)
VALUES
(NEW.issue_id,'AUTO_HEAL','Connection overload resolved',0.85);

ELSE

INSERT INTO decision_log
(issue_id, decision_type, decision_reason, confidence_at_decision)
VALUES
(NEW.issue_id,'ADMIN_REVIEW','Requires manual review',0.70);

END IF;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `healing_actions`
--

DROP TABLE IF EXISTS `healing_actions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `healing_actions` (
  `action_id` bigint NOT NULL AUTO_INCREMENT,
  `decision_id` bigint NOT NULL,
  `action_type` enum('ROLLBACK_TRANSACTION','KILL_CONNECTION','RETRY_OPERATION') COLLATE utf8mb4_unicode_ci NOT NULL,
  `execution_mode` enum('AUTOMATIC','ADMIN_APPROVED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `executed_by` enum('SYSTEM','ADMIN') COLLATE utf8mb4_unicode_ci NOT NULL,
  `execution_status` enum('SUCCESS','FAILED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `executed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`action_id`),
  KEY `idx_action_decision_id` (`decision_id`),
  KEY `idx_healing_actions_time` (`executed_at`),
  CONSTRAINT `fk_action_decision` FOREIGN KEY (`decision_id`) REFERENCES `decision_log` (`decision_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `healing_actions`
--

LOCK TABLES `healing_actions` WRITE;
/*!40000 ALTER TABLE `healing_actions` DISABLE KEYS */;
INSERT INTO `healing_actions` VALUES (1,1,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','FAILED','2026-03-10 04:03:32'),(2,3,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-10 04:04:59'),(4,6,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:32:36'),(5,8,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:32:36'),(6,10,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:32:36'),(7,12,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:32:36'),(8,14,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:32:36'),(21,7,'RETRY_OPERATION','ADMIN_APPROVED','ADMIN','FAILED','2026-03-20 05:38:51'),(22,9,'RETRY_OPERATION','ADMIN_APPROVED','ADMIN','SUCCESS','2026-03-20 05:38:51'),(23,11,'KILL_CONNECTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:38:51'),(24,26,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','FAILED','2026-03-20 05:42:03'),(25,28,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:42:28'),(26,29,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:56:35'),(27,30,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:57:37'),(28,31,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-20 05:57:46'),(29,32,'ROLLBACK_TRANSACTION','AUTOMATIC','SYSTEM','SUCCESS','2026-03-22 06:51:59');
/*!40000 ALTER TABLE `healing_actions` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `after_healing_action` AFTER INSERT ON `healing_actions` FOR EACH ROW BEGIN

INSERT INTO learning_history
(issue_type, action_type, outcome, confidence_before, confidence_after)
SELECT
d_i.issue_type,
NEW.action_type,
'RESOLVED',
d.confidence_at_decision,
d.confidence_at_decision + 0.02
FROM decision_log d
JOIN detected_issues d_i
ON d.issue_id = d_i.issue_id
WHERE d.decision_id = NEW.decision_id;

END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `learning_history`
--

DROP TABLE IF EXISTS `learning_history`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `learning_history` (
  `learning_id` bigint NOT NULL AUTO_INCREMENT,
  `issue_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `action_type` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `outcome` enum('RESOLVED','FAILED') COLLATE utf8mb4_unicode_ci NOT NULL,
  `confidence_before` decimal(5,4) NOT NULL,
  `confidence_after` decimal(5,4) NOT NULL,
  `recorded_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`learning_id`),
  KEY `idx_learning_issue_action` (`issue_type`,`action_type`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `learning_history`
--

LOCK TABLES `learning_history` WRITE;
/*!40000 ALTER TABLE `learning_history` DISABLE KEYS */;
INSERT INTO `learning_history` VALUES (1,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.9000,0.9200,'2026-03-10 04:03:32'),(2,'CONNECTION_OVERLOAD','ROLLBACK_TRANSACTION','RESOLVED',0.8500,0.8700,'2026-03-10 04:04:59'),(4,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.9000,0.9200,'2026-03-20 05:32:36'),(5,'CONNECTION_OVERLOAD','ROLLBACK_TRANSACTION','RESOLVED',0.8500,0.8700,'2026-03-20 05:32:36'),(6,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.9000,0.9200,'2026-03-20 05:32:36'),(7,'CONNECTION_OVERLOAD','ROLLBACK_TRANSACTION','RESOLVED',0.8500,0.8700,'2026-03-20 05:32:36'),(8,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.9000,0.9200,'2026-03-20 05:32:36'),(15,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.8000,0.9500,'2026-03-20 05:33:21'),(16,'SLOW_QUERY','RETRY_OPERATION','RESOLVED',0.7000,0.8500,'2026-03-20 05:33:21'),(17,'CONNECTION_OVERLOAD','KILL_CONNECTION','RESOLVED',0.8500,0.9300,'2026-03-20 05:33:21'),(18,'TRANSACTION_FAILURE','RETRY_OPERATION','FAILED',0.7500,0.8000,'2026-03-20 05:33:21'),(19,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.8200,0.9600,'2026-03-20 05:33:21'),(20,'SLOW_QUERY','RETRY_OPERATION','FAILED',0.6500,0.7000,'2026-03-20 05:33:21'),(21,'CONNECTION_OVERLOAD','KILL_CONNECTION','RESOLVED',0.8800,0.9400,'2026-03-20 05:33:21'),(22,'TRANSACTION_FAILURE','RETRY_OPERATION','RESOLVED',0.7800,0.8500,'2026-03-20 05:33:21'),(23,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.9000,0.9700,'2026-03-20 05:33:21'),(24,'SLOW_QUERY','RETRY_OPERATION','RESOLVED',0.7200,0.8800,'2026-03-20 05:33:21'),(25,'SLOW_QUERY','RETRY_OPERATION','RESOLVED',0.7000,0.7200,'2026-03-20 05:38:51'),(26,'TRANSACTION_FAILURE','RETRY_OPERATION','RESOLVED',0.7000,0.7200,'2026-03-20 05:38:51'),(27,'SLOW_QUERY','KILL_CONNECTION','RESOLVED',0.7000,0.7200,'2026-03-20 05:38:51'),(28,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.9500,0.9700,'2026-03-20 05:42:03'),(29,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.9000,0.9200,'2026-03-20 05:42:28'),(30,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.9000,0.9200,'2026-03-20 05:56:35'),(31,'DEADLOCK','ROLLBACK_TRANSACTION','RESOLVED',0.9000,0.9200,'2026-03-20 05:57:37'),(32,'CONNECTION_OVERLOAD','ROLLBACK_TRANSACTION','RESOLVED',0.8500,0.8700,'2026-03-20 05:57:46'),(33,'CONNECTION_OVERLOAD','ROLLBACK_TRANSACTION','RESOLVED',0.8500,0.8700,'2026-03-22 06:51:59');
/*!40000 ALTER TABLE `learning_history` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `test_table`
--

DROP TABLE IF EXISTS `test_table`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_table` (
  `id` int NOT NULL,
  `value` int DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `test_table`
--

LOCK TABLES `test_table` WRITE;
/*!40000 ALTER TABLE `test_table` DISABLE KEYS */;
INSERT INTO `test_table` VALUES (1,40),(2,20),(11,110);
/*!40000 ALTER TABLE `test_table` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-22 14:23:11
