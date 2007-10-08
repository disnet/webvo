#!/usr/bin/env ruby

require 'cgi'
require 'util'
require 'xml/libxml'

cgi = CGI.new

search_title = cgi.params['title'][0]
sub_title = cgi.params['sub_title'][0]
format = cgi.params['format'][0]
json = cgi.params['json'][0]

query = "SELECT DISTINCT p.xmlNode, number
         FROM Programme p JOIN Channel USING(channelID)
         WHERE stop >= #{PaddedTime.strstop}"
query += " AND ( title LIKE '#{Mysql.escape_string(search_title)}%'" unless search_title.nil?
query += " OR title LIKE 'the #{Mysql.escape_string(search_title)}%' )" unless search_title.nil?
#query += " AND `sub-title` LIKE '%#{sub_title}%'" unless sub_title.nil?

query += " ORDER BY episode"
query += " LIMIT 400"

# changing the order will break error xml formatting
result = databasequery(query)

if format == "new" or json == "true"
    puts JSON_HEADER
    json_out = JSON_Output.new(JSON_Output::SEARCH)
    result.each_hash {|hash|
        prog = Prog.new(XML::Parser.string(hash['xmlNode'].to_s).parse, hash['number'])
        prog.set_json_output
        json_out.add_programme(prog)
    }
    databasequery("SELECT xmlNode from Scheduled 
                  JOIN Programme USING (channelID, start)").each {|xml| 
        json_out.add_scheduled(Prog.new(XML::Parser.string(xml[0].to_s).parse, "0"))
    }
    databasequery("SELECT xmlNode from Recorded 
                  JOIN Programme USING (channelID, start)").each {|xml|
        json_out.add_scheduled(Prog.new(XML::Parser.string(xml[0].to_s).parse, "0"))
    }
    puts json_out

else
    puts XML_HEADER
    result.each {|show| puts show[0]}
    puts XML_FOOTER
end
