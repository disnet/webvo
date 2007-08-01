#!/usr/bin/env ruby

require "mysql"

def load_config
    config = Hash.new
    File.read('webvo.conf').each { |line|
        line_reg = line.match(/\s*(.*?)\s*=\s*(.*)/)
        config[line_reg[1]] = line_reg[2] unless line_reg.nil?
    }
    return config
end

constants = load_config

XML_FILE_NAME = constants[:XML_FILE_NAME.to_s]
XMLTV_CONFIG = constants[:XMLTV_CONFIG.to_s]
SERVERNAME = constants[:SERVERNAME.to_s]
USERNAME = constants[:USERNAME.to_s]
USERPASS = constants[:USERPASS.to_s]
DBNAME = constants[:DBNAME.to_s]
VIDEO_PATH = constants[:VIDEO_PATH.to_s]
LOG_PATH = constants[:LOG_PATH.to_s]
ENCODER_BIN = constants[:ENCODER_BIN.to_s]
CONFIG_PATH = constants[:CONFIG_PATH.to_s]
FILE_PADDING = constants[:FILE_PADDING.to_i]

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

#this function finds the available free space on the hard drive
def freespace()
    #runs UNIX free space command
    readme = IO.popen("df #{VIDEO_PATH}")
    space_raw = readme.read
    readme.close 

    #get information from the command line as to how much space is available
    space_match = space_raw.match(/\s(\d+)\s+(\d+)\s+(\d+)/)
    space = Hash.new(0)
    unless space_match.nil?
        space['total'] = space_match[1]
        space['used'] = space_match[2]
        space['available'] = space_match[3]
    end

    return space
end

class PaddedTime
    def PaddedTime.start
        Time.now + load_config["FILE_PADDING"].to_i
    end
    def PaddedTime.stop
        Time.now - load_config["FILE_PADDING"].to_i
    end
    def PaddedTime.strstart
        PaddedTime.start.strftime(DATE_TIME_FORMAT_RUBY_XML)
    end
    def PaddedTime.strstop
        PaddedTime.stop.strftime(DATE_TIME_FORMAT_RUBY_XML)
    end
end
