#!/usr/bin/ruby1.8
#require 'cgi'

puts "Content-Type: text/plain\n\n"    # If this was an html doc the Content-Type would have been 'text/html' and if it was an xml doc it would be 'text/xml'
                                       # It is always needed to help the browser decide what to do with the document
                                       # It is a header and never seen in the output

cgi = CGI.new                                  # The CGI object is how we get the arguments
puts "The name argument was #{cgi['name']}"
puts "The job argument was #{cgi['job']}"
