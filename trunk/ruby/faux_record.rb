#!/usr/local/bin/ruby
puts "<hello>got here</hello>"
cgi.close
sleep(14)
log = File.open("recording_log.txt", "w")
log << "got here"