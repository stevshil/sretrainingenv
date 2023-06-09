CREATE DATABASE IF NOT EXISTS `tpscd`;

USE `tpscd`;

CREATE TABLE `compact_discs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(150) DEFAULT NULL,
  `artist` varchar(130) DEFAULT NULL,
  `tracks` int DEFAULT NULL,
  `price` double DEFAULT NULL,
  PRIMARY KEY (`id`)
);

LOCK TABLES `compact_discs` WRITE;
INSERT INTO `compact_discs` VALUES (9,'Is This It','The Strokes',11,13.99),
(10,'Just Enough Education To Perform','Stereophonics',11,10.99),
(11,'Parachutes','Coldplay',10,11.99),
(12,'White Ladder','David Gray',10,9.99),
(13,'Greatest Hits','Penelope',14,14.99),
(14,'Echo Park','Feeder',12,13.99),
(15,'Mezzanine','Massive Attack',11,12.99),
(16,'Invisible Touch','Genesis',11,4.99);
UNLOCK TABLES;

CREATE TABLE `tracks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `cd_id` int NOT NULL,
  `title` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cd_id` (`cd_id`),
  CONSTRAINT `tracks_ibfk_1` FOREIGN KEY (`cd_id`) REFERENCES `compact_discs` (`id`)
);