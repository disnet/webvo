#parsing_xml.xml
#Molly Jo Bault

#including the rexml which allows for xml parsing
require 'rexml/document'
require 'date'
include REXML

XML_FILE_NAME = "info.xml"

#Functions------------------------------------------------------------------------------
def format_date(current_date)
  puts "formatted"
  return current_date.year.to_s + current_date.month.to_s + current_date.day.to_s
end
#sort_xml takes the parsed xml document and splits all the information up by date
  #with the date set has the hash value
  
def sort_xml(xml, xml_hash, today)
  #get all of the channel information
  first_time = true
  puts "pulling out channel information"
  xml.elements.each("//tv/channel") do |e|
    if( first_time == true):
      
      xml_hash["channel"] = xml.root.clone()
      xml_hash["channel"].add e
      puts "channel"
    else
      xml_hash["channel"].add e
    end
    first_time = false
  end

  #sort out all the date information
  puts "pulling out program information"
  xml.elements.each("//tv/programme") do |e|
    start_date = e.attributes['start'][0..today.length-1]
    end_date = e.attributes['stop'][0..today.length-1]
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
  output_string << xml.doctype.to_s + "\n"
  return output_string
end


def clean_up_old_xml(today)
  cur_dir_entries = Dir.entries(Dir.getwd)
  
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
#puts DateTime.now
xml = REXML::Document.new(File.open(XML_FILE_NAME))

#puts "parsed it!"
#puts DateTime.now
xml_hash = Hash.new(0)

#get current day
today = DateTime.now

#puts "sorting hash"
#puts DateTime.now

#sort the xml file
xml_hash = sort_xml(xml, xml_hash,format_date(today))

#puts "writing hash"
#puts DateTime.now
# write the hash to the file
write_xml(xml_hash, get_header(xml))
#puts DateTime.now






