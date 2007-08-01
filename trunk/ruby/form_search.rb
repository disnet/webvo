#!/usr/bin/env ruby

require 'cgi'
require 'util'

puts XML_HEADER

cgi = CGI.new

search_title = cgi.params['title'][0]
sub_title = cgi.params['sub_title'][0]

error_if_not_equal(cgi.params.size == 0, false, "No search terms entered")

query = "SELECT DISTINCT xmlNode
         FROM Programme
         WHERE stop >= #{PaddedTime.strstop}"
query += " AND ( title LIKE '#{Mysql.escape_string(search_title)}%'" unless search_title.nil?
query += " OR title LIKE 'the #{Mysql.escape_string(search_title)}%' )" unless search_title.nil?
#query += " AND `sub-title` LIKE '%#{sub_title}%'" unless sub_title.nil?

query += " LIMIT 400"

databasequery(query).each { |show| 
    puts show
}

puts XML_FOOTER
