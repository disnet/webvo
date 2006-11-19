#!/usr/local/bin/ruby

#Daryl Siu
#Write to the recorder in Ruby

require "date"
require "mysql"

SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVo"
TABLENAME = "Recording"

#class to hold pertinent data for recording a show
class RecordedShow
  attr_accessor :channel
  attr_accessor :starttime
  attr_accessor :stoptime
  attr_accessor :showID

  def initialize(sid,chnl,statime,stotime)
    @showID = sid
    @channel = chnl
    @starttime = statime
    @stoptime = stotime
  end
  
end

#change from xml form of the date to the dateTime form
def format_to_Ruby (xmlform_data)
   year = xmlform_data[0..3].to_i
   month = xmlform_data[4..5].to_i
   day = xmlform_data[6..7].to_i
   hour = xmlform_data[8..9].to_i
   minute = xmlform_data[10..11].to_i
   second = xmlform_data[12..13].to_i
   puts "#{year} #{month} #{day}  #{hour} #{minute} #{second}"
   result = DateTime.new(year,month,day,hour,minute,second,-0.3333333334,2361222)
   puts "timezone " + result.zone()
   return result
end

#begin recording script

if __FILE__ == $0

#connect to the mysql server
begin
  dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
#if get an error (can't connect)
rescue MysqlError => e
       print "Error code: ", e.errno, "\n"
       print "Error message: ", e.error, "\n"
  puts "Unable to connect to database\n"
  if dbh.nil? == false
    dbh.close() 
  end

#if there are no errors
else
  #return the last PID (if there is one)
  pidrow = dbh.query("SELECT PID FROM Recording WHERE PID!=0")
  pidres = pidrow.fetch_row
  puts pidres
  #if there is no pid continue normally
  if pidres.nil?
     puts "No PIDs found\n"

  #if there is one, need to locate and end process
  else
     CAT_PID = pidres[0] #need PID number
     puts "PID found: #{CAT_PID}"
     readme = IO.popen("ps #{CAT_PID}")
     sleep (1)
     temp = readme.gets
     pid = readme.gets
     if pid != "NULL"
       commandSent = system("kill #{CAT_PID}")
       dbh.query("UPDATE Recording SET PID = 0 WHERE PID = #{CAT_PID}")
     end
  end   
 end

#parse info from database of last entry
  channelIDquery = "SELECT ChannelID FROM Recording ORDER BY Start LIMIT 1"
  lastshowstart = dbh.query("SELECT Start FROM Recording ORDER BY Start LIMIT 1")
  lastshowchannel = dbh.query("SELECT number FROM Channel WHERE ChannelID = (#{channelIDquery})")
  lastshowstop = dbh.query("SELECT STOP FROM Programme WHERE(ChannelID=(#{channelIDquery})AND START=(SELECT Start FROM Recording ORDER BY Start LIMIT 1))")

#done with DB for now
  dbh.close()

#change vals to numbers
  startrow = lastshowstart.fetch_row
  channelrow = lastshowchannel.fetch_row
  stoprow = lastshowstop.fetch_row
  puts channelrow
  puts "The show to be recorded is on channel #{channelrow}, starts at #{startrow} and ends at #{stoprow}."
  
#initialize values of show
  
  showStartDate = format_to_Ruby("#{startrow}")
  puts "showStartDate " + showStartDate.to_s
  showStopDate = format_to_Ruby("#{stoprow}")
  puts "showStopDate" + showStopDate.to_s
  puts "curdate:" + (currDate = DateTime.now).to_s #(2361222)
  puts "Current date:  #{currDate.year()} #{currDate.mon()} #{currDate.day()}  #{currDate.hour()} #{currDate.min()} #{currDate.sec()}"
  show = RecordedShow.new(20061115100,channelrow,startrow,stoprow)

  #calc if show has been missed
  diffstop = showStopDate - currDate
  sh,sm,ss,sfrac = Date.day_fraction_to_time(diffstop)
  puts "#{sh} #{sm} #{ss}"
  diffstopInS = (sh)*3600 + (sm)*60 + ss
  puts diffstopInS

  #calc show length in seconds
  showlength = showStopDate - showStartDate
  puts showlength
  sh,sm,ss,sfrac = Date.day_fraction_to_time(showlength)
  puts "#{sh} #{sm} #{ss}"
  showlengthInS = (sh)*3600 + (60-sm)*60 + ss

  #calculate when recording show starts
  diffstart = showStartDate - currDate 
  sh,sm,ss,sfrac = Date.day_fraction_to_time(diffstart)
  puts "#{sh} #{sm} #{ss}"
  sleeptime = (sh)*3600 + (60-sm)*60 + ss
  puts sleeptime

  #if the show hasn't started yet
  if sleeptime > 0
    puts "The show will start in #{sh} hours and #{sm} minutes.\n"
    sleep (sleeptime)

  #if the show started already and is over
  else if diffstopInS < 0
    puts "Sorry, the show wasn't recorded\n"
  
  #begin recording immediately
  else
  
  #tune the card to the correct channel
    commandSent = system ("ivtv-tune -c #{show.channel}")
    if commandSent != true
      puts "Channel set failed\n"
    end
  
  #start the recording
    puts "Recording channel #{show.channel} from #{show.starttime} to #{show.stoptime}.\n"
    puts "Beginning recording \n"
    commandSent = system ("cat /dev/video0 > /home/daryl/Desktop/TestVideos/#{show.showID}.mpg &")
    if commandSent != true
      puts "Recording failed to start\n"
    end

  #locate PID for process
    readme = IO.popen("ps -C cat -o pid")
    sleep (1)
    temp = readme.gets
    CAT_PID = readme.gets
    puts CAT_PID.to_i
  #send CAT_PID to database (need to reopen database)
    dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
    dbh.query("UPDATE Recording SET PID = #{CAT_PID.to_i} WHERE Start = #{startrow[0]}")
    puts "PID saved to database\n"
    readme.close

  #close the database
    dbh.close()

  #sleep for length of the show
   puts "Going to sleep for the show\n" 
   sleep (showlengthInS)

  #stop the recording
    commandSent = system("kill #{CAT_PID}")
    puts "Recording done!\n"
 
  #reopen the database (will remove PID)
    dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
    
  #move the show from the recording list to recorded list
    puts "Moving show to recorded list\n"
    transferquery = dbh.query("#{channelIDquery}")
    dbh.query("INSERT INTO Recorded (ChannelID,Start) VALUES (transferquery,startrow)")
    puts "Removing show from recording list\n"
    dbh.query("DELETE FROM Recording WHERE PID = #{CAT_PID}")
     
    #close the database
    dbh.close()

  end
 end
end
