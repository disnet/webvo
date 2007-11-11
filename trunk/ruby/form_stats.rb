#!/usr/bin/env ruby

require 'util'

DATE_FORMAT_STRING = "%Y-%m-%d"

puts JSON_HEADER

retstr = "{ 'type': 'stats'"

stop_day = databasequery("SELECT DATE_FORMAT(stop,'#{DATE_FORMAT_STRING}') FROM Programme ORDER BY stop DESC LIMIT 1").fetch_row
#start_day = Time.now.strftime(DATE_FORMAT_STRING)
start_day = databasequery("SELECT DATE_FORMAT(start,'#{DATE_FORMAT_STRING}') FROM Programme ORDER BY start ASC LIMIT 1").fetch_row
retstr += ",\n'programme_date_range': {'start': '"+ start_day.to_s + "', 'stop': '" + stop_day.to_s + "'}"
space = freespace

retstr += ",\n'space': {" +
    "'available': '#{space['available']}', " +
    "'used': '#{space['used']}', " +
    "'total': '#{space['total']}' }"


recording = getNextShow

unless recording.nil?
    retstr += ",\n'recording': {" +
        "'id': '#{recording.channelID+recording.start_xml}', " +
        "'channel': '#{recording.channel}', " +
        "'filename': '#{recording.filename.to_s.gsub(/'/,"&#39;")}' }"
end

retstr += ",\n'datetime': '#{Time.new.strftime(DATE_TIME_FORMAT_RUBY_XML)}'"

retstr += "\n}"

puts retstr
