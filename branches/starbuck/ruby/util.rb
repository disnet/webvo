#!/usr/bin/env ruby

conf = File.read('webvo.conf')

xml_file_name = conf.match(/(\s*XML_FILE_NAME\s*)=\s*(.*)/)
XML_FILE_NAME = xml_file_name[2]

xmltv_config = conf.match(/(\s*XMLTV_CONFIG\s*)=\s*(.*)/)
XMLTV_CONFIG = xmltv_config[2]

servername = conf.match(/(\s*SERVERNAME\s*)=\s*(.*)/)
SERVERNAME = servername[2]

username = conf.match(/(\s*USERNAME\s*)=\s*(.*)/)
USERNAME = username[2]

userpass = conf.match(/(\s*USERPASS\s*)=\s*(.*)/)
USERPASS = userpass[2]

dbname = conf.match(/(\s*DBNAME\s*)=\s*(.*)/)
DBNAME = dbname[2]

tablename = conf.match(/(\s*TABLENAME\s*)=\s*(.*)/)
TABLENAME = tablename[2]

video_path = conf.match(/(\s*VIDEO_PATH\s*)=\s*(.*)/)
VIDEO_PATH = video_path[2]

LOG_PATH = conf.match(/(\s*LOG_PATH\s*)=\s*(.*)/)[2]

ENCODER_BIN = conf.match(/(\s*ENCODER_BIN\s*)=\s*(.*)/)[2]

FILE_PART = conf.match(/(\s*FILE_PART\s*)=\s*(.*)/)[2]

CONFIG_PATH = conf.match(/(\s*CONFIG_PATH\s*)=\s*(.*)/)[2]


LENGTH_OF_DATE_TIME = 14

SUPPORTED_ENCODING_SCHEMES= [".mpg", ".avi"]
SUPPORTED_FILE_TYPES = [".mpg", ".avi"]

XML_HEADER = "Content-Type:text/xml\n\n<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<!DOCTYPE tv SYSTEM \"xmltv.dtd\">\n<tv source-info-url=\"http://labs.zap2it.com/\" source-info-name=\"TMS Data Direct Service\" generator-info-name=\"XMLTV\" generator-info-url=\"http://www.xmltv.org/\">"

XML_FOOTER = "</tv>"

DATE_FORMAT_STRING = "%Y%m%d"
DATE_TIME_FORMAT_STRING = "%Y-%m-%d_[%H.%i.%S]"
DATE_TIME_FORMAT_STRING_RUBY = "%Y-%m-%d_[%H.%M.%S]"
DATE_TIME_FORMAT_XML= "%Y%m%d%H%i%S"
DATE_TIME_FORMAT_RUBY_XML= "%Y%m%d%H%M%S"

def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts "<error>Error: " + error_string +"</error>"
    puts XML_FOOTER
    exit
  end
end

def databaseconnect()
    begin
        dbh = Mysql.real_connect(
            "#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
    rescue MysqlError => e
        #log.error("Error code: #{e.errno}")
        #log.error("Error message: #{e.error}")
        #log.error("Unable to connect to database. Error code: #{e.errno} Message: #{e.error}")
        puts ("Unable to connect to database. Error code: #{e.errno} Message: #{e.error}")
        puts XML_FOOTER
        exit
    end
    return dbh
end

def databasequery(query_str)
    dbh = databaseconnect()
    begin
        result = dbh.query(query_str)
    rescue MysqlError => e
        #log.error("Error code: #{e.errno}")
        #log.error("Error message: #{e.error}")
        #log.error("Error in database query. Error code: #{e.errno} Message: #{e.error}")
        puts "<error>Error in database query. Error code: #{e.errno} Message: #{e.error}</error>"
        puts XML_FOOTER
        exit
    ensure
        dbh.close if dbh
    end
    return result
end

def hours_in (start, stop)
    startTime = formatToRuby(start)
    stopTime = formatToRuby(stop)
    hours = []
    hour = startTime - startTime.min * 60 - startTime.sec
    while hour < stopTime
        hours << hour.strftime(DATE_TIME_FORMAT_RUBY_XML)
        hour += 60 * 60
    end
    return hours
end

def formatToRuby (xmlform_data)
   year = xmlform_data[0..3].to_i
   month = xmlform_data[4..5].to_i
   day = xmlform_data[6..7].to_i
   hour = xmlform_data[8..9].to_i
   minute = xmlform_data[10..11].to_i
   second = xmlform_data[12..13].to_i
   Time.local(year,month,day,hour,minute,second)
end

