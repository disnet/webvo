#!/usr/local/bin/ruby

#Daryl Siu
#Second attempt at writing out commands to Ruby

require "mysql"

SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
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
  res = dbh.query("SELECT PID FROM Recording WHERE PID!=0")
  row = res.fetch_row
  pidres = row[0]

  #if there is no pid continue normally
  if pidres.nil?
     puts "No PIDs found\n"

  #if there is one, need to locate and end process
  else
     CAT_PID = pidres #need PID number
     puts "PID found: #{CAT_PID}"
     readme = IO.popen("ps #{CAT_PID}")
     sleep(1)
     temp = readme.gets
     pid = readme.gets
     if pid != "NULL"
       commandSent = system("kill #{CAT_PID}")
     end
  end   
 end

#parse info from database of last entry
#initialize queries
  channelIDquery = "SELECT ChannelID FROM Recording ORDER BY Start LIMIT 1"
  startIDquery = "SELECT Start FROM Recording ORDER BY Start LIMIT 1"
  lastshowstart = dbh.query("#{startIDquery}")
  lastshowchannel = dbh.query("SELECT number FROM Channel WHERE ChannelID = (#{channelIDquery})")
  lastshowstop = dbh.query("SELECT STOP FROM Programme WHERE(ChannelID=(#{channelIDquery})AND Start =(#{startIDquery}))")

#change vals to numbers
  startrow = lastshowstart.fetch_row
  channelrow = lastshowchannel.fetch_row
  stoprow = lastshowstop.fetch_row
  puts "The show to be recorded is on channel #{channelrow[0]}, starts at #{startrow[0]} and ends at #{stoprow[0]}."

#close the database
  dbh.close()
end
