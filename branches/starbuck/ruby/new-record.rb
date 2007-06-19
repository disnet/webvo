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

require "mysql"
require "logger"
require "util"

LOG = Logger.new(STDOUT)
LOG.level = Logger::DEBUG

SLEEP_TIME = 1

#calculate the difference between two given dates in seconds
def calcSecUntil(date1,date2)
  date1.to_i - date2.to_i
end

def getNextShow()
    #this is a temp query, as it the final should deal with priority not be "limit 1"
    show_result = databasequery("SELECT DATE_FORMAT(start, '#{DATE_TIME_FORMAT_XML}') as start, 
                                DATE_FORMAT(stop, '#{DATE_TIME_FORMAT_XML}') as stop, 
                                number AS 'channelNumber', 
                                channelID, filename 
                                FROM Scheduled JOIN Channel USING (channelID)
                                ORDER BY start LIMIT 1").fetch_hash
    #next_show = show_result.fetch_hash
    next_show = show_result
    return nil if next_show.nil?
    LOG.debug("The next show to record is #{next_show['filename']}")
    return next_show
end

def isTime(show)
    return false if show.nil?
    show_start = formatToRuby(show['start'])
    show_stop = formatToRuby(show['stop'])
    starts_in = calcSecUntil(show_start,Time.now)
    stops_in = calcSecUntil(show_stop,Time.now)

    LOG.debug("Show starts in: #{starts_in} seconds")
    LOG.debug("Show stops in:  #{stops_in} seconds")

    if (show_start < Time.now) and (show_stop > Time.now)
        return true
    elsif show_stop < Time.now
        unschedule(show['channelID'], show['start'])

        # where should we deal with a show that is over and needs to be removed from Scheduled?
        return false
    end
end

#will this work if the db is already opened?
def unschedule(chan, start)
    LOG.debug("Unscheduling #{chan} - #{start}")
    databasequery("DELETE FROM Scheduled WHERE channelID = '#{chan}' AND start = '#{start}'")
end

while true
    next_show = getNextShow() 
    if isTime(next_show)
        LOG.debug("It is time to start recording...")
    end
    # I think the sleep time should the number of seconds until the next minute
    # assuming we run every 60 sec, which makes sense, I doubt any shows start
    # on a fraction minute, and if they do, does it relaly matter? -dmh
    sleep_time = (SLEEP_TIME - Time.now.sec)
    # this next if is not needed if SLEEP_TIME is 60
    if sleep_time < 0
        sleep_time = SLEEP_TIME
    end
    LOG.debug("Will sleep for #{sleep_time} seconds")
    sleep(sleep_time)
end
