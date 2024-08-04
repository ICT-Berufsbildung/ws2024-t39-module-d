-- MariaDB dump 10.19  Distrib 10.11.6-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: uvdesk
-- ------------------------------------------------------
-- Server version	10.11.6-MariaDB-0+deb12u1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `uv_saved_replies`
--

DROP TABLE IF EXISTS `uv_saved_replies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `uv_saved_replies` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `subject` varchar(255) DEFAULT NULL,
  `message` longtext NOT NULL,
  `template_id` int(11) DEFAULT NULL,
  `is_predefind` tinyint(1) DEFAULT 1,
  `message_inline` longtext DEFAULT NULL,
  `template_for` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `IDX_39C8BA50A76ED395` (`user_id`),
  CONSTRAINT `FK_39C8BA50A76ED395` FOREIGN KEY (`user_id`) REFERENCES `uv_user_instance` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `uv_saved_replies`
--

LOCK TABLES `uv_saved_replies` WRITE;
/*!40000 ALTER TABLE `uv_saved_replies` DISABLE KEYS */;
INSERT INTO `uv_saved_replies` VALUES
(1,1,'WSC2024',NULL,'<p class=\"western\" lang=\"en-US\" align=\"justify\"><span style=\"font-family: Arial, serif;\"><span style=\"font-size: medium;\"><span lang=\"en-SG\"><strong>What are the causes of the problem?</strong></span></span></span></p>\r\n<p class=\"western\" lang=\"en-US\" align=\"justify\">&nbsp;</p>\r\n<p class=\"western\" lang=\"en-US\" align=\"justify\"><span style=\"font-family: Arial, serif;\"><span style=\"font-size: medium;\"><span lang=\"en-SG\"><strong>Recommended solutions to fix this:</strong></span></span></span></p>',NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `uv_saved_replies` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2024-08-04 15:17:13