#!/usr/local/bin/ruby

#Delete the recording from the hard drive

require "mysql"
require "cgi"

LENGTH_OF_DATE_TIME = 14

f = File.new('webvo.conf','r')
conf = f.read
f.close

servername = conf.match(/(\s*SERVERNAME\s*)=\s*(.*)/)
SERVERNAME = servername[2]

username = conf.match(/(\s*USERNAME\s*)=\s*(.*)/)
USERNAME = username[2]

userpass = conf.match(/(\s*USERPASS\s*)=\s*(.*)/)
USERPASS = userpass[2]

dbname = conf.match(/(\s*DBNAME\s*)=\s*(.*)/)
DBNAME = dbname[2]

tablename = conf.match(/(\s*TABLENAME\s*)=\s*(.*)/)
TABLENAME = tablename[2]

video_path = conf.match(/(\s*VIDEO_PATH\s*)=\s*(.*)/)
VIDEO_PATH = video_path[2]

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

#main------------------------------------------------------------
puts "Content-Type: text/xml\n\n"
puts "<?xml version='1.0' encoding='ISO-8859-1'?>"
puts "<tv>"
#checks for 1 argument
#  error_if_not_equal(ARGV.length(),1, "Needs one argument")
  
#get argument
#  prog_id = ARGV[0]

  cgi = CGI.new
  prog_id = cgi['prog_id'][0]

  error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Needs a Channel ID")
  date_time = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
  chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME-1).to_i]

  if chan_id == nil || date_time == nil:
     puts "<error>Show does not exist</error>"
     exit
  else
     puts "<success>chanID and datetime acquired</success>"
  end

#get the showName
  dbh = databaseconnect()
  shownameres = dbh.query("SELECT showName FROM Recorded WHERE (ChannelID='#{chan_id}'AND START= '#{date_time}')")
  temp = shownameres.fetch_row
  showname = temp.to_s
  showname.strip
  if showname == nil
     puts "<error>Show does not exist</error>"
     dbh.close()
     exit
  end
    
#check the hard drive for the show to be deleted
  check = "#{VIDEO_PATH}#{showname}"
  onHD = IO.popen("ls #{check}-0.mpg")
  test = onHD.gets
  onHD.close()

#if does not exist, return error
  if test.nil?
     puts "<error>Show does not need to be deleted</error>"
     exit

#if it does,remove it from recording, recorded and programme
  else
     puts "<success>Show located</success>"

#check in Recording to see if still recording one of the fragments
     schedcheck = dbh.query("SELECT cat_pid FROM Recording WHERE(ChannelID = '#{chan_id}'AND Start = '#{date_time}')")
     cmdcheck = dbh.query("SELECT CMD FROM Recording WHERE(ChannelID = '#{chan_id}'AND Start = '#{date_time}')")
     sched = schedcheck.fetch_row
     cmd = cmdcheck.fetch_row

#if is still recording, need to kill process (if it exists) and remove from Recording
     if sched != nil
        commandSent = system ("kill #[sched}")
     end

#remove from recording now that checked to make sure no longer running
     dbh.query("DELETE FROM Recording Where (ChannelID = '#{chan_id}'AND Start = '#{date_time}')")
     puts "<success>Removed from Recording</success>"
#remove from recorded
     dbh.query("DELETE FROM Recorded Where (ChannelID = '#{chan_id}'AND Start = '#{date_time}')")
     puts "<success>Removed from Recorded</success>"
#remove from programme
     dbh.query("DELETE FROM Programme Where(ChannelID = '#{chan_id}'AND Start = '#{date_time}')")
     puts "<success>Removed from Programme</success>"
     dbh.close()

#remove from hard drive (need to locate all fragments as well)

#get the fragment number from the name
     lastchar = 0
     hold = IO.popen("ls #{check}-#{lastchar}.mpg")
     checkforfrags = hold.gets

#check for more fragments
     #while the show is not located on HD
     while (!checkforfrags.nil?)
     
     #remove first fragment
       system("rm -f #{check}-#{lastchar}.mpg")
       puts "<success>#{check} has been removed</success>"

     #increment the fragment number
       lastchar += 1
     #see if the show exists
        hold = IO.popen("ls #{check}-#{lastchar}.mpg")
        checkforfrags = hold.gets
     #if it doesn't, get out of loop
        if checkforfrags.nil?
          break
        end  
     #close while loop
     end
#all done
     puts "<success>Removed from hard drive</success>"
  end
  puts "</tv>"
  hold.close()
#close stdout
  STDOUT.close
  STDIN.close
  #STDERR.close
#call record.rb
  system ("ruby record.rb &")
  exit
