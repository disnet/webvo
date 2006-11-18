#!/usr/local/bin/ruby
require 'cgi'
require 'xml/libxml'
require 'date'

puts "Content-Type:text/xml\n\n"

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
                  # It is always needed to help the browser decide what to do with the document
                  # It is a header and never seen in the output

#parse xmldoc
if file_available(XML_FILE_NAME) == false
  puts "<error> Error " + XML_FILE_NAME + "not in directory</error>"
  exit
end

xmldoc = XML::Document.file(XML_FILE_NAME)

#manually return header and parent beginning
  puts "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<!DOCTYPE tv SYSTEM \"xmltv.dtd\">\n<tv source-info-url=\"http://labs.zap2it.com/\" source-info-name=\"TMS Data Direct Service\" generator-info-name=\"XMLTV\" generator-info-url=\"http://www.xmltv.org/\">"

#get channel and set it up to go to client
  first_time = true
  xmldoc.find('channel').each do |e|	  
    puts e.to_s # print out the channel
  end
 
 #write up end of parent
  puts "</tv>" 

