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

#!/usr/local/bin/ruby
require 'cgi'
require 'xml/libxml'
require 'date'

LENGTH_OF_TIME = 6
LENGTH_OF_DATE_TIME = 14
START = "start_date_time"
STOP = "end_date_time"
XML_FILE_NAME = 'info.xml'

#Functions-------------------------------------------------------------------------------
#make sure file available in current directory
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


def get_header(xml)
  output_string ="<?xml version=\"" + xml.version.to_s 
  output_string << "\" encoding=\"" 
  output_string << xml.encoding.to_s + "\"?>" + "\n"
  return output_string
end

# Main-----------------------------------------------------------------------------------


  puts "Content-Type: text/xml\n\n" 
  
  cgi = CGI.new                      # The CGI object is how we get the arguments 
  
#checks for 2 arguments
  error_if_not_equal(cgi.keys.length, 2, "Needs two arguments")

  error_if_not_equal(cgi.has_key?(START), true, "Need start date time")
  error_if_not_equal(cgi.has_key?(STOP), true, "Need end date time")
#get arguments
  start_date_time = cgi[START]
  end_date_time = cgi[STOP]

#checks lengths of arguments to make sure the have the length of YYYYMMDDHHMMSS
  error_if_not_equal(start_date_time.length, LENGTH_OF_DATE_TIME, "incorrect len for start date")
  error_if_not_equal(end_date_time.length, LENGTH_OF_DATE_TIME, "incorrect len for end date")
  
  start_date = start_date_time[0][0..7]

  end_time = end_date_time[0][8..13]
  start_time = start_date_time[0][8..13]
  end_date = end_date_time[0][0..7]

#error checking
  #Check if date stamp valid
  error_if_not_equal(start_date_time.to_i < end_date_time.to_i, true, "Start time must be before end time")

  #Check if times are valid
  error_if_not_equal(start_time.to_i < 240000, true, "Start time must be millitary time")
  error_if_not_equal(end_time.to_i < 240000, true, "End time must be millitary time") 
  error_if_not_equal(start_time[2..3].to_i < 60 , true, "Start minutes must be less than 60")
  error_if_not_equal(end_time[2..3].to_i < 60, true, "End minutes must be less than 60")
  
  #Check if dates are valid
  error_if_not_equal(start_date[4..5].to_i <= 12 , true, "Starting month must be <= to 12")
  error_if_not_equal(end_date[4..5].to_i <= 12 , true, "Ending month error < 12")
  error_if_not_equal(start_date[6..7].to_i <= 31, true, "Starting month error < 31") 
  error_if_not_equal(end_date[6..7].to_i <= 31, true, "Ending day must be less than 31")
  
  #Get output the information into output
  xml = XML::Document.file(XML_FILE_NAME)

  start = start_date_time.to_i
  stop = end_date_time.to_i

  first_time = true
  newest_e = 0
  oldest_e = 999999999999999
  
  puts "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<!DOCTYPE tv SYSTEM \"xmltv.dtd\">\n<tv source-info-url=\"http://labs.zap2it.com/\" source-info-name=\"TMS Data Direct Service\" generator-info-name=\"XMLTV\" generator-info-url=\"http://www.xmltv.org/\">"
  
  #go through file and get files within requested range 
  xml.find("programme").each do |e|
    #get element start and end time
    e_start = e['start'][0..13].to_i
    e_end = e['stop'][0..13].to_i
    
    #calculations for seeing if requesting unavailable timeframe
      #get newest element
    if e_end > newest_e:
      newest_e = e_end 
    end
    
      #get oldest element
    if e_start < oldest_e:
      oldest_e = e_start
    end

    if e_start <= e_end:
      #possible locations of programmes
      begins_before = e_end > start && e_end <= stop && e_start <= stop && e_start < start
      ends_after = e_start >= start && e_end > stop && e_start < stop
      occurs_during = e_start >= start && e_end <= stop
      occurs_around = (e_start <= start && e_end >= stop)
      
      if begins_before || ends_after || occurs_during || occurs_around:
        puts e.to_s
      end
    else
      error_if_not_equal(false, true, "Invaild xml data")
    end
  end
  puts "</tv>"
  
#checking to see if the user requested an unavailable timeframe
  error_if_not_equal(start >= oldest_e, true, "Ran off begining of info.xml")
  error_if_not_equal(stop <= newest_e, true, "Ran off end of info.xml")
