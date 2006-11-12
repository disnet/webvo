require 'xml/libxml'
require 'date'

XML_FILE_NAME = 'info.xml'

def format_date(current_date)
	if( current_date.month.to_s.length != 2 ):
		month = "0" + current_date.month.to_s
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
	return DateTime.new(formatted_date[0..3].to_i, formatted_date[4..5].to_i, formatted_date[6..7].to_i)
end

def sort_xml(xml,xml_hash,today)
	first_time = true
	xml.find('channel').each do |e|
	  
		if(first_time == true):
			xml_hash["channel"] = XML::Document.new()
			xml_hash["channel"].root = e
			first_time = false
		else
			xml_hash["channel"].root << e.copy(true)
		end
	end
	
    xml.find("programme").each do |e|
        #sort out all the date information
        start_date = e['start'][0..7]
        end_date = e['stop'][0..7]
        
        if xml_hash.has_key?(start_date) :
            xml_hash[start_date].root << e.copy(true)
        else
            xml_hash[start_date] = XML::Document.new()
            xml_hash[start_date].root = e 
        end
        
        if start_date != end_date:
            if xml_hash.has_key?(end_date) :
                xml_hash[end_date].root << e.copy(true)
            else
                xml_hash[end_date] = XML::Document.new()
                xml_hash[end_date].root = e 
            end
        end
      end     
	
	return xml_hash
end

def write_xml(xml_hash)
	xml_hash.each_key do |k|
		file_name = k.to_s + ".xml"
		puts file_name
		xml_hash[k].save(file_name,false)
	end
	return true
end

def get_header(xml)
	output_string = "<?xml version=\"" + xml.version
	output_string << "\"encoding=\""
	output_string << xml.encoding + "\"?>" + "\n"
	output_string << xml.uri + "\n\n"
	return output_string
end

def clean_up_old_xml(today)
	Dir.foreach(Dir.getwd) do |entry|
		file_name_without_ext = entry.split('.')[0]

		if file_name_without_ext != nil && file_name_without_ext.length == 8:
			xml_date = unformat_date(file_name_without_ext)
			difference = (xml_date - (today-3)).to_i

			if difference.to_i < 0:
				puts "deleting: " + entry
				File.delete(entry)
			end
		end
	end
	return true
end

puts "Begining parsing..."
puts DateTime.now
puts "change"
xmldoc = XML::Document.file('info.xml')

puts "parsed it"
puts DateTime.now
xml_hash = Hash.new(0)

puts "Root el name: #{xmldoc.root.name}"

today = DateTime.now

puts "Sorting hash"
puts DateTime.now

xml_hash = sort_xml(xmldoc,xml_hash,format_date(today))

puts "Writing hash"
puts DateTime.now
write_xml(xml_hash)
puts "wrote out files"
puts DateTime.now
