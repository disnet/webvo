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
#delete_recording.rb
#takes a programmeid from the front end and deletes it from the database

require "cgi"
require "util"

cgi = CGI.new
json = cgi.params['json'][0].to_s.downcase == "true"
prog_id = cgi.params['prog_id'][0]

puts "Content-Type:text/xml\n\n<?xml version='1.0' encoding='ISO-8859-1'?>\n<tv>" unless json
puts JSON_HEADER if json

error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Needs a Channel ID", json)

date_time = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
date_time = formatToRuby(date_time+Time.now.strftime(" %z")).strftime(DATE_TIME_FORMAT_RUBY_XML) unless json
chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME-1).to_i]
 
start_date = date_time[0..7]
start_time = date_time[8..13]

#Check if times are valid
error_if_not_equal(start_date.to_i.to_s == start_date, true, "the date time needs to have only numbers in it", json)
error_if_not_equal(start_time.to_i < 240000, true, "Time must be millitary time", json)
error_if_not_equal(start_time[2..3].to_i < 60 , true, "Minutes must be less than 60", json)

#Check if dates are valid
error_if_not_equal(start_date[4..5].to_i <= 12 , true, "Starting month must be <= to 12", json)
error_if_not_equal(start_date[6..7].to_i <= 31, true, "Starting month error < 31", json)

progxml = databasequery("SELECT xmlNode FROM Scheduled JOIN Programme USING(channelID, start) WHERE (channelID='#{chan_id}'AND start = '#{date_time}')").fetch_row
error_if_not_equal( progxml.nil?, false, "Show not scheduled", json)
databasequery("DELETE FROM Scheduled WHERE (channelID = '#{chan_id}'AND start = '#{date_time}')")

if json
    json_out = JSON_Output.new(JSON_Output::UNSCHEDULE)
    prog = Prog.new(XML::Parser.string(progxml[0].to_s).parse, 0)
    prog.set_json_output
    json_out.add_programme(prog)
    puts json_out
else
    puts "<success>"
    puts "<prog_id>#{prog_id}</prog_id>"
    puts "</success>"
    puts XML_FOOTER
end
