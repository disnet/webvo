#!/usr/bin/env ruby
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
#form_recorded.rb
#returns a list of recorded (or partially recorded) shows

require 'date'
require "mysql"
require 'util'
require 'xml/libxml'

#this is only need for the trnasition to json
require 'cgi'
cgi = CGI.new
format = cgi.params['format'][0]
json = cgi.params['json'][0]

#todo: make this work when the movies dir is not visible from the web?
SHOW_RELATIVE_ADDRESS = "movies/"

#this file needs some upkeep, perhaps we need to send the "path" back differently?
def add_size_path_to_xml_Node(size,related_files,fragNum, xmlNode)
  nodePart = "\t<size>" + size.to_s + "</size>\n"
  #nodePart << "\t<path>" + related_files.to_s.gsub(/&/,'&amp;') + "</path>\n"
  related_files.each { |file| nodePart << "\t<path>" + SHOW_RELATIVE_ADDRESS + file.gsub(/&/,'&amp;') + "</path>" }
  nodePart << "\t<fragNum>" + fragNum.to_s + "</fragNum>\n"
  nodePart << "</programme>"
  xmlNode.gsub!("</programme>", nodePart)
end

#main ------------------------------------------------------------------------------------
#look up information in directory where recorded shows are being saved

#for each check against record.rb's pattern
f_size = 0
Dir.chdir(VIDEO_PATH)
file_list = Dir["**/*"]
json_out = JSON_Output.new(JSON_Output::RECORDED)
retstr = ""
# changing the order will break error xml formatting
databasequery("SELECT filename, p.xmlNode, number
              FROM Recorded JOIN Programme p USING (channelID, start) 
              JOIN Channel USING(channelID)
              ORDER BY start").each_hash { |recorded|
    #file may be there but need to compare with title in programme
    show_name = recorded["filename"]
    xmlNode = recorded["xmlNode"]

    file_size = 0
    files_with_name = file_list.grep(/#{Regexp.escape(show_name)}/)
    files_with_name.each { |file|
        file_size += File.size(file)
    }
    if format == "new" or json == "true"
        prog = Prog.new(XML::Parser.string(recorded['xmlNode'].to_s).parse, recorded['number'], file_size)
        prog.set_json_output
        json_out.add_programme(prog)
    else
        retstr += add_size_path_to_xml_Node(file_size.to_i, 
                                   files_with_name,
                                   files_with_name.length/2, 
                                   xmlNode) if files_with_name.length > 0
    end
}

if format == "new" or json == "true"
    puts JSON_HEADER
    puts json_out
else
    puts XML_HEADER
    puts retstr
    puts XML_FOOTER
end
