require 'rexml/document'
require 'date'
include REXML

LENGTH_OF_TIME = 6
LENGTH_OF_DATE_TIME = 14

#Functions-------------------------------------------------------------------------------
#make sure file available in current directory
def file_available(file_name)
  cur_dir_entries=Dir.entries(Dir.getwd)
  return cur_dir_entries.include?(file_name)
end

def format_date(current_date)
  puts "formatted"
  month = current_date.month.to_s
  day = current_date.day.to_s
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
  return current_date.year.to_s + month + day
end

def unformat_date(formatted_date)
  return DateTime.new(formatted_date[0..3].to_i, formatted_date[4..5].to_i, formatted_date[6..7].to_i)

end
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
def shows(xml, start_time, end_time)
  output = File.open("out.xml","a+")
  puts start = start_time.to_i
  puts stop = end_time.to_i
  puts "pre-filter"
  
  xml.root.elements.each('child::node()') do |e|
  #xml.root.each_child do |e|
    #if start time is between start and end time
    e_start = e.attributes['start'][8..15].to_i
    
    e_end = e.attributes['stop'][8..15].to_i
    if e_start < e_end
      begins_before = e_end > start && e_end <= stop && e_start <= stop && e_start < start
      ends_after = e_start >= start && e_end > stop && e_start < stop
      occurs_during = e_start >= start && e_end <= stop
      occurs_around = (e_start <= start && e_end >= stop)
      
      if begins_before || ends_after || occurs_during || occurs_around:
        STDOUT << "*"
        output << e.to_s
        output << "\n"
      end
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
  File.delete("out.xml")
  cur_date = start_date
  
  difference = unformat_date(end_date)-unformat_date(cur_date)
  puts difference.to_i
  
  inter_start_time = start_time
  inter_end_time = end_time

  while difference.to_i >= 0 :
    error_if_not_equal(file_available(cur_date+".xml"), true, cur_date + " is not available")
    if cur_date == start_date && cur_date == end_date && start_date == end_date:
      puts "first case"
    elsif cur_date == start_date:
      puts "second case"
      inter_start_time = start_time
      inter_end_time = "235900"
    elsif cur_date != start_date && cur_date != end_date:
      puts "neither beg or end"
      inter_start_time = "000000"
      inter_end_time = "235900"
    elsif cur_date == end_date:
      puts "last case"
      inter_start_time = "000000"
      inter_end_time = end_time
    end
    puts "parsing"
    puts DateTime.now.to_s
    xml = REXML::Document.new(File.open(cur_date + ".xml"))
    puts( "Done Parsing " + DateTime.now.to_s)
    shows(xml, inter_start_time, inter_end_time)
    puts( "Done writing shows " + DateTime.now.to_s)
    
    puts cur_date=format_date(unformat_date(cur_date)+1)
    difference=unformat_date(end_date)-unformat_date(cur_date)
    puts difference.to_i
  end


