#!/usr/bin/env ruby

#Delete the recording from the hard drive

require "cgi"
require "util"

puts "Content-Type: text/xml\n\n"
puts "<?xml version='1.0' encoding='ISO-8859-1'?>"
puts "<tv>"

cgi = CGI.new
prog_id = cgi.params['prog_id'][0]

error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Need a Channel ID")
date_time = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME-1).to_i]

showname = databasequery("SELECT filename FROM Recorded WHERE (ChannelID='#{chan_id}'AND START= '#{date_time}')").fetch_row
error_if_not_equal( showname.nil?, false, "Show does not exist")
showname = showname[0]

#remove from hard drive
Dir[VIDEO_PATH+"*"].grep(/#{Regexp.escape(showname)}/).each {|file| File.delete file}

databasequery("DELETE FROM Scheduled WHERE (channelID = '#{chan_id}'AND start = '#{date_time}')")
databasequery("DELETE FROM Recorded WHERE (channelID = '#{chan_id}'AND start = '#{date_time}')")

puts "<success>Removed #{showname.gsub(/_/," ")} from hard drive</success>"
puts XML_FOOTER
