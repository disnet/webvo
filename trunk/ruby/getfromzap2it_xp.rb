#getfromzap2it.rb
#Molly Jo Bault
#Imports information from zap2it.com by using
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
  xmltv_ran = system( "xmltv.exe tv_grab_na_dd --output info.xml")
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