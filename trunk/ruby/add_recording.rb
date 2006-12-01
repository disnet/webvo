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
#takes a programmeid from the front end and adds it to the database

#get some libraries
require 'cgi'         #allows for communication with the front end
require 'xml/libxml'  #allows for parsing the info.xml
require 'date'        #allows for finding the current date
require "mysql"       #allows for communication with the mysql database

#constants
SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVo"
TABLENAME = "Recording"

PROG_ID = "prog_id"
LENGTH_OF_DATE_TIME = 14
XML_FILE_NAME = "info.xml"
SHOW_DIR = "/home/daryl/Desktop/TestVideos/"

#Functions-----------------------------------------------------------------------
#checks to see if the file is there
def file_available(file_name)
  cur_dir_entries=Dir.entries(Dir.getwd)
  return cur_dir_entries.include?(file_name)
end

#error handler, changes errors into valid xml
def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts "<error>Error " + error_string +"</error>"
    exit
  end
end

#takes in information and forms it into a xmlNode for more information
def form_node(start, stop, title, channel, channelID, desc)
  xmlNode = "<programme>\n"
  xmlNode << "\t<title>#{title}</title>\n"
  xmlNode << "\t<desc>#{desc}</desc>\n"
  xmlNode << "\t<start>" + start.to_s + "</start>\n"
  xmlNode << "\t<stop>" + stop.to_s + "</stop>\n"
  xmlNode << "\t<channel>" + channel.to_s + "</channel>\n"
  xmlNode << "\t<channelID>" + channelID.to_s + "</channelID>\n"
  xmlNode << "</programme>\n"
  return xmlNode
end

#this function finds the available free space on the hard drive to determine
def freespace()
  #runs UNIX free space command
  readme = IO.popen("df --type ext3")
  sleep (0.5)
  
  #gets information from the 
  header = readme.gets
  header_arr = Array.new
  header_arr = header.scan(/\w+/)
  values = readme.gets
  values_arr = Array.new
  values_arr = values.scan(/\w+/)
  if(header_arr.length == values_arr.length)
    if(values_arr[header_arr.index("Available")].to_i > (50*10000)):
      return true
    else
      return false
    end
  end
  readme.close()
  return true
end

#this this takes the date and turns it into YYYYMMDDHHMMSS 
def format_date(current_date)
  #if elses for padding the numbers
  if (current_date.month.to_s.length != 2):
    month = "0"+ current_date.month.to_s
  else
    month = current_date.month.to_s
  end

  if (current_date.day.to_s.length != 2):
    day = "0" + current_date.day.to_s
  else
    day = current_date.day.to_s
  end

  if(current_date.hour.to_s.length !=2):
    hour = "0" + current_date.hour.to_s
  else
    hour = current_date.hour.to_s
  end

  if(current_date.min.to_s.length !=2):
    min = "0" + current_date.min.to_s
  else
    min = current_date.min.to_s
  end
  
  if(current_date.sec.to_s.length !=2):
    sec = "0" + current_date.sec.to_s
  else
    sec = current_date.sec.to_s
  end
  return current_date.year.to_s + month + day + hour + min + sec
end
#main--------------------------------------------------------------------------
  puts "Content-Type: text/xml\n\n" 
  
  cgi = CGI.new     # The CGI object is how we get the arguments 
  
#checks for 1 argument
  error_if_not_equal(cgi.keys.length(), 1, "Needs one argument")
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

#get programme from info.xml
  error_if_not_equal(file_available(XML_FILE_NAME), true, "Source .xml file not in directory")
  xml = XML::Document.file(XML_FILE_NAME)

  error_if_not_equal(freespace(), true, "not enough room on server")
  got_programme = true
  

