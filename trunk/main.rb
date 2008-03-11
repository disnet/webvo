#!/usr/local/bin/ruby
require 'cgi'
puts "Content-Type: text/html\n\n"

cgi = CGI.new
if cgi.has_key?('user') && cgi.has_key?('passwd'):
    if cgi['user'] == 'admin' &&  cgi['passwd'] == 'csc4150':
        doc = File.read("listing.html")
    else
        doc = "<html><head><title>Error</title></head><body><p>Error: must enter valid username and password</p></body></html>"
    end
else
    doc = "<html><head><title>Error</title></head><body><p>Error: must enter a useranme and password</p></body</html>"
end
puts doc
