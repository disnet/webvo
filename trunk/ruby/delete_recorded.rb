#!/usr/local/bin/ruby

#Delete the recording from the hard drive

require "mysql"
require "cgi"

SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVo"
TABLENAME = "Recording"
PROG_ID = "prog_id"
VIDEO_PATH = "/home/daryl/Desktop/TestVideos"
LENGTH_OF_DATE_TIME = 14

#connect to the database
def databaseconnect()
  begin
  dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
  rescue MysqlError => e
    print "Error code: ", e.errno, "\n"
    print "Error message: ", e.error, "\n"
    puts "Unable to connect to database\n"
    if dbh.nil? == false
      dbh.close() 
      exit
    end
  else
    return dbh
  end
end

#Error handler
def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts "<error>Error " + error_string +"</error>"
    exit
  end
end

#find the category name of the process
def findProcCat(procNum)
  readme = IO.popen("ps -p #{procNum} -o cmd")
  sleep (1)
  temp = readme.gets
  cmd = readme.gets
  readme.close()
  return cmd
end


puts "Content-Type: text/plain\n\n" 

  cgi = CGI.new     # The CGI object is how we get the arguments 

#checks for 1 argument
  error_if_not_equal(cgi.keys.length(), 1, "Needs one argument")
  error_if_not_equal(cgi.has_key?(PROG_ID), true, "Needs Programme ID")
#get argument
  prog_id =  cgi[PROG_ID][0]
  error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Needs a Channel ID")
  date_time = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
  chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME-1).to_i]
  if chan_id == nil || date_time == nil:
     puts "Show does not exist"
     exit
  else
     puts "chanID and datetime acquired"
  end

#get the showName
  dbh = databaseconnect()
  shownameres = dbh.query("SELECT showName FROM Recorded WHERE (ChannelID='#{chan_id}'AND START= '#{date_time}')")
  temp = shownameres.fetch_row
  showname = temp.to_s
  showname.strip
  if showname == nil
     puts "Show does not exist"
     exit
  else
     showname << "-0"
     puts showname
     puts "showname acquired"
  end
    
#check the hard drive for the show to be deleted
  check = "#{VIDEO_PATH}/#{showname}.mpg"
  onHD = IO.popen("ls #{check}")
  test = onHD.gets
  puts test
  onHD.close()

#if does not exist, return error
  puts check
  if !(test.strip == check.strip)
     puts "Show does not need to be deleted"
     exit

#if it does,remove it from recording, recorded and programme
  else
     puts "Show located"

#check in Recording to see if still recording one of the fragments
     schedcheck = dbh.query("SELECT PID FROM Recording WHERE(ChannelID = '#{chan_id}'AND Start = '#{date_time}')")
     cmdcheck = dbh.query("SELECT CMD FROM Recording WHERE(ChannelID = '#{chan_id}'AND Start = '#{date_time}')")
     sched = schedcheck.fetch_row
     cmd = cmdcheck.fetch_row
     puts "#{sched} #{cmd}"

#if is still recording, need to kill process (if it exists) and remove from Recording
     if sched != nil
        comd = findProcNum(sched)
        puts comd
        if comd == cmdcheck
          commandSent = system ("kill #[schedcheck}")
        end
     end

#remove from recording now that checked to make sure no longer running
     dbh.query("DELETE FROM Recording Where (ChannelID = '#{chan_id}'AND Start = '#{date_time}')")
     puts "Removed from Recording"
#remove from recorded
     dbh.query("DELETE FROM Recorded Where ShowName = '#{showname}'")
     puts "Removed from Recorded"
#remove from programme
     dbh.query("DELETE FROM Programme Where(ChannelID = '#{chan_id}'AND Start = '#{date_time}')")
     puts "Removed from Programme"
     dbh.close()

#remove from hard drive (need to locate all fragments as well)

#get the fragment number from the name
     lastchar = showname[showname.length-1]
     checkforfrags = IO.popen("ls #{check}")

#remove first fragment
     exec("rm #{check}")
     puts "#{check} has been removed"
#check for more fragments
     #while the show is not located on HD
     while (!checkforfrags.nil?)
     #increment the fragment number
        lastchar += 1
        puts lastchar
     #reinsert into title string
        showname[showname.length-1] = lastchar
        puts showname
     #see if the show exists
        checkforfrags = IO.popen("ls #{VIDEO_PATH}/#{showname}.mpg")
     #if it doesn't, get out of loop
        if checkforfrags.nil?
          deletefromHD.close()
          checkforfrag.close()
          break
#if it does, delete from HD,      puts "retrieved"look for another fragment
        else  
          deletefromHD = IO.popen("rm #{VIDEO_PATH}/#{showname}.mpg")
          puts "#{VIDEO_PATH}/#{showname}.mpg has been removed"
        end  
     #close while loop
     end
#all done
     puts "Removed from hard drive"
  end

