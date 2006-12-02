#!/usr/local/bin/ruby
require 'cgi'

  puts "Content-Type: text/plain\n\n" 
  
  cgi = CGI.new     # The CGI object is how we get the arguments 
  
  puts "calling faux_record.rb"
  pid = fork
    cgi.close
    system("ruby faux_record.rb &")
  end
  Process.detach(pid)
  puts "done"
  Process.detach
  cgi.close