#These all filled with ' ' just incase they are not filled below
  start = ' '
  stop = ' '
  xmlNode = ' '
  title = ' '
  desc = ' '
  
  #getting information to put in xmlNode
  #reforming node to look like
  xml.find("programme").each do |e|
    if (e["channel"] == chan_id && e["start"][0..(LENGTH_OF_DATE_TIME-1).to_i] == date_time):
      #get channel id, start time, stop time, title, and all xml information
      #channel id -> chan_id
      #start time -> start
      #stop time -> stop
      #title -> title
      
      error_if_not_equal(got_programme, true, "two or more programmes match that program ID")
      
      start = e["start"][0..LENGTH_OF_DATE_TIME-1]
      stop = e["stop"][0..LENGTH_OF_DATE_TIME-1]
      
      #make sure that stop is after current date time
      today = format_date(DateTime.now)
      itoday = today.to_i
      error_if_not_equal(itoday < stop.to_i, true, "today is #{today} and your requested show ends in the past at #{stop}")
      error_if_not_equal(e.child?, true, "programme to add doesn't have needed information")
      c = e.child
      
      keep_looping = true #varible to do a do-while
      
      #gets the title
      while keep_looping == true:
        if c.name == "title":
          title = c.content
          need_title = false
        end  
        if c.name == "desc":
          desc = c.content
        end
        #if there needs to be more things code will need to be added here
        if c.next?:
            c = c.next
        else
          keep_looping = false
        end
      end
      error_if_not_equal(need_title, false, "programme doesn't have a title")
      got_programme = false
    end
  end
  
  error_if_not_equal(got_programme, false, "requested show not in source listings") 
  
  #get the integer versions of start and stop to use to check if the programme
  #to be added is at the same time as a current show.
  istart = start.to_i
  istop = stop.to_i
  
  #connect to database
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
    #check and make sure that the programme isn't already there
    presults = dbh.query("SELECT * FROM Programme WHERE (channelID = '#{chan_id}' AND start = '#{start}')")
    rresults = dbh.query("SELECT * FROM Recording WHERE (channelID ='chan_id}' AND start = '#{start}')")
    
    if presults.fetch_row != nil:
      dbh.close()
      error_if_not_equal(false, true, "show already added")
    end
   
    #check to see if there is a programme during the same time.
    allpresults = dbh.query("SELECT start, stop, channelID, title FROM Programme ORDER BY start")
    
    #loop through the results and check if they are during the same time
    allpresults.each_hash do |row|
      qstart = row["start"].to_i
      qstop = row["stop"].to_i
      #possible locations of programmes
      begins_before = qstop > istart && qstop <= istop && qstart <= istop && qstart < istart
      ends_after = qstart >= istart && qstop > istop && qstart < istop
      occurs_during = qstart >= istart && qstop <= istop
      occurs_around = (qstart <= istart && qstop >= istop)
      
      #if programme to add is during a programme that is already in the database
      if begins_before || ends_after || occurs_during || occurs_around:
        schan_id = row["channelID"]
        #see if this programme is in recording, if so then error out
        show_in_recording = dbh.query("SELECT start FROM Recording WHERE (channelID ='#{schan_id}' AND start = '#{qstart.to_s}')")
        recording_res = show_in_recording.fetch_row
        if recording_res != nil:
          
          title_with_spaces = row["title"].gsub(/["_"]/," ")
          
          dbh.close()
          
          error_if_not_equal(true, false, "Requested show occurs during: " + title_with_spaces)
          
        end
        
      end
    end
    
    #look up channel number to include in xmlNode
    channel_info = dbh.query("SELECT number FROM Channel WHERE channelID ='#{chan_id}' LIMIT 1")
    channel_num = channel_info.fetch_row
    if channel_num == nil:
      dbh.close()
      error_if_not_equal(true, false, "channel from requested show not in database")
    end

    xmlNode = form_node(start, stop, title, channel_num, chan_id, desc).to_s
    #send information to programme's table 
      #change data a bit to get it not to error when put in the database
    xmlNode.gsub!(/["'"]/, "_*_")
    xmlNode.gsub!("&", "&#38;")
    title = title.gsub(/[" "]/,"_")
    dbh.query("INSERT INTO Programme (channelID, start, stop, title, xmlNode) VALUES ('#{chan_id}', '#{start}','#{stop}','#{title}','#{xmlNode}')")
    if rresults.fetch_row == nil:
      #send information to recording table
      dbh.query("INSERT INTO Recording (channelID, start) VALUES ('#{chan_id}', '#{start}')")
    end
    #close the database
    dbh.close()
  end
  puts "<success>#{prog_id}</success>"
  cgi.shutdown()
  #call record.rb
  executed_record = system("ruby record.rb &")
  
  log = File.open("add_recoringlog.txt","a")
  
  if executed_record == true:
    log << DateTime.now + " Called ruby record.rb"
  else
    log << DateTime.now + " Did not ruby record.rb"
  end
  
  log.close()