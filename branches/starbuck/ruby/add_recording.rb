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
#add_recording.rb
#Schedules the programme identified by prog_id (channelID + start) to be recorded

require 'mysql'
require 'cgi'
require 'util'

PROG_ID = "prog_id"

#Functions-----------------------------------------------------------------------

#this function finds the available free space on the hard drive to determine
def freespace()
  #runs UNIX free space command
  readme = IO.popen("df #{VIDEO_PATH}")
  space_raw = readme.read
  readme.close

  space_match = space_raw.match(/\s(\d+)\s+(\d+)\s+(\d+)/)
  available = space_match[3]

    # Not enough free space if we have less than 100 megs (avail is in kbytes)
    if(available.to_i > 102400):
        return true
    else
        return false
    end
end

#main--------------------------------------------------------------------------
puts "Content-Type: text/xml\n\n<tv>\n"
cgi = CGI.new
prog_id = cgi.params['prog_id'][0]

error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Needs a Channel ID")

start = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
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

error_if_not_equal(freespace(), true, "not enough room on server")

show_row = databasequery("SELECT channelID, title, `sub-title`, episode, xmlNode, 
                         DATE_FORMAT(start, '#{DATE_TIME_FORMAT_XML}') as start, 
                         DATE_FORMAT(stop, '#{DATE_TIME_FORMAT_XML}') as stop, 
                         DATE_FORMAT(start, '#{DATE_TIME_FORMAT_STRING}') as start_string, 
                         DATE_FORMAT(stop, '#{DATE_TIME_FORMAT_STRING}') as stop_string 
                         FROM Programme WHERE channelID = '#{chan_id}' and start = #{start}").fetch_hash
now_time = Time.now
now_xml = now_time.strftime(DATE_TIME_FORMAT_RUBY_XML)

error_if_not_equal(show_row.nil?, false, "requested show not in source listings") 
error_if_not_equal(now_xml.to_i < show_row['stop'].to_i, true, "today is #{now_time} and your requested show ends in the past at #{show_row['stop_string']}.  Please record only shows that are airing currently or in the future.")

filename = String.new
[show_row['title'],show_row['episode'],show_row['sub-title'],show_row['start_string']].each {|namepart|
    if !namepart.nil?
        filename += "#{namepart}_-_"
    end
}
# is '-' a good replacement for a '/' in the filename?
filename = Mysql.escape_string(filename.gsub(/\//,'-').gsub(/ /, "_").sub(/_-_$/, ""))

#todo: return a 'prog_id' (and xml?) for each overlaping show in an <error/>
#   also include a priority value
overlaping_progs = databasequery("SELECT filename from Scheduled WHERE 
                                  (start < #{show_row['stop']}) and
                                  (stop > #{show_row['start']})").each {|showname_row|
    error_if_not_equal(true, false, "Requested show occurs during: #{showname_row.to_s.gsub(/_/," ")}")
}
databasequery("INSERT INTO Scheduled (channelID, start, stop, filename, priority) VALUES 
               ('#{chan_id}','#{start}','#{show_row['stop']}','#{filename}',0)")
puts "<success>"
puts "<prog_id>#{prog_id}</prog_id>"
puts "#{show_row['xmlNode']}"
puts "</success>"

puts XML_FOOTER
exit
#call record.rb
pid = fork do
    #STDIN.close
    #STDOUT.close
    #STDERR.close
    system('./record.rb &')
end
