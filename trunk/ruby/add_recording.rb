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
#takes a programmeid from the front end and adds it to the database

#!/usr/local/bin/ruby
require 'cgi'
require 'xml/libxml'
require 'date'

PROG_ID = "prog_id"
LENGTH_OF_DATE_TIME = 14
XML_FILE_NAME = "info.xml"



def file_available(file_name)
  cur_dir_entries=Dir.entries(Dir.getwd)
  return cur_dir_entries.include?(file_name)
end
#Error handler
def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts "<error>Error " + error_string +"</error>"
    exit
  end
end

#main--------------------------------------------------------------------------

  puts "Content-Type: text/xml\n\n" 
  
  #cgi = CGI.new     # The CGI object is how we get the arguments 
  
#checks for 1 argument
  #error_if_not_equal(cgi.keys.length, 1, "Need one arguments")

  #error_if_not_equal(cgi.has_key?(PROG_ID), true, "Need Programme ID")
#get argument
  prog_id = "11111111120061206080000" #cgi[PROG_ID][0]

  error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Needs a Channel ID")
  
  puts date_time = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME)..(prog_id.length-1)]
  puts chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME)]
  
  start_date = date_time[0][0..7]
  start_time = date_time[0][8..13]

#error checking
  #Check if times are valid
  error_if_not_equal(start_time.to_i < 240000, true, "Time must be millitary time")
  error_if_not_equal(start_time[2..3].to_i < 60 , true, "Minutes must be less than 60")
  
  #Check if dates are valid
  error_if_not_equal(start_date[4..5].to_i <= 12 , true, "Starting month must be <= to 12")
  error_if_not_equal(start_date[6..7].to_i <= 31, true, "Starting month error < 31") 

#get programme from info.xml
  error_if_not_equal(file_available(XML_FILE_NAME), true, XML_FILE_NAME +"not in directory")
  xml = XML::Document.file(XML_FILE_NAME)
  
  xml.find("programme") do |e|
    if xml["channel"] == chan_id &&

  
