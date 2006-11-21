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
#form_recording.rb
#sends recording information to client

require 'cgi'
require 'xml/libxml'
require 'date'
require "mysql"

SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVo"
TABLENAME = "Recording"

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
#open up database
#for each entry in recording
  #get the channel_id and start_time
  #look up channel_id and start_time in programme
  #get the xmlNode information
  #using start date time and stop date time estimate the size of the file
  



