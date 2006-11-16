#!/usr/bin/ruby1.8
require 'cgi'
cgi = CGI.new

# If this is an html doc should be 'text/html'
# If an xml doc then 'text/xml'
puts "Content-Type: text/plain\n\n"

puts "Hello, world"
puts cgi['name']
