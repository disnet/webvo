#!/usr/bin/env ruby

require 'util'

puts XML_HEADER

stop_day = databasequery("SELECT DATE_FORMAT(stop,'#{DATE_FORMAT_STRING}') FROM Programme ORDER BY stop DESC LIMIT 1").fetch_row
#start_day = Time.now.strftime(DATE_FORMAT_STRING)
start_day = databasequery("SELECT DATE_FORMAT(start,'#{DATE_FORMAT_STRING}') FROM Programme ORDER BY start ASC LIMIT 1").fetch_row
puts "<programme_date_range start='"+ start_day.to_s + "' stop='" + stop_day.to_s + "'></programme_date_range>\n"

space = freespace

puts "<space>"
puts "<available>" + space['available'] + "</available>"
puts "<used>" + space['used'] + "</used>"
puts "<total>" + space['total'] + "</total>"
puts "</space>"

recording = getNextShow

unless recording.nil?
    puts "<recording>"
    puts recording.xmlNode
    puts "</recording>"
end

puts XML_FOOTER
