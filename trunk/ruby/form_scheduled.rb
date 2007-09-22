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
#form_scheduled.rb
#sends scheduled information to client

require "mysql"
require 'util'
require 'xml/libxml'

#this is only need for the trnasition to json
require 'cgi'
cgi = CGI.new
format = cgi.params['format'][0]
json = cgi.params['json'][0]


# changing the order will break error xml formatting
result = databasequery("SELECT p.xmlNode, number from Programme p JOIN Scheduled USING(channelID, start) JOIN Channel USING(channelID) ORDER BY start")

if format == "new" or json == "true"
    puts JSON_HEADER
    json_out = JSON_Output.new(JSON_Output::SCHEDULED)
    result.each_hash {|hash|
        prog = Prog.new(XML::Parser.string(hash['xmlNode'].to_s).parse, hash['number'])
        prog.set_json_output
        json_out.add_programme(prog)
    }
    puts json_out

else
    puts XML_HEADER
    result.each {|show| puts show[0]}
    puts XML_FOOTER
end
