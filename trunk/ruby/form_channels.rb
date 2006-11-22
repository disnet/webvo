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


require 'cgi'
require 'xml/libxml'
require 'date'

XML_FILE_NAME = 'info.xml'
def file_available(file_name)
  cur_dir_entries=Dir.entries(Dir.getwd)
  return cur_dir_entries.include?(file_name)
end


def get_header(xml)
  output_string = "<?xml version=\"" + xml.version
  output_string << "\"encoding=\""
  output_string << xml.encoding + "\"?>" + "\n"
  output_string << xml.uri + "\n\n"
  return output_string
end
#Main ------------------------------------------------------------------------
puts "Content-Type:text/xml\n\n"

#parse xmldoc
if file_available("channels.xml") == true:
  channel_xml = File.open("channels.xml", "r")
  channel_xml.each_line{|line| puts line}
else
  if file_available(XML_FILE_NAME) == false
    puts "<error> Error " + XML_FILE_NAME + "not in directory</error>"
    exit
  end

  xmldoc = XML::Document.file(XML_FILE_NAME)

  #manually return header and parent beginning
    puts "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<!DOCTYPE tv SYSTEM \"xmltv.dtd\">\n<tv source-info-url=\"http://labs.zap2it.com/\" source-info-name=\"TMS Data Direct Service\" generator-info-name=\"XMLTV\" generator-info-url=\"http://www.xmltv.org/\">"

  #get channel and send it up to go to client
    xmldoc.find('channel').each do |e|	  
      puts e.to_s # print out the channel
    end

  #get first and last programme date
    newest_day = 000000000000
    oldest_day = 999999999999
    xmldoc.find('programme').each do |e|
      if (e["start"][0..7].to_i > newest_day)
	newest_day = e["start"][0..7].to_i
      end
      if(e["stop"][0..7].to_i < oldest_day)
	oldest_day = e["stop"][0..7].to_i
      end
    end
    puts "\n<programme_date_range start='"+ oldest_day.to_s + "' stop='" + newest_day.to_s + "'></programme_date_range>\n"

  #write up end of parent
    puts "</tv>" 
end

