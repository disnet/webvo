#!/usr/local/bin/ruby
################################################################################
#WebVo: Web-based PVR
#Copyright (C) 2006 Molly Jo Bault, Tim Disney, Daryl Siu

#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
################################################################################

require "date"
require "mysql"
require "logger"

LOG = Logger.new(STDOUT)
LOG.level = Logger::DEBUG

f = File.new('webvo.conf','r')
conf = f.read
f.close

xml_file_name = conf.match(/(\s*XML_FILE_NAME\s*)=\s*(.*)/)
XML_FILE_NAME = xml_file_name[2]

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

log_path = conf.match(/(\s*LOG_PATH\s*)=\s*(.*)/)
LOG_PATH = log_path[2]

encoder_bin = conf.match(/(\s*ENCODER_BIN\s*)=\s*(.*)/)
ENCODER_BIN = encoder_bin[2]

SLEEP_TIME = 60

def formatToRuby (xmlform_data)
   year = xmlform_data[0..3].to_i
   month = xmlform_data[4..5].to_i
   day = xmlform_data[6..7].to_i
   hour = xmlform_data[8..9].to_i
   minute = xmlform_data[10..11].to_i
   second = xmlform_data[12..13].to_i
   result = DateTime.new(year,month,day,hour,minute,second,DateTime.now.offset)
   return result
end
#
#calculate the difference between two given dates in seconds
def calcSecUntil(date1,date2)
  diffstop = date1 - date2
  sh,sm,ss,sfrac = Date.day_fraction_to_time(diffstop)
  diffstopInS = (sh)*3600 + (sm)*60 + ss
  return diffstopInS
end

#connect to the database
def databaseconnect()
    begin
        dbh = Mysql.real_connect(
            "#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
    rescue MysqlError => e
        log.error("Error code: #{e.errno}")
        log.error("Error message: #{e.error}")
        log.error("Unable to connect to database. Error code: #{e.errno} Message: #{e.error}")
        if dbh.nil? == false
            dbh.close() 
        end
        exit
    end
 
  return dbh
end

def getNextShow()
    dbh = databaseconnect()
    show_result = dbh.query("SELECT Recording.channelID,Recording.start , number AS 'Channel Number',Programme.stop , title FROM Recording, Channel, Programme WHERE (Recording.channelID = Programme.channelID) AND (Recording.start = Programme.start) AND (Recording.channelID = Channel.channelID) ORDER BY start")

    next_show = show_result.fetch_hash
    LOG.debug("The next show to record is #{next_show['title']}")
    return next_show
    dbh.close()
end

def isTime(show)
    show_start = formatToRuby(show['start'])
    show_stop = formatToRuby(show['stop'])
    starts_in = calcSecUntil(show_start,DateTime.now)
    stops_in = calcSecUntil(show_stop,DateTime.now)

    LOG.debug(starts_in)
    LOG.debug(stops_in)

    if (show_start < DateTime.now) and (show_stop > DateTime.now)
        return true
    else
        return false
    end
end

while true
    next_show = getNextShow() 
    if isTime(next_show)
        LOG.debug("It is time to start recording...")
    end
    LOG.debug("will sleep for #{SLEEP_TIME}")
    # I think the sleep time should the number of seconds until the next minute, a calculated value -- dmh
    sleep(SLEEP_TIME)
end
