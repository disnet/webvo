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
   return result
end

def databaseconnect()
  dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
  return dbh
end

def findProcessNum(procCat)
  puts procCat
  readme = IO.popen("ps -C #{procCat} -o pid")
  sleep (1)
  temp = readme.gets
  puts temp
  pid = readme.gets
  puts pid
  readme.close()
  return pid
end

def findProcNum(procNum)
  readme = IO.popen("ps #{procNum}")
  sleep (1)
  temp = readme.gets
  pid = readme.gets
  readme.close()
  return pid
end

def calcTimeTo(date1,date2)
  diffstop = date1 - date2
  sh,sm,ss,sfrac = Date.day_fraction_to_time(diffstop)
  diffstopInS = (sh)*3600 + (sm)*60 + ss
  return diffstopInS
end
#begin recording script

if __FILE__ == $0

#connect to the mysql server
begin
  dbh = databaseconnect()
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
  
  #make sure there are shows to record
  showcheck = dbh.query("SELECT Start FROM Recording ORDER BY Start")  
  noshowcheck = showcheck.fetch_row
  if noshowcheck == nil
    puts "No shows to record"
    dbh.close()
    exit
  end

  #return the last PID (if there is one)
  pidrow = dbh.query("SELECT PID FROM Recording WHERE PID!=0")
  pidres = pidrow.fetch_row
  #if there is no pid continue normally
  if pidres.nil?
     puts "No PIDs found\n"

  #if there is one, need to locate and end process
  else
     CAT_PID = pidres
     puts "PID found: #{CAT_PID}"
     pid = findProcNum(CAT_PID)
     #if not found as actually running,remove from database
     if pid.nil?
       puts "Process not actually running"
       dbh.query("UPDATE Recording SET PID = 0 WHERE PID = #{CAT_PID}")

     #if is found to be running, need to confirm that isn't most recent program
     else
       row = dbh.query("SELECT PID FROM Recording ORDER BY start LIMIT 1")
       initialpid = row.fetch_row
       #if is not most recent show, kill process
       if initialpid.nil?
         puts "Current process does not contain most recent show"
	 commandSent = system("kill #{CAT_PID}")
         dbh.query("UPDATE Recording SET PID = 0 WHERE PID = #{CAT_PID}")
       
       #otherwise leave it alone, wait for it to finish
       else
       puts "Most current show already recording, please wait until finished\n"
       dbh.close()
       exit
       end 
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
  puts startrow
  puts "The show to be recorded is on channel #{channelrow}, starts at #{startrow} and ends at #{stoprow}."
  
#initialize values of show  
  showStartDate = format_to_Ruby("#{startrow}")
  showStopDate = format_to_Ruby("#{stoprow}")
  currDate = DateTime.now
  show = RecordedShow.new(20061115100,channelrow,startrow,stoprow)

#calc if show has been missed
  diffstop = calcTimeTo(showStopDate,currDate)
 
#calc show length in seconds
  showlength = calcTimeTo(showStopDate,showStartDate)
  puts "show length in seconds " + showlength.to_s

#calculate when recording show starts
  sleeptime = calcTimeTo(showStartDate,currDate)
  puts "sleep for this long " + sleeptime.to_s

#if the show started already and is over
  if diffstop < 0
    puts "Sorry, the time has passed for this show\n"
    dbh = databaseconnect()
    dbh.query("DELETE FROM Recording WHERE start = #{startrow}")
    dbh.close()
    #commandSent = system ("ruby record.rb")
    exit
  end

#if the show hasn't started yet
  if sleeptime > 0
    hours = sleeptime/3600
    minutes = (sleeptime%3600)/60
    seconds = minutes%60
#locate PID for process
    CAT_PID = findProcessNum("ruby")
    puts CAT_PID

#send CAT_PID to database (need to reopen database)
    dbh = databaseconnect()
    dbh.query("UPDATE Recording SET PID = #{CAT_PID.to_i} WHERE Start = #{startrow[0]}")
    puts "PID saved to database\n"


#close the database
    dbh.close()

#go to sleep
    puts "The show will start in #{hours.to_i} hours, #{minutes.to_i} minutes and #{seconds.to_i} seconds.\n"
    sleep (sleeptime)
  end

#if here, begin recording immediately  
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
    sleep (1)
    CAT_PID = findProcessNum("cat")
    puts CAT_PID

#send CAT_PID to database (need to reopen database)
    dbh = databaseconnect()
    dbh.query("UPDATE Recording SET PID = #{CAT_PID.to_i} WHERE Start = #{startrow[0]}")
    puts "PID saved to database\n"

#close the database
    dbh.close()

#sleep for length of the show
   puts "Going to sleep for the show: #{showlength}\n" 
   sleep (showlength)

#stop the recording
    commandSent = system("kill #{CAT_PID}")
    puts "Recording done!\n"
 
#reopen the database (will remove PID)
    dbh = databaseconnect()
    
#move the show from the recording list to recorded list
    puts "Moving show to recorded list\n"
    transferquery = dbh.query("#{channelIDquery}")
    chanID = transferquery.fetch_row
    puts chanID
    dbh.query("INSERT INTO Recorded (channelID,start) VALUES ('#{chanID}', '#{startrow}')")
    puts "Removing show from recording list\n"
    dbh.query("DELETE FROM Recording WHERE PID = #{CAT_PID}")
     
#close the database
    dbh.close()
end

