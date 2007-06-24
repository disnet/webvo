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
  PRIMARY KEY  (`channelID`,`start`)
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
  KEY `showing_index` (`showing`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
-- --------------------------------------------------------

-- 
-- Table structure for table `Recurrence`
-- 

CREATE TABLE `Recurrence` (
  `channelID` char(60) NOT NULL,
  `start` time NOT NULL,
  `days` char(8) NOT NULL,
  `priority` integer NOT NULL,
  PRIMARY KEY  (`channelID`,`start`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
