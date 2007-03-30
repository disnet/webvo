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
#form_search_results.rb
#This takes a search string and search in parameters and searches the listings 
#for the information

#get some libraries
require 'cgi'
require 'xml/libxml'  #allows for parsing the info.xml
require 'date'        #allows for finding the current date
#require "mysql"       #allows for communication with the mysql database

#constants
SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVoFast"
TABLENAME = "Recording"

PROG_ID = "prog_id"
LENGTH_OF_DATE_TIME = 14
XML_FILE_NAME = "info.xml"
SHOW_DIR = "/home/public_html/webvo/movies"



#-------------------------------------------------------------------------------
#Functions
#error handler, changes errors into valid xml
def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts "<error>Error " + error_string +"</error>"
    puts "\n</tv>" 
    STDOUT.close
    STDIN.close
    STDERR.close
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
  xmlNode.gsub!("&", "&#38;")
  return xmlNode
end

#checks to see if the file is there
def file_available(file_name)
  cur_dir_entries=Dir.entries(Dir.getwd)
  return cur_dir_entries.include?(file_name)
end

#Search in show title
def search_show_title( show_title )
  #get programme from info.xml
  error_if_not_equal(file_available(XML_FILE_NAME), true, "Source .xml file not in directory")
  xml = XML::Document.file(XML_FILE_NAME)

  #These all filled with ' ' just incase they are not filled below
  start = ' '
  stop = ' '
  xmlNode = "<Error>No items match your search.</Error>"
  title = ' '
  desc = ' '
  phrase = ' '
  attribute = ' '
  channelID = ' '
  found_match = false
  
  #getting information to put in xmlNode
  #reforming node to look like
  xml.find("programme").each do |e|
    #see if node has information
      puts "*"
      c = e.child    #get first child of programme
      keep_looping = true #varible to do a do-while
      matching_title = false # flag to see if the comparison is true
      got_title = false # flag if the title has been found
      #checking the title
      while keep_looping == true && got_title == false:
        if c.name == "title":
	  #comparison here********************************************
          if (c.content.to_s.upcase.include? show_title.to_s.upcase):
            matching_title = true
            puts c.content
          end
          got_title = true
        end  
        #if c.name == "desc":
        #  desc = c.content
        #end 
        if c.next?:
            c = c.next
        else
          keep_looping = false
        end
      end

      #if it does
      if matching_title == true:

        #get start
        start = e["start"][0..LENGTH_OF_DATE_TIME-1]
        #get stop        
        stop = e["stop"][0..LENGTH_OF_DATE_TIME-1]
        #get channel id
        channelID = e["channel"]
        c = e.child    #get first child of programme
        keep_looping = true #varible to do a do-while
        got_title = false # flag if the title has been found
        #getting child information
        while keep_looping == true: #&& got_title == false):
          #get title
	  if c.name == "title":
	    title = c.content
            got_title = true
          end  
          #get description
          if c.name == "desc":
            desc = c.content
          end 
          if c.next?:
              c = c.next
          else
            keep_looping = false
          end
        end
        
        xmlNode = form_node(start, stop, title, look_up_channel( channelID ), channelID, desc)
        puts xmlNode
        found_match = true
      end #matching title
      #if not move to next element
    end #end of each element
    # if none found
    if found_match == false:
       error_if_not_equal( true, false, "Sorry, no programmes match your search")
    end
end

#Search in show name
def search_show_subtitle( subtitle )
    #get programme from info.xml
  error_if_not_equal(file_available(XML_FILE_NAME), true, "Source .xml file not in directory")
  xml = XML::Document.file(XML_FILE_NAME)

  #These all filled with ' ' just incase they are not filled below
  start = ' '
  stop = ' '
  xmlNode = "<Error>No items match your search.</Error>"
  subtitle = ' '
  desc = ' '
  phrase = ' '
  attribute = ' '
  channelID = ' '
  found_match = false
  
  #getting information to put in xmlNode
  #reforming node to look like
  xml.find("programme").each do |e|
    #see if node has information
      c = e.child    #get first child of programme
      keep_looping = true #varible to do a do-while
      matching_subtitle = false # flag to see if the comparison is true
      got_subtitle = false # flag if the title has been found
      #checking the title
      while keep_looping == true && got_subtitle == false:
        if c.name == "sub-title":
	  #comparison here********************************************
          if (c.content.to_s.upcase.include? subtitle.to_s.upcase):
            matching_subtitle = true
          end
          got_subtitle = true
        end  
        #if c.name == "desc":
        #  desc = c.content
        #end 
        if c.next?:
            c = c.next
        else
          keep_looping = false
        end
      end

      #if it does
      if matching_subtitle == true:

        #get start
        start = e["start"][0..LENGTH_OF_DATE_TIME-1]
        #get stop        
        stop = e["stop"][0..LENGTH_OF_DATE_TIME-1]
        #get channel id
        channelID = e["channel"]
        c = e.child    #get first child of programme
        keep_looping = true #varible to do a do-while
        got_title = false # flag if the title has been found
        #getting child information
        while keep_looping == true: # && got_title == false):
          #get title
	  if c.name == "title":
	    title = c.content
            got_title = true
          end  
          #get description
          if c.name == "desc":
            desc = c.content
          end 
          if c.next?:
              c = c.next
          else
            keep_looping = false
          end
        end
        
        xmlNode = form_node(start, stop, title, look_up_channel( channelID ), channelID, desc)
        puts xmlNode
        found_match = true
      end #matching title
      #if not move to next element
    end #end of each element
    # if none found
    if found_match == false:
       error_if_not_equal( true, false, "Sorry, no programmes match your search")
    end
end

#Search in description
def search_description( description )
end

#look up channel
def look_up_channel( chan_id )
 #look up channel number
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
    channel_info = dbh.query("SELECT number FROM Channel WHERE channelID ='#{chan_id}' LIMIT 1")
    channel_num = channel_info.fetch_row
    if channel_num == nil:
      dbh.close()
      error_if_not_equal(true, false, "channel not found, please contact system administrator")
    end
    dbh.close()
  end
  return channel_num
end
#main--------------------------------------------------------------------------
  puts "Content-Type: text/xml\n\n" 
  cgi = CGI.new     # The CGI object is how we get the arguments 
  #manually return header and parent beginning
  puts "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<!DOCTYPE tv SYSTEM \"xmltv.dtd\">\n<tv source-info-url=\"http://labs.zap2it.com/\" source-info-name=\"TMS Data Direct Service\" generator-info-name=\"XMLTV\" generator-info-url=\"http://www.xmltv.org/\">"

  if cgi.has_key?('search_string') && cgi.has_key?('title'):
    puts "Starting to execute find title"
    search_show_title(cgi.params['search_string'][0])
    puts "done executing find title"
  elsif cgi.has_key?('search_string') && cgi.has_key?('subtitle'):
    search_show_subtitle( cgi.params['search_string'][0] )
  end

  puts "\n</tv>" 

  STDOUT.close
  STDIN.close
  STDERR.close
