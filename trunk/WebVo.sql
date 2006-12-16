-- phpMyAdmin SQL Dump
-- version 2.8.0.3-Debian-1
-- http://www.phpmyadmin.net
-- 
-- Host: localhost
-- Generation Time: Dec 15, 2006 at 05:43 PM
-- Server version: 5.0.22
-- PHP Version: 5.1.2
-- 
-- Database: `WebVoFast`
-- 

-- --------------------------------------------------------

-- 
-- Table structure for table `Channel`
-- 

CREATE TABLE `Channel` (
  `channelID` varchar(50) NOT NULL,
  `number` varchar(20) NOT NULL,
  PRIMARY KEY  (`channelID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

-- 
-- Table structure for table `Programme`
-- 

CREATE TABLE `Programme` (
  `channelID` varchar(50) NOT NULL,
  `start` varchar(20) NOT NULL,
  `stop` varchar(20) NOT NULL,
  `title` varchar(50) NOT NULL,
  `xmlNode` text NOT NULL,
  PRIMARY KEY  (`channelID`,`start`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

-- 
-- Table structure for table `Recorded`
-- 

CREATE TABLE `Recorded` (
  `channelID` varchar(50) NOT NULL,
  `start` varchar(20) NOT NULL,
  `ShowName` varchar(1000) NOT NULL,
  PRIMARY KEY  (`channelID`,`start`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

-- 
-- Table structure for table `Recording`
-- 

CREATE TABLE `Recording` (
  `channelID` varchar(50) NOT NULL,
  `start` varchar(20) NOT NULL,
  `sleep_pid` varchar(20) NOT NULL,
  `cat_pid` varchar(20) NOT NULL,
  `CMD` varchar(100) NOT NULL,
  PRIMARY KEY  (`channelID`,`start`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
