#!/usr/bin/env ruby
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

# sets the working directory to the directory containing the script
Dir.chdir($0.match(/(.*\/)/)[0])

require "mysql"
require "logger"
require "util"

LOG = Logger.new(STDOUT)
LOG.level = Logger::DEBUG

PIDFILE = Dir.getwd + File::SEPARATOR + "record.pid"
pid_file = File.open(PIDFILE, File::RDONLY|File::CREAT)
pid = pid_file.read.to_i
pid_file.close
if pid != 0
    pidread = IO.popen("pidof ruby")
    pids = pidread.read.split(" ")
    pidread.close

    pids.each { |livepid|
        if livepid.to_i == pid
            puts "Error -- WebVo record already running"
            exit
        end
    }
end
pid_file = File.open(PIDFILE, File::WRONLY|File::CREAT|File::TRUNC)
pid_file << Process.pid
pid_file.close

SLEEP_TIME = 3

class Show
    attr_reader :channel, :filename, :xmlNode, :channelID, :start_xml, :start, :stop
    attr_writer :start, :stop
    protected :start, :stop
    def initialize(start, stop, channel, xmlNode, filename, channelID)
        @start = formatToRuby(start) - load_config["FILE_PADDING"].to_i
        @start_xml = start
        @stop = formatToRuby(stop) + load_config["FILE_PADDING"].to_i
        @channel = channel
        @xmlNode = xmlNode
        @filename = filename
        @channelID = channelID
    end
    def notShowing
        return false if @start <= Time.now and @stop > Time.now
        return true
    end
    def starts_in
        @start.to_i - Time.now.to_i
    end
    def stops_in
        @stop.to_i - Time.now.to_i
    end
    def showTimes()
        # starts_in is only used here, it has no use otherwise
        LOG.debug("Show starts in: #{self.starts_in} seconds")
        LOG.debug("Show stops in:  #{self.stops_in} seconds")
    end
    def unpad(after_show)
        newpad = (@stop - after_show.start).to_i/2
        @stop -= newpad
        after_show.start += newpad
    end
end

#this could be done better
def paddedTime(position)
    return (Time.now + load_config["FILE_PADDING"].to_i).strftime(DATE_TIME_FORMAT_RUBY_XML) if position == "start"
    return (Time.now - load_config["FILE_PADDING"].to_i).strftime(DATE_TIME_FORMAT_RUBY_XML) if position == "stop"
end

def cleanScheduled
    databasequery "Delete FROM Scheduled WHERE stop < #{paddedTime("stop")}"
end

#return the show that should currently be recording, or nil
def getNextShow()
    #todo: implement priority checking
    #this query only grabs shows that should currently be recording
    #assume shows do not overlap, just the padded times overlap
    shows = Array.new
    databasequery("SELECT DATE_FORMAT(start, '#{DATE_TIME_FORMAT_XML}') as start, 
                   DATE_FORMAT(s.stop, '#{DATE_TIME_FORMAT_XML}') as stop, 
                   number, filename, p.xmlNode as xmlNode, channelID
                   FROM Scheduled s JOIN Channel USING (channelID)
                   JOIN Programme p USING(channelID, start)
                   WHERE start <= #{paddedTime("start")}
                   AND s.stop > #{paddedTime("stop")}").each_hash { |show_hash| 
        shows << Show.new(show_hash['start'], 
                          show_hash['stop'], 
                          show_hash['number'], 
                          show_hash['xmlNode'], 
                          show_hash['filename'], 
                          show_hash['channelID'])
    }
    return nil if shows.length == 0
    if shows.length > 1
        #we have adjacent shows, or at least close enough so they overlap when padded
        shows.sort! {|a,b| a.starts_in <=> b.starts_in }
        (1...shows.length).each {|pos|
            shows[pos-1].unpad(shows[pos])
        }
        shows.delete_if { |show| show.notShowing }
    end
    #LOG.debug("The next show to record is #{shows[0].filename}")
    shows[0]
end

def placeInRecorded(show)
    if databasequery("SELECT filename FROM Recorded WHERE channelID = '#{show.channelID}' and start = #{show.start_xml}").fetch_row.nil?
        databasequery("INSERT INTO Recorded (channelID,start,filename) VALUES ('#{show.channelID}', '#{show.start_xml}', '#{Mysql.escape_string(show.filename)}')")
    end
end

def recordShow(show)
    LOG.debug("It is time to start recording #{show.filename} for #{show.stops_in} seconds")
    File.open(load_config["VIDEO_PATH"] + File::SEPARATOR + show.filename+".xml", File::WRONLY|File::TRUNC|File::CREAT) { |file| file << show.xmlNode }
    LOG.info("Recording #{show.filename}")
    # the append can cause problems, the file may stop plaing part way through, but you can still jump to the end parts
    outfile = File.open(load_config["VIDEO_PATH"] + File::SEPARATOR + show.filename+".mpg", File::WRONLY|File::APPEND|File::CREAT )
    system("ivtv-tune -c#{show.channel}")
    videoin = IO.popen("cat /dev/video0", "r")
    Thread.current["rec_pid"] = videoin.pid
    videoin.each {|part| outfile << part }
    outfile.close
    videoin.close
    LOG.info("Finished #{show.filename}")
end

def stopRecord(thread)
    LOG.debug("killing pid #{thread['rec_pid']}")
    Process.kill("SIGTERM", thread['rec_pid'] ) unless thread['rec_pid'].nil?
    thread.join
end

recording = Hash.new

trap("SIGTERM") {
    LOG.info("Exiting program")
    recording.each_value { |thread| stopRecord thread }
    File.open(PIDFILE, File::WRONLY|File::TRUNC).close
    exit
}

trap("SIGINT") { Process.kill("SIGTERM", Process.pid) }

while true
    next_show = getNextShow()
    recording.delete_if { |filename, thread| !thread.alive? }
    unless next_show.nil?
        unless recording.has_key?(next_show.filename)
            recording.each_value { |thread| stopRecord thread }
            recording[next_show.filename] = Thread.new(next_show) { |show| recordShow(show) }
            placeInRecorded(next_show)
        end
    else
        recording.each_value { |thread| stopRecord thread }
    end
    # I think the sleep time should the number of seconds until the next minute
    # assuming we run every 60 sec, which makes sense, I doubt any shows start
    # on a fraction minute, and if they do, does it relaly matter? -dmh

    cleanScheduled()

    sleep_time = SLEEP_TIME - Time.now.sec
    sleep_time = SLEEP_TIME if sleep_time <= 0
    #usec not needed in final? (that would mean that we are only ever off by 1 sec)
    #  as well as not having to force quit recording when two shows are adjacent
    sleep_time -= Time.now.usec/1000000.0
    LOG.debug("Will sleep for #{sleep_time} seconds")
    sleep(sleep_time)
end
