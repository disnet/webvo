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
  cgi = CGI.new     # The CGI object is how we get the arguments 
  #manually return header and parent beginning
  puts "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<!DOCTYPE tv SYSTEM \"xmltv.dtd\">\n<tv source-info-url=\"http://labs.zap2it.com/\" source-info-name=\"TMS Data Direct Service\" generator-info-name=\"XMLTV\" generator-info-url=\"http://www.xmltv.org/\">"
  have_recordings = false
#open up database
  begin
  dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
#  if gets an error (can't connect)
  rescue MysqlError => e
      error_if_not_equal(false,true, "Error code: " + e.errno + " " + e.error + "\n")
    if dbh.nil? == false
      #close the database
      dbh.close() 
    end
  else
    allrresults = dbh.query("SELECT start, channelID FROM Recording ORDER BY start")
    allrresults.each_hash do |row|
      start = row["start"]
      chan_id = row["channelID"]      
      show = dbh.query("SELECT xmlNode FROM Programme WHERE (start='#{start}' AND channelID='#{chan_id}')")
      show_info = show.fetch_row
      if show_info != nil:
        puts show_info.to_s.gsub("_*_", "'")
      else
        dbh.close()
        error_if_not_equal(true, false, "recording programme not in programme "+ start.to_s + " " + chan_id.to_s)
      end
      have_recordings = true	
    end	
    dbh.close()
  end
  #write up end of parent
  puts "\n</tv>" 




