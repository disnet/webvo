#!/usr/bin/env ruby

#Delete the recording from the hard drive

require "cgi"
require "util"

cgi = CGI.new

json = cgi.params['json'][0].to_s.downcase == "true"
prog_id = cgi.params['prog_id'][0]

puts "Content-Type:text/xml\n\n<?xml version='1.0' encoding='ISO-8859-1'?>\n<tv>" unless json
puts JSON_HEADER if json

error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Need a Channel ID")
date_time = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
date_time = formatToRuby(date_time+Time.now.strftime(" %z")).strftime(DATE_TIME_FORMAT_RUBY_XML) unless json
chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME-1).to_i]

progxml = databasequery("SELECT filename, xmlNode FROM Recorded JOIN Programme USING(channelID, start) WHERE (channelID='#{chan_id}'AND start = '#{date_time}')").fetch_row
error_if_not_equal( progxml.nil?, false, "Show does not exist")
showname = progxml[0]

#remove from hard drive
Dir[VIDEO_PATH+"**/*"].grep(/#{Regexp.escape(showname)}/).each {|file| File.delete file}

databasequery("DELETE FROM Scheduled WHERE (channelID = '#{chan_id}'AND start = '#{date_time}')")
databasequery("DELETE FROM Recorded WHERE (channelID = '#{chan_id}'AND start = '#{date_time}')")

if json
    json_out = JSON_Output.new(JSON_Output::DELETE)
    prog = Prog.new(XML::Parser.string(progxml[1].to_s).parse, 0)
    prog.set_json_output
    json_out.add_programme(prog)
    puts json_out
else
    puts "<success>Removed #{showname.gsub(/_/," ")} from hard drive</success>"
    puts XML_FOOTER
end
