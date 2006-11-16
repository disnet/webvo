#Daryl Siu
#Write to the recorder in Ruby

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

#begin recording script

if __FILE__ == $0
  show = RecordedShow.new(20061028100,13,100,200)
  
  #calculate when recording show starts  
  puts "Recording channel #{show.channel} from #{show.starttime} to #{show.stoptime}."
  
  #tune the card to the correct channel
  commandSent = System ("ivtv -tune -c #{show.channel}")
  if commandSent != true
    puts "Channel set failed\n"
  end
  
  #start the recording
  commandSent = System ("cat /dev/video0 > #{show.showID}.mpg")
  CAT_PID = $! #keeps track of last job ID number
  if commandSent != true
    puts "Recording failed to start\n"
  end
  #sleep for length of the show
  sleep (60)

  #stop the recording
  kill CAT_PID if CAT_PID.alive? = true
  
end
