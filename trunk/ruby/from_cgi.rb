require 'cgi'

  puts "Content-Type: text/plain\n\n" 
  
  cgi = CGI.new     # The CGI object is how we get the arguments 
  
  puts "calling faux_record.rb"
  
  system("ruby faux_record.rb")
  
  puts "done"