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
#delete_recording.rb
#takes a programmeid from the front end and deletes it from the database

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
#checks for 1 argument
  error_if_not_equal(cgi.keys.length, 1, "Needs one argument")
  error_if_not_equal(cgi.has_key?(PROG_ID), true, "Needs Programme ID")
  
#get argument
  prog_id =  cgi[PROG_ID][0]

  error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Needs a Channel ID")

  date_time = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
  chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME-1).to_i]
  
  start_date = date_time[0..7]
  start_time = date_time[8..13]
#error checking
  #Check if times are valid
  error_if_not_equal(start_date.to_i.to_s == start_date, true, "the date time needs to have only numbers in it")
  error_if_not_equal(start_time.to_i < 240000, true, "Time must be millitary time")
  error_if_not_equal(start_time[2..3].to_i < 60 , true, "Minutes must be less than 60")
  
  #Check if dates are valid
  error_if_not_equal(start_date[4..5].to_i <= 12 , true, "Starting month must be <= to 12")
  error_if_not_equal(start_date[6..7].to_i <= 31, true, "Starting month error < 31")
  
  have_errored = false
#connect to database
  begin
    dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
  #if gets an error (can't connect)
  rescue MysqlError => e
      error_if_not_equal(false,true, "Error code: " + e.errno + " " + e.error + "\n")
    if dbh.nil? == false
      #close the database
      dbh.close() 
    end
  else
#look up programme in database
    presults = dbh.query("SELECT title FROM Programme WHERE (channelID = '#{chan_id}' AND start = '#{date_time}')")
    rresults = dbh.query("SELECT * FROM Recording WHERE (channelID ='#{chan_id}' AND start = '#{date_time}')")
    reced_results = dbh.query("SELECT * FROM Recording WHERE (channelID ='#{chan_id}' AND start = '#{date_time}')")
    
#if not there error
    rresult = rresults.fetch_row
    presult = presults.fetch_row
    reced_result = reced_results.fetch_row
    if(rresult == nil)
      puts "<error>Programme not in Recording</error>\n"
      have_errored = true
    else
	#check if it has a PID
      pids = dbh.query("SELECT PID From Recording WHERE (channelID = '#{chan_id}' AND start = '#{date_time}' AND PID)")
      #if it does kill the process
      pid_info = pids.fetch_row
      if pid_info != nil:
        CAT_PID = pid_info #need PID number
        readme = IO.popen("ps #{CAT_PID}")
        sleep (1)
        temp = readme.gets
        pid = readme.gets
        if pid != "NULL"
          commandSent = system("kill #{CAT_PID}")
        end
        if presult != nil:
          rec_dir = Dir.new(SHOW_DIR)
          rec_array = rec_dir.entries
          
          channel_info = dbh.query("SELECT number FROM Channel WHERE channelID ='#{chan_id}' LIMIT 1")
          channel_num = channel_info.fetch_row
          show_info = presult.to_s + "-" + date_time + channel_num
          dbh.query("INSERT INTO Recorded (channelID,start,ShowName) VALUES ('#{chan_id}', '#{date_time}', '#{show_info}')")
        end
      end
      #delete the entry from Recording
      dbh.query("DELETE FROM Recording WHERE (channelID = '#{chan_id}' AND start = '#{date_time}')")        
    end
    #See if there is an entry for programme
    if(presult == nil)
      puts "<error>Programme not in Programme</error>\n"
      have_errored = true
    else
      #if there is an entry, delete it
      if reced_result != nil:
        dbh.query("DELETE FROM Programme WHERE (channelID = '#{chan_id}' AND start = '#{date_time}')")
      end
    end  
  end
  if have_errored == false:
    puts "<success>Programme Deleted</success>"
  end
#closing down cgi
cgi.shutdown()

#call record.rb
  exec("ruby record.rb")
