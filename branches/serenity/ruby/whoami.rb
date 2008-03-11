#!/usr/local/bin/ruby

t = IO.popen('which ivtv-encoder')
out = t.read

puts "Content-Type: text/plain\n\n"
puts out
