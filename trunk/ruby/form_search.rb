#!/usr/bin/env ruby

require 'cgi'
require 'util'
require 'xml/libxml'

cgi = CGI.new

search_title = cgi.params['title'][0]
sub_title = cgi.params['sub_title'][0]
format = cgi.params['format'][0]

query = "SELECT DISTINCT xmlNode
         FROM Programme
         WHERE stop >= #{PaddedTime.strstop}"
query += " AND ( title LIKE '#{Mysql.escape_string(search_title)}%'" unless search_title.nil?
query += " OR title LIKE 'the #{Mysql.escape_string(search_title)}%' )" unless search_title.nil?
#query += " AND `sub-title` LIKE '%#{sub_title}%'" unless sub_title.nil?

query += " LIMIT 20"

result = databasequery(query)

if format == "new"
    puts JSON_HEADER
    json_out = JSON_Output.new(JSON_Output::SEARCH)
    result.each {|showxml|
        prog = Prog.new(XML::Parser.string(showxml.to_s).parse)
        prog.set_json_output
        json_out.add_programme(prog)
    }
    puts json_out

else
    puts XML_HEADER
    result.each {|showxml| puts showxml}
    puts XML_FOOTER
end
