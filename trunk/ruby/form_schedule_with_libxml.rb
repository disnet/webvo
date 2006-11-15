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
  output_string << xml.doctype.to_s + "\n\n"
  return output_string
end

def shows(xml, start_date_time, end_date_time)
  puts "got here"
  output = File.open("out.xml","a+")
  puts start = (start_date_time[8..9] + start_date_time[10..11] + start_date_time[12..15]).to_i
  puts start_date = start_date_time[0..3] + start_date_time[4..5] + start_date_time[6..7]
  end_time = (end_date_time[8..9] + end_date_time[10..11] + start_date_time[12..15]).to_i
  puts end_date = end_date_time[0..3] + end_date_time[4..5] + end_date_time[6..7]
  puts (unformat_date(end_date)-unformat_date(start_date)).to_i
  
  if start_date != end_date:
    puts stop = end_time + 240000*(unformat_date(end_date)-unformat_date(start_date)).to_i
  else
    stop = end_time
  end

  
  xml.find("programme").each do |e|
    #get element start and end time
    e_start_date = e['start'][0..7]
    e_end_date = e['stop'][0..7]
    
    next if e_start_date.to_i < start_date.to_i

    e_start = e['start'][8..15].to_i
    e_end = e['stop'][8..15].to_i
    
    if e_start_date != e_end_date:
      e_end = e_end + 240000*(unformat_date(e_end_date)-unformat_date(e_start_date)).to_i
    end 
    
    if e_start < e_end:
      begins_before = e_end > start && e_end <= stop && e_start <= stop && e_start < start
      ends_after = e_start >= start && e_end > stop && e_start < stop
      occurs_during = e_start >= start && e_end <= stop
      occurs_around = (e_start <= start && e_end >= stop)
      
      if begins_before || ends_after || occurs_during || occurs_around:
        STDOUT << "*"
        output << e.to_s
        output << "\n"
      end
    else
      error_if_not_equal(false, true, "Have to deal with later")
    end
  end
  output.close()
end

# Main-----------------------------------------------------------------------------------
#checking for three arguements
puts DateTime.now
error_if_not_equal(ARGV.length, 2, "Needs two arguments")


#get arguments
  puts start_date_time = ARGV[0]
  puts end_date_time = ARGV[1]

  error_if_not_equal(start_date_time.length, LENGTH_OF_DATE_TIME, "incorrect length for start date")
  error_if_not_equal(end_date_time.length, LENGTH_OF_DATE_TIME, "incorrect length for start date")
  
  puts start_time = start_date_time[8..9] + start_date_time[10..11] + start_date_time[12..15]
  puts start_date = start_date_time[0..3] + start_date_time[4..5] + start_date_time[6..7]
  puts end_time = end_date_time[8..9] + end_date_time[10..11] + start_date_time[12..15]
  puts end_date = end_date_time[0..3] + end_date_time[4..5] + end_date_time[6..7]
#error checking
  #check format of start_date
  today = DateTime.now
  
  formatted_today = format_date(today)
  
  
  #check format of start_time
  error_if_not_equal(start_time.length, LENGTH_OF_TIME, "incorrect length for start time")
  
  #check format of end_time
  error_if_not_equal(end_time.length, LENGTH_OF_TIME, "incorrect length for end time")
  
  #see if start_date is available
  error_if_not_equal(file_available(start_date+".xml"), true, "start date is not available")
  error_if_not_equal(file_available("channel"+".xml"), true, "channel is not avaiable")
  
  #Get output the information into output
  #File.delete("out.xml")

    puts "parsing"
    puts DateTime.now.to_s
    xml = XML::Document.file("info.xml")
    puts( "Done Parsing " + DateTime.now.to_s)
    shows(xml, start_date_time, end_date_time)
    puts( "Done writing shows " + DateTime.now.to_s)



