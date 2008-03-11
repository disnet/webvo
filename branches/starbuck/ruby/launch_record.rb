#!/usr/local/bin/ruby
#Debug code for webvo

puts "Content-Type:text/plain\n\n"

puts "Launching record.rb..."
pid = fork do
    STDIN.close
    STDOUT.close
    STDERR.close
    exec('ruby record.rb')
end

Process.wait
puts "Finished"
