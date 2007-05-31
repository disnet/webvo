#!/usr/bin/env ruby
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

require 'cgi'
require 'mysql'
require 'logger'
require 'util'

LENGTH_OF_TIME = 6
START = "start_date_time"
STOP = "end_date_time"
LOG = Logger.new(LOG_PATH+"form_listing_log.txt")
LOG.level = Logger::DEBUG

puts XML_HEADER

cgi = CGI.new                      # The CGI object is how we get the arguments 
  
error_if_not_equal(cgi.has_key?(START), true, "Need start date time")
error_if_not_equal(cgi.has_key?(STOP), true, "Need end date time")

start_date_time = cgi.params[START][0]
end_date_time = cgi.params[STOP][0]

#checks lengths of arguments to make sure the have the length of YYYYMMDDHHMMSS
error_if_not_equal(start_date_time.length, LENGTH_OF_DATE_TIME, "incorrect len for start date")
error_if_not_equal(end_date_time.length, LENGTH_OF_DATE_TIME, "incorrect len for end date")
  
start_date = start_date_time[0..7]
end_date = end_date_time[0..7]
start_time = start_date_time[8..13]
end_time = end_date_time[8..13]

#Check if date stamp valid
error_if_not_equal(start_date_time.to_i < end_date_time.to_i, true, "Start time must be before end time")

#Check if times are valid
error_if_not_equal(start_time.to_i < 240000, true, "Start time must be millitary time")
error_if_not_equal(end_time.to_i < 240000, true, "End time must be millitary time") 
error_if_not_equal(start_time[2..3].to_i < 60 , true, "Start minutes must be less than 60")
error_if_not_equal(end_time[2..3].to_i < 60, true, "End minutes must be less than 60")

#Check if dates are valid
error_if_not_equal(start_date[4..5].to_i <= 12 , true, "Starting month must be <= to 12")
error_if_not_equal(end_date[4..5].to_i <= 12 , true, "Ending month error < 12")
error_if_not_equal(start_date[6..7].to_i <= 31, true, "Starting month error < 31") 
error_if_not_equal(end_date[6..7].to_i <= 31, true, "Ending day must be less than 31")

before_query = Time.now
#Get output the information into output
dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
dbh.query("SELECT xmlNode from Programme WHERE 
          (start < #{end_date_time}) and
          (stop > #{start_date_time})").each { |prog| puts prog }
after_query = Time.now
LOG.debug("SQL query on start: #{start_date_time}  and stop: #{end_date_time}  took: " + (after_query - before_query).to_s)

puts XML_FOOTER
dbh.close()
  
#checking to see if the user requested an unavailable timeframe
#error_if_not_equal(start >= oldest_e, true, "Ran off begining of info.xml")
#error_if_not_equal(stop <= newest_e, true, "Ran off end of info.xml")
