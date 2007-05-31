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

SHOW_RELATIVE_ADDRESS = "movies/"

def add_size_path_to_xml_Node(size,path,fragNum, xmlNode)
  nodePart = "\t<size>" + size.to_s + "</size>\n"
  nodePart << "\t<path>" + path.to_s + "</path>\n"
  nodePart << "\t<fragNum>" + fragNum.to_s + "</fragNum>\n"
  nodePart << "</programme>"
  xmlNode.gsub!("</programme>", nodePart)
end

#main ------------------------------------------------------------------------------------
puts XML_HEADER

#look up information in directory where recorded shows are being saved

#for each check against record.rb's pattern
f_size = 0
file_list = Dir.new(VIDEO_PATH).entries
Dir.chdir(VIDEO_PATH)
rec_info = databasequery("SELECT filename, xmlNode FROM Recorded JOIN Programme USING (channelID, start) ORDER BY start")

#file may be there but need to compare with title in programme
rec_info.each_hash { |recorded|
    show_name = recorded["filename"]
    xmlNode = recorded["xmlNode"]

    #To support multiple encoding schemes, will list all of the files.
    SUPPORTED_ENCODING_SCHEMES.each do |type|
        if file_list.include?(show_name + "-0"+type) :

            f_size = File.size("#{show_name}-0#{type}")
            frag_num = 1
            while file_list.include?(show_name + "-" + frag_num.to_s + type) == true
                f_size = f_size + File.size("#{show_name}-#{frag_num.to_s}#{type}")
                frag_num = frag_num + 1
            end
            # need to check for characters other than "&" that mess up the xml, perhaps "<" and/or ">"
            puts add_size_path_to_xml_Node(f_size.to_i, 
                                           SHOW_RELATIVE_ADDRESS + "#{show_name.gsub(/&/,'&amp;')}-0"+type, 
                                           frag_num, 
                                           xmlNode)
        end
    end
}
puts XML_FOOTER
