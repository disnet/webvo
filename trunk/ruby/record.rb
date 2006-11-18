#Daryl Siu
#Write to the recorder in Ruby

require "date"

#class to hold pertinent data for recording a show
class RecordedShow
  attr_accessor :channel
  attr_accessor :starttime
  attr_accessor :stoptime
  attr_accessor :showID=

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
     #end process
     commandSent = system ("kill #{CAT_PID}") 
     #set the PID value to 0
     dbh.query ("UPDATE #{TABLENAME} SET PID = 0 WHERE PID = #{CAT_PID}")
  end

#parse info from database of last entry
lastshowchannel = dbh.query("SELECT channel FROM #{TABLENAME} ORDERBY timestamp LIMIT 1")
lastshowstart = dbh.query("SELECT startTime FROM #{TABLENAME} ORDERBY timestamp LIMIT 1")
lastshowstop = dbh.query("SELECT stopTime FROM #{TABLENAME} ORDERBY timestamp LIMIT 1")

#close the database
dbh.close
end

#initialize values of show
  showStartDate = format_to_Ruby(lastshowstart)
  showStopDate = format_to_Ruby(lastshowstop)
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
  dbh.query ("
  readme.close

  #sleep for length of the show
  sleep (5)

  #stop the recording
  commandSent = system("kill #{CAT_PID}")
  puts "Recording done!"

end
