#!/usr/bin/env ruby

#David Hopkins
#This is a "do close to nothing" replacement for ivtv-encoder 
#to be used for Webvo development/testing

channel = ARGV[1]
length = ARGV[2].to_i
filename = ARGV[3]

if filename.nil?
    puts "Error: need 4 arguments (-c channel length filename)"
    exit
end

filedex = File.new(filename+".index", 'w')
filedex.puts "This is the #{filename} index file"
filedex.close

file = File.new(filename, 'w')
file.puts "(#{Time.now}) started  channel: #{channel}, length: #{length}"
sleep length 
file.puts "(#{Time.now}) stopped  channel: #{channel}, length: #{length}"
file.close
