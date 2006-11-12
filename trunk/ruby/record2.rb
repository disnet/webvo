#Daryl Siu
#Second attempt at writing out commands to Ruby

require "mysql"

SERVERNAME = "tvbox.homelinux.com/localhost"
USERNAME = "root@localhost"
USERPASS = ""
DBNAME = "WebVo"
TABLENAME = "Recording"

#change from xml form of the date to the dateTime form
def format_to_date (xmlform_data)
   year = xmlform_data[0..3].to_i
   month = xmlform_data[4..5].to_i
   day = xmlform_data[6..7].to_i
   hour = xmlform_data[8..9].to_i
   minute = xmlform_data[10..11].to_i
   second = xmlform_data[12..13].to_i
   return DateTime.new(year,month,day,hour,minute,second)
end

#class to hold pertinent data for recording a show
class RecordedShow
  attr_accessor :channel
  attr_accessor :starttime
  attr_accessor :stoptime
  attr_accessor :showID

  def initialize(SID,chnl,statime,stotime)
    @showID = SID
    @channel = chnl
    @starttime = statime
    @stoptime = stotime
  end
  
end

if __FILE__ == $0

#connect to the mysql server
dbh = Mysql.real_connect("#{SERVERNAME},#{USERNAME},#{USERPASS},#{DBNAME}")
rescue MysqlError => e
  Print "Error code: ",e.errno, "\n"
  Print "Error message: ",e.error, "\n"

ensure
  #return the last PID (if there is one)
  pidres = dbh.query("SELECT PID FROM #{TABLENAME} WHERE PID!=NULL")

  #if there is no pid continue normally
  if pidres.nil? then
     puts "No PIDs found\n"

  #if there is one, need to locate and end process
  else
     CAT_PID = pidres #need PID number
     puts "PID found: #{CAT_PID}"
     kill CAT_PID if CAT_PID.alive? == true
  #need to change the pidvalue to zero
  end

#close the database
dbh.close
end

#parse info from database of last entry
lastshowchannel = dbh.query("SELECT channel FROM #{TABLENAME} ORDERBY timestamp LIMIT 1")
lastshowstart = dbh.query("SELECT startTime FROM #{TABLENAME} ORDERBY timestamp LIMIT 1")
lastshowstop = dbh.query("SELECT stopTime FROM #{TABLENAME} ORDERBY timestamp LIMIT 1")

#begin show recording

#initialize show object
show = RecordedShow.new(20061030100,lastshowchannel,lastshowstart,lastshowstop)
  
#calculate when recording show starts
currTime = DateTime.now
showTime = format_to_date(show.starttime)
if showtime - currTime != 0 #if not starting now
  diffTime = showTime-currTime
  waittime = diffTime.day*24*60*60 + diffTime.hour*60*60 + diffTime.minute*60 + diffTime.second
  sleep (waittime)
end
 
#outputting recording information
puts "Recording channel #{show.channel} from #{show.starttime} to #{show.stoptime}."
 
#tune the card to the correct channel
commandSent = System ("ivtv -tune -c#{show.channel}")
if commandSent != true
  puts "Channel set failed\n"
end
  
#start the recording
commandSent = System ("cat /dev/video0 > #{show.showID}.mpg")
CAT_PID = $! #keeps track of last job ID number
#insert value of CAT_PID into table

if commandSent != true
  puts "Recording failed to start\n"
end

#sleep for length of the show
stopTime = format_to_date(show.stoptime)
diffTime = stopTime - showTime
waittime = diffTime.day*24*60*60 + diffTime.hour*60*60 + diffTime.minute*60 + diffTime.second
sleep (waittime)

#stop the recording
kill CAT_PID if CAT_PID.alive? == true

#end of the program
end