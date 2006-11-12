#Daryl Siu
#Second attempt at writing out commands to Ruby

require "mysql"

SERVERNAME = "localhost"
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
  attr_accessor :show

  def inputVals(sid,chnl,statime,stotime)
    @showID = sid
    @channel = chnl
    @starttime = statime
    @stoptime = stotime
  end
  
end

if __FILE__ == $0

#connect to the mysql server
begin
  dbh = Mysql.real_connect("#{SERVERNAME},#{USERNAME},#{USERPASS},#{DBNAME}")
#if get an error (can't connect)
rescue
  puts "Unable to connect to database\n"
  if dbh.nil? == false
    dbh.close() 
  end

#if there are no errors
else
  #return the last PID (if there is one)
  pidres = dbh.query("SELECT PID FROM #{TABLENAME} WHERE PID!=NULL")

  #if there is no pid continue normally
  if pidres.nil?
     puts "No PIDs found\n"

  #if there is one, need to locate and end process
  else
     CAT_PID = pidres #need PID number
     puts "PID found: #{CAT_PID}"
     if CAT_PID.alive? == true
       kill CAT_PID #need to change the pidvalue to zero
     end
  end

#parse info from database of last entry
  lastshowchannel = dbh.query("SELECT channel FROM #{TABLENAME} ORDERBY timestamp LIMIT 1")
  lastshowstart = dbh.query("SELECT startTime FROM #{TABLENAME} ORDERBY timestamp LIMIT 1")
  lastshowstop = dbh.query("SELECT stopTime FROM #{TABLENAME} ORDERBY timestamp LIMIT 1")

#close the database
  dbh.close()
end

end
