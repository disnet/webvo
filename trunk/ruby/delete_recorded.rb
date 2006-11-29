#!/usr/local/bin/ruby

#Delete the recording from the hard drive

require "mysql"
require "cgi"

SERVERNAME = "tvbox.homelinux.com/phpmyadmin/"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVo"
TABLENAME = "Recording"
PROG_ID = "prog_id"
VIDEO_PATH = "/home/daryl/Desktop/TestVideos"

#connect to the database
def databaseconnect()
  dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
  rescue MysqlError => e
       print "Error code: ", e.errno, "\n"
       print "Error message: ", e.error, "\n"
  puts "Unable to connect to database\n"
  if dbh.nil? == false
    dbh.close() 
    exit
  end
  return dbh
end

#Error handler
def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts "<error>Error " + error_string +"</error>"
    exit
  end
end

if __FILE__ == $0

puts "Content-Type: text/plain\n\n" 

begin
  cgi = CGI.new     # The CGI object is how we get the arguments 
  puts "Input taken"

#checks for 1 argument
  error_if_not_equal(cgi.keys.length(), 1, "Needs one argument")
  error_if_not_equal(cgi.has_key?(PROG_ID), true, "Needs Programme ID")
  puts "checked for 1 arg"
#get argument
  prog_id =  cgi[PROG_ID][0]
  puts "prog_id returned"
  error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Needs a Channel ID")
  date_time = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
  chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME-1).to_i]
  puts "chanID and datetime acquired"

#get the showName
  dbh = databaseconnect()
  shownameres = dbh.query("SELECT Title FROM Programme WHERE (ChannelID='#{chan_id}'AND START= '#{date_time}')")
  showname = shownameres.fetch_row
  puts "show name acquired"
    
#check the hard drive for the show to be deleted
  onHD = system("ls #{VIDEO_PATH}/#{showname}.mpg")     
#if does not exist, return error
  if onHD.gets != "#{VIDEO_PATH}/#{showname}.mpg"
     puts "Show does not need to be deleted"
     exit
#if it does,remove it from recording, programme
  else
     puts "Show located"
     dbh.query("DELETE FROM Recorded Where ShowName = '#{showname}'")
     puts "Removed from Recorded"
     dbh.query("DELETE FROM Programme Where ShowName = '#{showname}'")
     puts "Removed from Programme"
     dbh.close()

#remove from hard drive
     #need to locate all fragments as well
     lastchar = showname[showname.length-4]

#remove first fragment
     deletefromHD = IO.popen ("rm #{VIDEO_PATH}/#{showname}.mpg")
     puts deletefromHD

#check for more fragments
     while (!deletefromHD.nil?)
        lastchar += 1
        puts lastchar
     #reinsert into title string
        showname[lastcharnum-4] = lastchar
     #see if the show exists
        checkforfrags = system("ls #{VIDEO_PATH}/#{showname}.mpg")
     #if it doesn't, get out of loop
        if checkforfrags.nil?
          deletefromHD.close()
          break
#if it does, delete from HD, look for another fragment
        else  
          deletefromHD = system ("rm #{VIDEO_PATH}/#{showname}.mpg")
        end  
    
     end
#all done
     puts "Removed from hard drive"
  end
end

end
