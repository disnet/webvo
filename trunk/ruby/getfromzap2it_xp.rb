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

#SUMMARY: Imports information from zap2it.com by using
#using "xmltv-0.5.44-win32" a SOAP client
#from zap2it.com 


require 'date'
require 'mysql'
require 'xml/libxml'

SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVo"
TABLENAME = "Recording"

#opening/creating log file
logfile = File.new("logfile.txt", "a")

#make sure xmltv.exe in current directory
#cur_dir_entries=Dir.entries(Dir.getwd)
xmltv_pres = true

#xmltv_pres = cur_dir_entries.include?("xmltv.exe")

#Get xmltv data
before_run_time = Time.new
after_run_time = Time.new
xmltv_ran = false

if xmltv_pres == true then 
  before_run_time = Time.new
  xmltv_ran = system( "tv_grab_na_dd --output info.xml")
end
after_run_time = Time.new
if xmltv_ran == true then
  logfile << "Download Started " << before_run_time << "\n"
  logfile <<"Download Finished" << after_run_time<< "\n"

else
  logfile << "xmltv.exe failed to run at " << after_run_time << "\n" 
  
  if xmltv_pres == false then
    logfile << "xmltv.exe not current directory\n"
  end
  
end

logfile << "\n\n"
logfile.close()

#populating channels in database
  xmldoc = XML::Document.file("info.xml")

  #connect to database
  begin
  dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
#  if get an error (can't connect)
  rescue MysqlError => e
      error_if_not_equal(false,true, "Error code: " + e.errno + "\n")
      error_if_not_equal(false,true, "Error message: "+ e.error + "\n")
    puts "Unable to connect to database\n"
    if dbh.nil? == false
      #close the database
      dbh.close() 
    end
  else
  #get channel_id and number and send to database
  #This code will compare four cases
  #1. If a new channel has been added it will update the database
  #2. If a channel has been removed it will check programme to see 
  #   if it is in use and if not it will delete it
  #set up an array of all of the channel IDs to see if a channel has been taken off the air
    chan_array = Array.new(0)
    db_channelIDs = dbh.query("SELECT ChannelID FROM channel")
    if db_channelIDs != nil:
      channelIDs.each do |ci|
        chan_array << ci[0]
      end
    end
    xmldoc.find('channel').each do |e|	  
      chan_id = e["id"].to_s
      chan_number = e.child.content.to_i.to_s
      #send to database
      #check if exists already
      if  chan_array.include?(chan_id) :
        #delete from array
        chan_id.delete(chan_id)
      else
      #if it doesn't exist add it to the database
        dbh.query("INSERT INTO channel (ChannelID, number) VALUES (#{chan_id}, #{chan_number})")
      end
    end
    
    #go through removed channels and see if in use by programme, if so leave it 
    #otherwise delete
    chan_array.each do |ci|
      db_prog_using_chan = dbh.query("SELECT ChannelID FROM programme WHERE ChannelID=(#{ci})")
      if db_prog_using_chan == nil:
        #if no programmes using that channel then delete it from channel
        puts "deleting channel with ID " + ci
        dbh.query("DELETE FROM channel WHERE ChannelID=(#{ci})")
      else
        puts ci + " still in use!"
      end
    end
    
  end 