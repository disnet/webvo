#!/usr/bin/env ruby

require 'util'

#DATE_FORMAT_STRING = "%Y-%m-%d"

puts JSON_HEADER

retstr = "{ 'type': 'stats'"

stop_day = databasequery("SELECT DATE_FORMAT(stop,'#{DATE_TIME_FORMAT_XMLSCHEMA}') FROM Programme ORDER BY stop DESC LIMIT 1").fetch_row
#start_day = Time.now.strftime(DATE_TIME_FORMAT_XMLSCHEMA)
start_day = databasequery("SELECT DATE_FORMAT(start,'#{DATE_TIME_FORMAT_XMLSCHEMA}') FROM Programme ORDER BY start ASC LIMIT 1").fetch_row
stop_day = Time.xmlschema(stop_day.to_s).localtime
start_day = Time.xmlschema(start_day.to_s).localtime
retstr += ",\n'programme_date_range': {'start': '"+ start_day.xmlschema + "', 'stop': '" + stop_day.xmlschema + "'}"
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

retstr += ",\n'datetime': '#{Time.new.xmlschema}'"

retstr += "\n}"

puts retstr
