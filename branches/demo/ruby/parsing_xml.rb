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


#including the rexml which allows for xml parsing
require 'rexml/document'
require 'date'
include REXML

XML_FILE_NAME = "info.xml"

#Functions------------------------------------------------------------------------------
def format_date(current_date)
  puts "formatted"
  if (current_date.month.to_s.length != 2):
    month = "0"+current_date.month.to_s
  else
    month = current_date.month.to_s
  end
  
  if (current_date.month.to_s.length != 2):
    day = "0" + current_date.day.to_s
  else
    day = current_date.day.to_s
  end
  return current_date.year.to_s + month + day
end

def unformat_date(formatted_date)
  #today = DateTime.now
  #day_len = today.to_s.length
  #return DateTime.new(formatted_date[0..day_len-5], formatted_date[day_len-4..day_len-3], formatted_date[day_len-2..day_len-1])
  return DateTime.new(formatted_date[0..3].to_i, formatted_date[4..5].to_i, formatted_date[6..7].to_i)

end

#sort_xml takes the parsed xml document and splits all the information up by date
  #with the date set has the hash value
  
def sort_xml(xml, xml_hash, today)
  #get all of the channel and program information
  first_time = true
  xml.root.elements.each('child::node()') do |e|
    if( e.name == "channel"):
      STDOUT << "."
      if( first_time == true):
        xml_hash["channel"] = xml.root.clone()
        xml_hash["channel"].add e
        puts "channel"
      else
        xml_hash["channel"].add e
      end
      first_time = false
    elsif( e.name == "programme"):
      STDOUT << "*"
      #sort out all the date information
      start_date = e.attributes['start'][0..7]
      end_date = e.attributes['stop'][0..7]
      if xml_hash.has_key?(start_date) :
        xml_hash[start_date].add e
      else
        xml_hash[start_date] = xml.root.clone()
        xml_hash[start_date].add e
      end
      
      if start_date != end_date:
        if xml_hash.has_key?(end_date) :
          xml_hash[end_date].add e
        else
          xml_hash[end_date] = xml.root.clone()
          xml_hash[end_date].add e
        end
      end
    end
  end
  
  return xml_hash

end

def write_xml(xml_hash, header)
  
  xml_hash.each_key do |k|
    #file name based off of key which is the applicable date
    file_name = k.to_s + ".xml"
    puts file_name
    output = File.open(file_name,"w+")
    
    #adding header information
    #putting in correct day information
    output << header
    output<< xml_hash[k].to_s
    output.close()
  end
  return true
end

def get_header(xml)
  output_string ="<?xml version=\"" + xml.version.to_s 
  output_string << "\" encoding=\"" 
  output_string << xml.encoding.to_s + "\"?>" + "\n"
  output_string << xml.doctype.to_s + "\n\n"
  return output_string
end


def clean_up_old_xml(today)
  Dir.foreach(Dir.getwd) do |entry|
  
  #pealing off extension
  
    file_name_without_ext = entry.split('.')[0]
    
    if file_name_without_ext != nil && file_name_without_ext.length == 8:
      xml_date = unformat_date(file_name_without_ext)
      difference = (xml_date-(today-3)).to_i
      
      if difference.to_i < 0:
        puts "deleting: " + entry
        File.delete(entry)
      end
    end
  end
  return true
end
#Main------------------------------------------------------------------------------------
#Witty thing to see while the document is being parsed
puts "Yes, it is parsing. It may be going slow but it is parsing its little heart out."
puts "Proverbs 19:11: A man's wisdom gives him patience;"
puts "    it is to his glory to overlook an offense."
puts "Proverbs 25:15: Through patience a ruler can be persuaded,"
puts "    and a gentle tongue can break a bone."
puts "Romans 2:4: Or do you show contempt for the riches of his kindness, "
puts "    tolerance and patience, not realizing that God's kindness "
puts "    leads you toward repentance?"

#parse the document
puts DateTime.now
xml = REXML::Document.new(File.open(XML_FILE_NAME))

puts "parsed it!"
puts DateTime.now
xml_hash = Hash.new(0)

#get current day
today = DateTime.now

puts "sorting hash"
puts DateTime.now

#sort the xml file
xml_hash = sort_xml(xml, xml_hash,format_date(today))

puts "writing hash"
puts DateTime.now
# write the hash to the file
write_xml(xml_hash, get_header(xml))
puts "wrote out new files"
puts DateTime.now

#Deletes old .xml files that are 2 days old or older
puts "Deleting old files"
clean_up_old_xml(today)
puts DateTime.now
 







