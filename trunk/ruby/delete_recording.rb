################################################################################
#WebVo: Web-based PVR
#Copyright (C) 2006 Molly Jo Bault, Tim Disney, Daryl Siu

#This program is free software; you can redistribute it and/or
#modify it under the terms of the GNU General Public License
#as published by the Free Software Foundation; either version 2
#of the License, or (at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program; if not, write to the Free Software
#Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
################################################################################
#delete_recording.rb
#takes a programmeid from the front end and deletes it from the database

require 'date'
require "mysql"

SERVERNAME = "localhost"
USERNAME = "root"
USERPASS = "csc4150"
DBNAME = "WebVoFast"
TABLENAME = "Recording"

PROG_ID = "prog_id"
LENGTH_OF_DATE_TIME = 14
XML_FILE_NAME = "info.xml"

def file_available(file_name)
  cur_dir_entries=Dir.entries(Dir.getwd)
  return cur_dir_entries.include?(file_name)
end
#Error handler
def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts "<error>Error " + error_string +"</error>"
    exit
  end
end

#main--------------------------------------------------------------------------

#checks for 1 argument
  error_if_not_equal(ARGV.length(),1, "Needs 1 arguments")
  
#get argument
  prog_id = ARGV[0]

  error_if_not_equal(prog_id.length > LENGTH_OF_DATE_TIME, true, "Needs a Channel ID")

  date_time = prog_id[(prog_id.length-LENGTH_OF_DATE_TIME).to_i..(prog_id.length-1).to_i]
  chan_id = prog_id[0..(prog_id.length-LENGTH_OF_DATE_TIME-1).to_i]
  
  start_date = date_time[0..7]
  start_time = date_time[8..13]
#error checking
  #Check if times are valid
  error_if_not_equal(start_date.to_i.to_s == start_date, true, "the date time needs to have only numbers in it")
  error_if_not_equal(start_time.to_i < 240000, true, "Time must be millitary time")
  error_if_not_equal(start_time[2..3].to_i < 60 , true, "Minutes must be less than 60")
  
  #Check if dates are valid
  error_if_not_equal(start_date[4..5].to_i <= 12 , true, "Starting month must be <= to 12")
  error_if_not_equal(start_date[6..7].to_i <= 31, true, "Starting month error < 31")
  xmlNode = " "
  have_errored = false
#connect to database
  begin
    dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
  #if gets an error (can't connect)
  rescue MysqlError => e
      error_if_not_equal(false,true, "Error code: " + e.errno + " " + e.error + "\n")
    if dbh.nil? == false
      #close the database
      dbh.close() 
    end
  else
#look up programme in database
    presults = dbh.query("SELECT title FROM Programme WHERE (channelID = '#{chan_id}' AND start = '#{date_time}')")
    rresults = dbh.query("SELECT * FROM Recording WHERE (channelID ='#{chan_id}' AND start = '#{date_time}')")
    reced_results = dbh.query("SELECT * FROM Recorded WHERE (channelID ='#{chan_id}' AND start = '#{date_time}')")
    
#Get the results from queries
    rresult = rresults.fetch_row
    presult = presults.fetch_row
    reced_result = reced_results.fetch_row

    if(rresult == nil)
      puts "<error>Programme not in Recording #{prog_id}</error>\n"
      have_errored = true
    else
	#check to see if process is running
	#check if it has a PID
      pids = dbh.query("SELECT PID From Recording WHERE (channelID = '#{chan_id}' AND start = '#{date_time}')")
      cat_pids = dbh.query("SELECT cat_pid From Recording WHERE (channelID ='#{chan_id}' AND start = '#{date_time}')")
      #if it does kill the process
      pid_info = nil
      pids.each_hash do |row|
	if row != nil && row != "0":
	  pid_info = row
        end
      end
      cat_info = nil
      cat_pids.each_hash do |row|
	if row != nil && row != "0":
	  cat_info = row
        end
      end
      if !(pid_info == nil || pid_info == '0'):        readme = IO.popen("ps -o pid #{cat_info}")
        sleep (0.2)
        temp = readme.gets
        cat_pid = readme.gets
	readme.close

        cat_readme = IO.popen("ps -o cmd #{cat_info}")
        sleep (0.2)
        temp = cat_readme.gets
        cat_cmd = cat_readme.gets
	cat_readme.close

        CAT_PID = cat_info #need PID number
        readme = IO.popen("ps -o pid #{pid_info}")
        sleep (0.2)
        temp = readme.gets
        ruby_pid = readme.gets
	readme.close

        cmd_readme = IO.popen("ps -o cmd #{pid_info}")
        sleep (0.2)
        temp = cmd_readme.gets
        ruby_cmd = cmd_readme.gets
	cmd_readme.close


        if cat_pid != nil && cat_cmd == "cat":
          commandSent = system("kill #{cat_pid}")
 	  if ruby_pid != nil && ruby_cmd == "ruby":
	    commandSent = system("kill #{ruby_pid}")
	  end
	  if (presult != nil && reced_result == nil):
          
            channel_info = dbh.query("SELECT number FROM Channel WHERE channelID ='#{chan_id}' LIMIT 1")
            channel_num = channel_info.fetch_row
            show_info = presult.to_s + "-" + date_time + channel_num.to_s
            dbh.query("INSERT INTO Recorded (channelID,start,ShowName) VALUES ('#{chan_id}', '#{date_time}', '#{show_info}')")
	  end
        end
      end
     #delete the entry from Recording
      dbh.query("DELETE FROM Recording WHERE (channelID = '#{chan_id}' AND start = '#{date_time}')")        
    end
    #See if there is an entry for programme
    if(presult == nil)
      puts "<error>Programme not in Programme #{prog_id}</error>\n"
      have_errored = true
    else
      xmlNode_query = dbh.query("SELECT xmlNode FROM Programme WHERE (channelID = '#{chan_id}' AND start = '#{date_time}')")
      xmlNode = xmlNode_query.fetch_row.to_s
      #if there is an entry, delete it
      if reced_result == nil:
        dbh.query("DELETE FROM Programme WHERE (channelID = '#{chan_id}' AND start = '#{date_time}')")
      end
    end  
  end
  if have_errored == false:
    puts "<success>"
    puts "<prog_id>#{prog_id}</prog_id>"
    xmlNode = xmlNode.gsub("_*_","'")
    puts xmlNode
    puts "</success>"
  end
#closing down standard out
  STDOUT.close()
  STDIN.close()
#call record.rb
  system("ruby record.rb &")
