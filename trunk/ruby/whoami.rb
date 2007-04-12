#!/usr/local/bin/ruby

t = IO.popen('whoami')
out = t.read

puts "Content-Type: text/plain\n\n"
puts out
