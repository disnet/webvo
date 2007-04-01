#!/usr/local/bin/ruby

#Daryl Siu
#Write to the recorder in Ruby

require "date"
require "mysql"


SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVoFast"
TABLENAME = "Recording"
VIDEO_PATH = "/home/public_html/webvo/movies/"
LOG_PATH = "../logs/"

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

def logInfo(m)
    log = File.open(LOG_PATH + "recordlog.txt","a")
    log << "(#{Time.now}) #{m}\n"
    log.close()
end

#change from xml form of the date to the dateTime form
def format_to_Ruby (xmlform_data)
   year = xmlform_data[0..3].to_i
   month = xmlform_data[4..5].to_i
   day = xmlform_data[6..7].to_i
   hour = xmlform_data[8..9].to_i
   minute = xmlform_data[10..11].to_i
   second = xmlform_data[12..13].to_i
   result = DateTime.new(year,month,day,hour,minute,second,DateTime.now.offset)#,2361222)
   return result
end

#connect to the database
def databaseconnect()
  dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
  return dbh
end

#find the process number given process name
def findProcessNum(procCat)
  readme = IO.popen("ps -C #{procCat} -o pid")
  sleep (1)
  temp = readme.gets
  pid = readme.gets
  readme.close()
  return pid
end

#find the category name of the process
def findProcCat(procNum)
  readme = IO.popen("ps -o cmd #{procNum}")
  sleep (1)
  temp = readme.gets
  cmd = readme.gets
  readme.close()
  return cmd
end

#find process number given the number
def findProcNum(procNum)
  readme = IO.popen("ps #{procNum}")
  sleep (1)
  temp = readme.gets
  pid = readme.gets
  readme.close()
  return pid
end

#look for show of this name
def findname(id)
  readme = IO.popen("ls #{VIDEO_PATH}#{id}.mpg")
  sleep(1)
  check = readme.gets
  readme.close()
  return check
end

#calculate the difference between two given dates in seconds
def calcTimeTo(date1,date2)
  diffstop = date1 - date2
  sh,sm,ss,sfrac = Date.day_fraction_to_time(diffstop)
  diffstopInS = (sh)*3600 + (sm)*60 + ss
  return diffstopInS
end

#if a process exists kill it
def killifrunning(pidres,dbcolumn)

  #retrieve pid number and command name from process scheduler   
     pid = findProcNum(pidres)
     cmd = findProcCat(pidres)
     
     dbh = databaseconnect()

  #if not found as actually running,remove from database
     if pid == nil
       logInfo("Process not running")
       dbh.query("UPDATE Recording SET #{dbcolumn} = '' WHERE #{dbcolumn} = '#{pidres}'")
       dbh.query("UPDATE Recording SET CMD = '' WHERE #{dbcolumn} = '#{pidres}'")
       dbh.close()
       return 0
     #if is found to be running, need to confirm that isn't most recent program or a random process that happens to have the same PID number
     else
       logInfo("Process running")

       #return PID and command of closest upcoming show
       row = dbh.query("SELECT #{dbcolumn} FROM Recording ORDER BY start LIMIT 1")
       processNum = row.fetch_row[0]
       row = dbh.query("SELECT CMD FROM Recording ORDER BY start LIMIT 1")
       command = row.fetch_row

       #if does return number and the commands are the same from both process scheduler and the database
       if processNum.to_i == 0
         commandSent = system("kill #{pidres}")
       #update database
         dbh.query("UPDATE Recording SET #{dbcolumn} = '' WHERE #{dbcolumn} = '#{pidres}'")
         dbh.query("UPDATE Recording SET CMD = '' WHERE #{dbcolumn} = '#{pidres}'")
       #indicate that it killed it
         dbh.close()
         return 1
        #otherwise leave it alone, wait for it to finish
       else
        dbh.close()
         return 2
       end 
     end
end

#begin recording script
if __FILE__ == $0

#connect to the mysql server
begin
  dbh = databaseconnect()
