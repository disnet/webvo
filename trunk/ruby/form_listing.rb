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

# changing the order will break error xml formatting
cgi = CGI.new                      # The CGI object is how we get the arguments 
  
json = cgi.params['json'][0].to_s.downcase == "true"
hours = cgi.params['hours'][0]
hours = DEFAULT_LISTING_HOURS if hours.nil?
start_date_time = cgi.params[START][0]

puts XML_HEADER unless json
puts JSON_HEADER if json

if cgi.has_key?(START) and cgi.has_key?(STOP)
    end_date_time = cgi.params[STOP][0]
else
    temp_time = Time.new
    temp_time = temp_time - temp_time.min * 60 - temp_time.sec
    start_date_time = temp_time.strftime(DATE_TIME_FORMAT_RUBY_XML) if start_date_time.nil?
    end_date_time = (formatToRuby(start_date_time)+ hours.to_i * 60 * 60).strftime(DATE_TIME_FORMAT_RUBY_XML)
end

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
retstr = ""
zone = ""
zone = Time.now.strftime(" %z") #unless json
start_date_time += zone
end_date_time += zone
range = hours_in(start_date_time, end_date_time).join(",")
# Is there a faster, better way to do this?
# This should not be needed in the JSON output formatting
query = "SELECT DISTINCT xmlNode from Channel JOIN Listing USING(channelID) WHERE showing in (#{range})"
channels = databasequery(query) #.each { |chan| puts chan[0]}
query = "SELECT DISTINCT p.xmlNode, number from Programme p JOIN Listing USING(channelID, start) JOIN Channel USING(channelID) WHERE showing in (#{range}) ORDER BY number, start"
programmes = databasequery(query) #.each { |prog| puts prog[0] }

if json
    json_out = JSON_Output.new(JSON_Output::LISTING, start_date_time, end_date_time)
    programmes.each_hash {|hash|
        prog = Prog.new(XML::Parser.string(hash['xmlNode'].to_s).parse, hash['number'])
        prog.set_json_output
        json_out.add_programme(prog)
    }
    puts json_out
else
    channels.each { |chan| puts chan[0] }
    programmes.each { |prog| puts prog[0] }
    puts XML_FOOTER
end
  
after_query = Time.now
LOG.debug("SQL query on start: #{start_date_time}  and stop: #{end_date_time}  took: " + (after_query - before_query).to_s)

#checking to see if the user requested an unavailable timeframe
#error_if_not_equal(start >= oldest_e, true, "Ran off begining of info.xml")
#error_if_not_equal(stop <= newest_e, true, "Ran off end of info.xml")
