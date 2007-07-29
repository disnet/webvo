#!/usr/local/bin/ruby

puts "Content-Type: text/html\n\n"

puts "<html><head><title>WebVo -- Login</title></head>"
puts "<body><form action='main.rb' method='post'>"
puts "User <input type='text' name='user'><br />"
puts "Password <input type='password' name='passwd'>"
puts "<input type='submit' value='Login'></body></html>"