#if get an error (can't connect)
rescue MysqlError => e
  logInfo("Error code: #{e.errno}")
  logInfo("Error message: #{e.error}")
  logInfo("Unable to connect to database")
  if dbh.nil? == false
    dbh.close() 
  end
  exit

#if there are no errors
else
  
  #make sure there are shows to record
  showcheck = dbh.query("SELECT Start FROM Recording ORDER BY Start")  
  noshowcheck = showcheck.fetch_row
   logInfo("--------------------------------------------")
   logInfo("(main) Next show to record: #{noshowcheck}")
  if noshowcheck == nil
    logInfo("(main) No shows to record")
    dbh.close()
    exit
  end

  #return the last PID (if there is one)
  pidrow = dbh.query("SELECT sleep_pid FROM Recording WHERE sleep_pid > 0")
  pidres = pidrow.fetch_row
    dbh.close()
#if there is no pid continue normally
  killed = 0
  if pidres == nil || pidres[0].to_i == 0
     logInfo("(main)No PIDs found")
  else
#kill the sleep_pid if it exists
    logInfo("(main)PID found: #{pidres}")
    killed = killifrunning(pidres[0],"sleep_pid")
  end
  
  if killed == 2
    logInfo("(main)Process not killed, wait for finish recording")
    exit
  else if killed == 1
    logInfo("(main)Process killed")
  else
    logInfo("(main)Process not actually running")
  end
end

#parse info from database of last entry
  logInfo("(main)Begin DB Query")

  dbh = databaseconnect()
  channelIDquery = "SELECT channelID FROM Recording ORDER BY start LIMIT 1"
  lastshowstart = dbh.query("SELECT start FROM Recording ORDER BY start LIMIT 1")
  lastshowchannel = dbh.query("SELECT number FROM Channel WHERE channelID = (#{channelIDquery})")
  lastshowstop = dbh.query("SELECT stop FROM Programme WHERE(channelID=(#{channelIDquery}) AND start=(SELECT start FROM Recording ORDER BY start LIMIT 1))")
  lastshowtitle = dbh.query("SELECT title FROM Programme WHERE (channelID=(#{channelIDquery})AND start =(SELECT start FROM Recording ORDER BY start LIMIT 1))")
#done with DB for now
  dbh.close()

#change vals to numbers
  startrow = lastshowstart.fetch_row
  channelrow = lastshowchannel.fetch_row
  stoprow = lastshowstop.fetch_row
  title = lastshowtitle.fetch_row
  
#initialize values of show  
  showStartDate = format_to_Ruby("#{startrow}")
  showStopDate = format_to_Ruby("#{stoprow}")
  currDate = DateTime.now
  show = RecordedShow.new("#{title}-#{startrow}#{channelrow}",channelrow,startrow,stoprow)
  logInfo("(main)Initializing show title, date")
  logInfo("(main)showID:#{show.showID}")
#calc if show has been missed
  diffstop = calcTimeTo(showStopDate,currDate)
 
#calc show length in seconds
  showlength = calcTimeTo(showStopDate,showStartDate)

#calculate when recording show starts
  sleeptime = calcTimeTo(showStartDate,currDate)

#if the show started already and is over
  if diffstop < 0
    logInfo("Sorry, the time has passed for this show")
    dbh = databaseconnect()
    dbh.query("DELETE FROM Recording WHERE start = #{startrow}")


    dbh.close()
    commandSent = system("ruby record.rb &")
    exit
  end
#if the show is still going, set the length of the show to the amount of time left
  if diffstop < showlength
    showlength = diffstop
  end

#if the show hasn't started yet
  if sleeptime > 0
    hours = sleeptime/3600
    minutes = (sleeptime%3600)/60
    seconds = minutes%60

#send CAT_PID and command to database (need to reopen database)
    sleepProcNum = Process.pid
    dbh = databaseconnect()
    dbh.query("UPDATE Recording SET sleep_pid = #{sleepProcNum} WHERE Start = #{startrow}")
    dbh.query("UPDATE Recording SET CMD = 'ruby' WHERE Start = #{startrow}") 
    dbh.close()
    
