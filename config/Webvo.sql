-- 
-- Database schema for WebVo
-- 

-- --------------------------------------------------------

-- 
-- Table structure for table `Channel`
-- 

CREATE TABLE `Channel` (
  `channelID` char(60) NOT NULL,
  `number` integer NOT NULL,
  `xmlNode` text NOT NULL,
  PRIMARY KEY  (`channelID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

-- 
-- Table structure for table `Programme`
-- 

CREATE TABLE `Programme` (
  `channelID` char(60) NOT NULL,
  `start` datetime NOT NULL,
  `stop` datetime NOT NULL,
  `title` varchar(250) NOT NULL,
  `sub-title` varchar(250),
  `description` varchar(4000),
  `episode` varchar(50),
  `credits` varchar(4000),
  `category` varchar(250),
  `xmlNode` text NOT NULL,
  KEY `title_index` (`title`),
  KEY `start_index` (`start`),
  KEY `stop_index` (`stop`),
  PRIMARY KEY  (`channelID`,`start`),
  FOREIGN KEY (`channelID`)
    REFERENCES `Channel` (`channelID`) 
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

-- 
-- Table structure for table `Recorded`
-- 

CREATE TABLE `Recorded` (
  `channelID` char(60) NOT NULL,
  `start` datetime NOT NULL,
  `filename` varchar(2000) NOT NULL,
  PRIMARY KEY  (`channelID`,`start`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

-- 
-- Table structure for table `Scheduled`
-- 

CREATE TABLE `Scheduled` (
  `channelID` char(60) NOT NULL,
  `start` datetime NOT NULL,
  `stop` datetime NOT NULL,
  `filename` varchar(2000) NOT NULL,
  `pid` integer,
  `priority` integer NOT NULL,
  PRIMARY KEY  (`channelID`,`start`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

-- 
-- Table structure for table `Listing`
-- 

CREATE TABLE `Listing` (
  `channelID` char(60) NOT NULL,
  `start` datetime NOT NULL,
  `showing` datetime NOT NULL,
  PRIMARY KEY  (`channelID`,`start`,`showing`),
  KEY `showing_index` (`showing`),
  FOREIGN KEY (`channelID`, `start`) 
    REFERENCES `Programme` (`channelID`, `start`) 
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- --------------------------------------------------------

-- 
-- Table structure for table `Recurrence`
-- 

CREATE TABLE `Recurrence` (
  `channelID` char(60) NOT NULL,
  `start` time NOT NULL,
  `stop` time NOT NULL,
  `priority` integer NOT NULL,
  PRIMARY KEY  (`channelID`,`start`, `stop`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- --------------------------------------------------------

-- 
-- Table structure for table `RecurrenceDays`
-- 

CREATE TABLE `RecurrenceDay` (
  `channelID` char(60) NOT NULL,
  `start` time NOT NULL,
  `stop` time NOT NULL,
  `day` char(10) NOT NULL,
  PRIMARY KEY  (`channelID`,`start`, `stop`, `day`),
  FOREIGN KEY (`channelID`, `start`, `stop`) 
    REFERENCES `Recurrence` (`channelID`, `start`, `stop`) 
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
