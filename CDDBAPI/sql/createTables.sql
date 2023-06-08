CREATE DATABASE  IF NOT EXISTS `tpscd`;
USE `tpscd`;

CREATE TABLE `compact_discs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(150) DEFAULT NULL,
  `artist` varchar(130) DEFAULT NULL,
  `tracks` int DEFAULT NULL,
  `price` double DEFAULT NULL,
  PRIMARY KEY (`id`)
);

INSERT INTO `compact_discs` VALUES (9,'Is This It','The Strokes',11,13.99),
(10,'Just Enough Education To Perform','Stereophonics',11,10.99),
(11,'Parachutes','Coldplay',10,11.99),
(12,'White Ladder','David Gray',10,9.99),
(13,'Greatest Hits','Penelope',14,14.99),
(14,'Echo Park','Feeder',12,13.99),
(15,'Mezzanine','Massive Attack',11,12.99),
(16,'Spice World','Spice Girls',11,4.99);

CREATE TABLE `tracks` (
  `id` int NOT NULL AUTO_INCREMENT,
  `cd_id` int NOT NULL,
  `title` varchar(150) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `cd_id` (`cd_id`),
  CONSTRAINT `tracks_ibfk_1` FOREIGN KEY (`cd_id`) REFERENCES `compact_discs` (`id`)
);

INSERT INTO `tracks` VALUES (1,16,'Mama'),
(2,16,'Wannabe'),
(3,16,'Spice up your life'),
(19,9,'Is This It'),
(20,9,'The Modern Age'),
(21,9,'Soma'),
(22,9,'Barely Legal'),
(23,9,'Someday'),
(24,9,'Alone, Together'),
(25,9,'Last Nite'),
(26,9,'Hard To Explain'),
(27,9,'New York City Cops'),
(28,9,'Trying Your Luck'),
(29,9,'Take It Or Leave It'),
(30,12,'Please Forgive Me'),
(31,12,'Babylon'),
(32,12,'My Oh My'),
(33,12,'We\'re Not Right'),
(34,12,'Nightblindness'),
(35,12,'Silver Lining'),
(36,12,'White Ladder'),
(37,12,'This Year\'s Love'),
(38,12,'Sail Away'),
(39,12,'Say Hello, Wave Goodbye'),
(40,15,'Angel'),
(41,15,'Risingson'),
(42,15,'Teardrop'),
(43,15,'Inertia Creeps'),
(44,15,'Exchange'),
(45,15,'Dissolved Girl'),
(46,15,'Man Next Door'),
(47,15,'Black Milk'),
(48,15,'Mezzanine'),
(49,15,'Group Four'),
(50,15,'(Exchange)');