#go to sleep
    logInfo("(main)SLEEP:The show will start in #{hours.to_i} hours, #{minutes.to_i} minutes and #{seconds.to_i} seconds.")
    sleep (sleeptime)
  end

#if the show exists, need to change the name to have a partII denotation
#check recorded shows to see if show exists already
    dbh = databaseconnect()
    duperes = dbh.query("SELECT ShowName FROM Recorded WHERE ShowName = '#{title}-#{startrow}#{channelrow}'")
    duperecord = duperes.fetch_row
    lastchar = 0
#if does return a result, change the final digit
    if !duperecord.nil? 
#increment to next number
       while findname(show.showID + '-' + lastchar.to_s) != nil
         lastchar += 1
       end
    end
    show.showID << '-' << lastchar.to_s
    dbh.close()

#if here, begin recording immediately  
#tune the card to the correct channel
      logInfo("(main)Tunning...")
      commandSent = IO.popen("whoami")
      output = commandSent.gets
      logInfo("Chanel is #{output}")
    commandSent = system("perl ptune.pl -c #{show.channel}")
#    commandSent = IO.popen("ivtv-tune -c #{show.channel}")
    
    if commandSent == false
      logInfo("(main)Failed to tune channel: #{show.channel}")
#      exit
    end
  
#start the recording
    logInfo("(main)Recording channel #{show.channel} from #{show.starttime} to #{show.stoptime}")
    #check and make sure a cat process is not already running
    dbh = databaseconnect()
    temp = dbh.query("SELECT cat_pid FROM Recording WHERE cat_pid > 0")
    catFound = temp.fetch_row
    #if it is, exit
    if catFound != nil 
       hold = findProcNum(catFound[0])
       if hold != nil
        logInfo("(main)Cat already running")
        exit
       else 
        dbh.query("UPDATE Recording SET cat_pid = '' WHERE cat_pid = '#{catFound}'")
       end
    end
    dbh.close()
    catProcNum = fork do
        src = File.open("/dev/video0",'r')
        vid = File.open("#{VIDEO_PATH}#{show.showID}.mpg",'w')
        while (true) 
          vid.write(src.read(4))
        end
	exit
    end
    
#send CAT_PID and command name to database (need to reopen database)
    dbh = databaseconnect()
    dbh.query("UPDATE Recording SET cat_pid = '#{catProcNum}' WHERE Start = '#{startrow}'")

#move the show from the recording list to recorded list
    #get the channel ID
    transferquery = dbh.query("#{channelIDquery}")
    chanID = transferquery.fetch_row

    #check the show name from Recorded to see if entry exists already
    res = dbh.query("SELECT ShowName FROM Recorded WHERE ShowName = '#{title}-#{startrow}#{channelrow}'")
    namecheck = res.fetch_row
    #if it doesn't and no key exists for that show already, insert into record, otherwise leave it alone
    if namecheck == nil && duperecord.nil?
     dbh.query("INSERT INTO Recorded (channelID,start,ShowName) VALUES ('#{chanID}', '#{startrow}', '#{title}-#{startrow}#{channelrow}')")
    end

#sleep for length of the show
   logInfo("(main)Going to sleep for the show: #{showlength}") 
   sleepProcNum = Process.pid
   dbh.query("UPDATE Recording SET sleep_pid = #{sleepProcNum} WHERE Start = #{startrow}")
   dbh.query("UPDATE Recording SET CMD = 'ruby' WHERE Start = #{startrow}") 

   dbh.close()
   sleep (showlength)

#stop the recording
   logInfo("(main)Going to kill the show: #{catProcNum}")
   commandSent = IO.popen("kill #{catProcNum}")
   hold = commandSent.gets
   commandSent.close()
   logInfo("Killed the show:  #{hold}") 

#remove PID from recording
    dbh = databaseconnect()
    dbh.query("DELETE FROM Recording WHERE cat_pid = #{catProcNum}")
#close the database
    dbh.close()

#start next recording check
    logInfo("(main)Locating next show to record")
    commandSent = system("ruby record.rb &")
    exit
  end
end
