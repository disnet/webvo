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

#SUMMARY: Imports information from zap2it.com by using
#using "xmltv-0.5.44-win32" a SOAP client
#from zap2it.com 


require 'date'

#opening/creating log file
logfile = File.new("logfile.txt", "a")

#make sure xmltv.exe in current directory
#cur_dir_entries=Dir.entries(Dir.getwd)
xmltv_pres = true

#xmltv_pres = cur_dir_entries.include?("xmltv.exe")

#Get xmltv data
before_run_time = Time.new
after_run_time = Time.new
xmltv_ran = false

if xmltv_pres == true then 
  before_run_time = Time.new
  xmltv_ran = system( "tv_grab_na_dd --output info.xml")
end
after_run_time = Time.new
if xmltv_ran == true then
  logfile << "Download Started " << before_run_time << "\n"
  logfile <<"Download Finished" << after_run_time<< "\n"

else
  logfile << "xmltv.exe failed to run at " << after_run_time << "\n" 
  
  if xmltv_pres == false then
    logfile << "xmltv.exe not current directory\n"
  end
  
end



parsing_xml_ran = system("ruby parsing_xml.rb")

if parsing_xml_ran == true:
  logfile << "Parsing_xml ran successfully at " + DateTime.now + "\n"
  
else
  logfile << "Parsing_xml ran unsuccessfully.\n"
end


logfile << "\n\n"
logfile.close()
