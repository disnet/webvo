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
#takes a programmeid from the front end and adds it to the database

require 'cgi'
require 'date'
require "mysql"

SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVo"
TABLENAME = "Recording"

LENGTH_OF_DATE_TIME = 14

SHOW_DIR = "/home/daryl/Desktop/TestVideos/"

def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts "<error>Error " + error_string +"</error>"
    exit
  end
end

def add_size_to_xml_Node(size, xmlNode)
  xmlNode.delete("</programme>\n")
  xmlNode << "<size>" + size + "</size>\n"
  xmlNode << "</programme>\n"
end

#main ------------------------------------------------------------------------------------
  puts "Content-Type: text/plain\n\n" 
  cgi = CGI.new     # The CGI object is how we get the arguments 
  #manually return header and parent beginning
  puts "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<!DOCTYPE tv SYSTEM \"xmltv.dtd\">\n<tv source-info-url=\"http://labs.zap2it.com/\" source-info-name=\"TMS Data Direct Service\" generator-info-name=\"XMLTV\" generator-info-url=\"http://www.xmltv.org/\">"


#connect to database
begin
dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
#  if gets an error (can't connect)
rescue MysqlError => e
      error_if_not_equal(false,true, "Error code: " + e.errno + " " + e.error + "\n")
    puts "Unable to connect to database\n"
    if dbh.nil? == false
      #close the database
      dbh.close() 
    end
  else
    puts "1"
    #look up information in directory where recorded shows are being saved
    
    #for each check against record.rb's pattern
    f_size = 0
    rec_dir = Dir.new(SHOW_DIR)
    rec_array = rec_dir.entries
    rec_info = dbh.query("SELECT start, channelID, ShowName FROM Recorded")  
    
    puts "2"
    #file may be there but need to compare with title in programme
      rec_info.each_hash do |recorded|
        puts "3"
        chan_id = recorded["channelID"]
        start = recorded["start"]
        show_name = recorded["ShowName"]
        
        #look up programme that matches start date and channelID to later compare with title
        programmes = dbh.query("SELECT * FROM Programme WHERE (start = '#{start}' AND channelID = '#{chan_id}')")
        got_programme = false
        channel_num_info = dbh.query("SELECT number FROM Channel WHERE (channelID = '#{chan_id}')")
        channel_num = channel_num_info.fetch_row
        programmes.each_hash do |programme|
          puts "4"
          if rec_array.include?(showName + ".mpg") && got_programme != false:
            f_size = File.size(+ ".mpg")
            puts add_size_to_xmlNode(f_size.to_i, xmlNode)
            got_programme = true
          else
            #duplicate in db or programme file not in directory either way entry should be deleted
            dbh.query("DELETE FROM Programme WHERE (channelID=('#{chan_id}') AND start = '#{start}')")
            dbh.query("DELETE FROM Recording WHERE (channelID=('#{chan_id}') AND start = '#{start}')")
          end
        end
      end
    puts "5"
    dbh.close()
  end
  puts "6"