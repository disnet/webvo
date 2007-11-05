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
#add_recording.rb
#Schedules the programme identified by prog_id (channelID + start) to be recorded

require 'cgi'
require 'util'

puts "Content-Type: text/xml\n\n<tv>\n"
cgi = CGI.new
json = cgi.params['json'][0]
prog_id = cgi.params['prog_id'][0]
priority = cgi.params['priority'][0].to_i

error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Needs a Channel ID")

start = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
puts start
start = formatToRuby(start+Time.now.strftime(" %z")).strftime(DATE_TIME_FORMAT_RUBY_XML) unless json == "true"
puts start
chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME-1).to_i]
  
start_date = start[0..7]
start_time = start[8..13]

#error checking
#Check if times are valid
error_if_not_equal(start_date.to_i.to_s == start_date, true, "the date time needs to have only numbers in it")
error_if_not_equal(start_time.to_i < 240000, true, "Time must be millitary time")
error_if_not_equal(start_time[2..3].to_i < 60 , true, "Minutes must be less than 60")
  
#Check if dates are valid
error_if_not_equal(start_date[4..5].to_i <= 12 , true, "Starting month must be <= to 12")
error_if_not_equal(start_date[6..7].to_i <= 31, true, "Starting month error < 31") 

# Not enough free space if we have less than 100 megs (avail is in kbytes)
# -- Handle this differently.  Perhaps provide a warning to the user? 
#error_if_not_equal(freespace['available'].to_i > 102400, true, "not enough room on server")

show_row = databasequery("SELECT channelID, title, `sub-title`, episode, number, Programme.xmlNode,
                         DATE_FORMAT(start, '#{DATE_TIME_FORMAT_XML}') as start, 
                         DATE_FORMAT(stop, '#{DATE_TIME_FORMAT_XML}') as stop, 
                         DATE_FORMAT(start, '#{DATE_TIME_FORMAT_STRING}') as start_string, 
                         DATE_FORMAT(stop, '#{DATE_TIME_FORMAT_STRING}') as stop_string 
                         FROM Programme JOIN Channel USING(channelID)
                         WHERE channelID = '#{chan_id}' and start = #{start}").fetch_hash
now_time = Time.now
now_xml = now_time.strftime(DATE_TIME_FORMAT_RUBY_XML)

error_if_not_equal(show_row.nil?, false, "requested show not in source listings") 
error_if_not_equal(now_xml.to_i < show_row['stop'].to_i, true, "Today is #{now_time} and your requested show ends in the past at #{show_row['stop_string']}.  Please record only shows that are airing currently or in the future.")

start_string = formatToRuby(show_row['start']).localtime.strftime(DATE_TIME_FORMAT_STRING_RUBY)

filename = [show_row['title'],show_row['episode'],show_row['sub-title'],start_string,show_row['number']].delete_if{|val| val.nil?}.join("_-_")

filename = Mysql.escape_string(format_filename(filename))

#todo: return a 'prog_id' and 'priority' (and xml?) for each overlaping show in an <error/>
overlapping_shows = []
databasequery("SELECT filename from Scheduled WHERE 
               (start < #{show_row['stop']}) and
               (stop > #{show_row['start']}) and
               (priority >= #{priority})").each { |show|
    overlapping_shows.push(show[0].to_s.gsub(/_/," "))
}
error_if_not_equal(overlapping_shows.length, 0, "Requested show occurs during: #{overlapping_shows.join(' and ')}")
databasequery("INSERT INTO Scheduled (channelID, start, stop, filename, priority) VALUES 
               ('#{chan_id}','#{start}','#{show_row['stop']}','#{filename}',#{priority})")
puts "<success>"
puts "<prog_id>#{prog_id}</prog_id>"
puts "#{show_row['xmlNode']}"
puts "</success>"

puts XML_FOOTER
