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
   return DateTime.new(year,month,day,hour,minute,second)
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
  #if there is no pid continue normally
  if pidres[0].nil?
     puts "No PIDs found\n"

  #if there is one, need to locate and end process
  else
     CAT_PID = pidres[0] #need PID number
     puts "PID found: #{CAT_PID}"
     readme = IO.popen("ps #{CAT_PID}")
     sleep (1)
     temp = readme.gets
     pid = readme.gets
     if pid != 0
       commandSent = system("kill #{CAT_PID}")
     end
  end   
 end

#parse info from database of last entry
  channelIDquery = "SELECT ChannelID FROM Recording ORDER BY Start LIMIT 1"
  lastshowstart = dbh.query("SELECT Start FROM Recording ORDER BY Start LIMIT 1")
  lastshowchannel = dbh.query("SELECT number FROM Channel WHERE ChannelID = (#{channelIDquery})")
  lastshowstop = dbh.query("SELECT STOP FROM Programme WHERE(ChannelID=(#{channelIDquery})AND START=(SELECT Start FROM Recording ORDER BY Start LIMIT 1))")

#change vals to numbers
  startrow = lastshowstart.fetch_row
  channelrow = lastshowchannel.fetch_row
  stoprow = lastshowstop.fetch_row
  puts "The show to be recorded is on channel #{channelrow[0]}, starts at #{startrow[0]} and ends at #{stoprow[0]}."

#initialize values of show
  showStartDate = format_to_Ruby("#startrow[0]")
  showStopDate = format_to_Ruby("#{stoprow[0]}")
  currDate = DateTime.now
  show = RecordedShow.new(20061115100,lastshowchannel,lastshowstart,lastshowstop)
  
  #calculate when recording show starts

  puts "Recording channel #{show.channel} from #{show.starttime} to #{show.stoptime}."
  
  #tune the card to the correct channel
  commandSent = system ("ivtv-tune -c #{show.channel}")
  if commandSent != true
    puts "Channel set failed\n"
  end
  
  #start the recording
  puts "Beginning recording \n"
  commandSent = system ("cat /dev/video0 > /home/daryl/Desktop/TestVideos/#{show.showID}.mpg &")
  if commandSent != true
    puts "Recording failed to start\n"
  end
  
  readme = IO.popen("ps -C cat -o pid")
  output = ""
  sleep (1)
  temp = readme.gets
  CAT_PID = readme.gets
#send CAT_PID to database
  #dbh.query ("
  readme.close

  #sleep for length of the show
  sleep (5)

  #stop the recording
  commandSent = system("kill #{CAT_PID}")
  puts "Recording done!"

#close the database
  dbh.close()

end
