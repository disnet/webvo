#!/usr/local/bin/ruby
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
LOG.level = Logger::INFO

SLEEP_TIME = 3

class Show
    attr_reader :channel, :filename, :xmlNode, :channelID, :start_xml
    def initialize(start, stop, channel, xmlNode, filename, channelID)
        @start = formatToRuby(start)
        @start_xml = start
        @stop = formatToRuby(stop)
        @channel = channel
        @xmlNode = xmlNode
        @filename = filename
        @channelID = channelID
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
end

def cleanScheduled
    #todo: deal with padding?
    databasequery "Delete FROM Scheduled WHERE stop < #{Time.now.strftime(DATE_TIME_FORMAT_RUBY_XML)}"
end

#return the show that should currently be recording
def getNextShow()
    #todo: implement priority checking
    #todo: implement padding
    #this query only grabs shows that should currently be recording
    show_result = databasequery("SELECT DATE_FORMAT(start, '#{DATE_TIME_FORMAT_XML}') as start, 
                                DATE_FORMAT(s.stop, '#{DATE_TIME_FORMAT_XML}') as stop, 
                                number, filename, p.xmlNode as xmlNode, channelID
                                FROM Scheduled s JOIN Channel USING (channelID)
                                  JOIN Programme p USING(channelID, start)
                                WHERE start <= #{Time.now.strftime(DATE_TIME_FORMAT_RUBY_XML)}
                                AND s.stop > #{Time.now.strftime(DATE_TIME_FORMAT_RUBY_XML)}")
    next_show = show_result.fetch_hash
    return nil if next_show.nil?
    #LOG.debug("The next show to record is #{next_show['filename']}")
    Show.new(next_show['start'], next_show['stop'], next_show['number'], next_show['xmlNode'], next_show['filename'], next_show['channelID'])
end

def placeInRecorded(show)
    if databasequery("SELECT filename FROM Recorded WHERE channelID = '#{show.channelID}' and start = #{show.start_xml}").fetch_row.nil?
        databasequery("INSERT INTO Recorded (channelID,start,filename) VALUES ('#{show.channelID}', '#{show.start_xml}', '#{Mysql.escape_string(show.filename)}')")
    end
end

def recordShow(show)
    LOG.debug("It is time to start recording #{show.filename} for #{show.stops_in} seconds")
    file_num = Dir["*"].grep(/#{Regexp.escape(show.filename)}/).length/2
    if file_num == 0
        file_end = ""
        File.new(show.filename+".xml", "w").puts show.xmlNode
    else
        file_end = FILE_PART + (file_num+1).to_s
    end
    LOG.info("Recording #{show.filename}#{file_end}")
    Thread.current["rec_pid"] = fork do 
        exec("#{ENCODER_BIN} -c #{show.channel} #{show.stops_in} \"#{VIDEO_PATH}#{show.filename}#{file_end}.mpg\"")
    end
    Process.wait
    LOG.info("Finished #{show.filename}#{file_end}")
end

def stopRecord(thread)
    Process.kill("SIGKILL", thread['rec_pid'] )
end

recording = Hash.new
Dir.chdir(VIDEO_PATH)

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
