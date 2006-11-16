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


require 'xml/libxml'
require 'date'

LENGTH_OF_TIME = 6
LENGTH_OF_DATE_TIME = 14

#Functions-------------------------------------------------------------------------------
#make sure file available in current directory
def file_available(file_name)
  cur_dir_entries=Dir.entries(Dir.getwd)
  return cur_dir_entries.include?(file_name)
end

#formate_date formates a date time object and converts it to a string
# formated YYYYMMDD
def format_date(current_date)
  month = current_date.month.to_s
  day = current_date.day.to_s
  
  #pads month
  if (current_date.month.to_s.length != 2):
    month = "0"+ current_date.month.to_s
  else
    month = current_date.month.to_s
  end
  
  #pads day
  if (current_date.day.to_s.length != 2):
    day = "0" + current_date.day.to_s
  else
    day = current_date.day.to_s
  end
  return current_date.year.to_s + month + day
end

#Turns string formatted YYYYMMDD to date time object
def unformat_date(formatted_date)
  return DateTime.new(formatted_date[0..3].to_i, formatted_date[4..5].to_i, formatted_date[6..7].to_i)
end

#Error handler
def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts("Error " + error_string)
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
puts( "Starting " + DateTime.now.to_s)
#checking for three arguements
  error_if_not_equal(ARGV.length, 2, "Needs two arguments")


#get arguments
  puts start_date_time = ARGV[0]
  puts end_date_time = ARGV[1]

#checks lengths of arguements to make sure the have the length of YYYYMMDDHHMMSS
  error_if_not_equal(start_date_time.length, LENGTH_OF_DATE_TIME, "incorrect length for start date")
  error_if_not_equal(end_date_time.length, LENGTH_OF_DATE_TIME, "incorrect length for end date")
  
  start_date = start_date_time[0..7]
  end_time = end_date_time[8..13]
  start_time = start_date_time[8..13]
  end_date = end_date_time[0..7]

#error checking
  #Check if date stamp valid
  error_if_not_equal(start_date_time.to_i < end_date_time.to_i, true, "Start time must be before end time")

  #Check if times are valid
  error_if_not_equal(start_time.to_i < 240000, true, "Start time must be millitary time")
  error_if_not_equal(end_time.to_i < 240000, true, "End time must be millitary time") 
  error_if_not_equal(start_time[2..3].to_i < 60 , true, "Start minutes must be less than 60")
  error_if_not_equal(end_time[2..3].to_i < 60, true, "End minutes must be less than 60")
  
  #Check if dates are valid
  error_if_not_equal(start_date[4..5].to_i <= 12 , true, "Starting month must be less than or equal to 12")
  error_if_not_equal(end_date[4..5].to_i <= 12 , true, "Ending month must be less than or equal to 12")
  error_if_not_equal(start_date[6..7].to_i <= 31, true, "Starting day must be less than 31")
  
  error_if_not_equal(end_date[6..7].to_i <= 31, true, "Ending day must be less than 31")
  
  #Get output the information into output
  puts "Parsing"
  xml = XML::Document.file("info.xml")
  to_client_xml = XML::Document.new()

  start = start_date_time.to_i
  stop = end_date_time.to_i

  first_time = true
  newest_e = 0

  output = "la" #puts get_header(xml)
  
  xml.find("programme").each do |e|
    #get element start and end time
    puts e_start = e['start'][0..13].to_i
    puts e_end = e['stop'][0..13].to_i
    
    #get newest element
    if e_end > newest_e:
      newest_e = e_end 
    end

    if e_start < e_end:
      begins_before = e_end > start && e_end <= stop && e_start <= stop && e_start < start
      ends_after = e_start >= start && e_end > stop && e_start < stop
      occurs_during = e_start >= start && e_end <= stop
      occurs_around = (e_start <= start && e_end >= stop)
      
      if begins_before || ends_after || occurs_during || occurs_around:
        STDOUT << "*"
        output << e.to_s
      end
    else
      error_if_not_equal(false, true, "Have to deal with later")
    end
  end
  
  error_if_not_equal(stop <= newest_e, true, "Ran off end of info.xml")

  output.close()    
  
  puts( "Done writing shows " + DateTime.now.to_s)



