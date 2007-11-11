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

#SUMMARY: Imports information from zap2it.com by using
#"xmltv-0.5.44-win32" a SOAP client from zap2it.com 

# sets the working directory to the directory containing the script
Dir.chdir($0.match(/(.*\/)/)[0])

require 'mysql'
require 'xml/libxml'
require 'util'
require 'logger'

LOG = Logger.new(STDOUT)
LOG.level = Logger::DEBUG

f = File.open(XMLTV_CONFIG,'r')
conf = f.read
f.close

#replace the default zap2it timezone with the local timezone
zone = Time.now.strftime("%z")
conf = conf.gsub(/timezone: [\+|\-][0-9]*/,'timezone: ' + zone)
#conf = conf.gsub(/timezone: \+[0-9]*/,'timezone: +0000')

f = File.open(XMLTV_CONFIG,'w')
f.write(conf)
f.close

# Class for channel sql entry formatting
class Chan
    def initialize(xmlNode)
        @xmlNode = xmlNode
    end
    def id
        Prog.sqlify @xmlNode["id"]
    end
    def id_raw
        @xmlNode["id"]
    end
    def number
        Chan.sqlify @xmlNode.find_first('display-name').content.to_i
    end
    def xmlNode
        Chan.sqlify @xmlNode
    end
    private
    def Chan.sqlify(node)
        "'" + Mysql.escape_string(node.to_s).gsub("\\n","\n") + "'"
    end
end

# this is to get rid of the dd episode number in the filename if there is no onscreen
class Prog
    def episode
        onscreen_ep = nil
        @xmlNode.find('episode-num').each {|ep| 
            onscreen_ep = ep.content if ep['system'] == 'onscreen'
        }
        format onscreen_ep
    end
end

#system( "tv_grab_na_dd --config-file " + XMLTV_CONFIG + " --output " + XML_FILE_NAME + " --days 14 --dropbadchar")

class Thing
    def initialize
    end
    def find thing
        Array.new
    end
end

xmldoc = Thing.new #XML::Document.file(XML_FILE_NAME)

dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")

# Populate database (channels and programmes)
chan_array = Array.new
dbh.query("SELECT channelID FROM Channel").each { |cid| chan_array << cid[0] }

xmldoc.find('channel').each { |e|
    chan = Chan.new(e)
    unless chan_array.include?(chan.id_raw)
        dbh.query("INSERT INTO Channel (channelID, number, xmlNode) VALUES (#{chan.id}, #{chan.number}, #{chan.xmlNode})")
    end
}
xmldoc.find('programme').each { |programme|
    prog = Prog.new(programme, nil)
    # check for specific time
    time_check = dbh.query("SELECT xmlNode, title FROM Programme WHERE start = #{prog.start} and channelID = #{prog.chanID}").fetch_row
    # still need to update is xml data not the same
    if time_check.nil? || time_check[0] != programme.to_s
        LOG.debug("#{prog.title} replacing #{time_check[1]}") unless time_check.nil?
        dbh.query("DELETE FROM Programme WHERE start = #{prog.start} and channelID = #{prog.chanID}")
        # now need to find any overlapping old shows
        dbh.query("SELECT channelID, start FROM Programme WHERE 
            channelID = #{prog.chanID} and
            start < #{prog.stop} and
            #{prog.start} < stop").each { |dead_prog|
            LOG.debug("#{dead_prog[0]} starting at #{dead_prog[1]} overlaps #{prog.title}")
            dbh.query("DELETE FROM Programme WHERE channelID = '#{dead_prog[0]}' and start = '#{dead_prog[1]}'")
        }
        query = ("INSERT INTO Programme (channelID, start, stop, title, `sub-title`, description, episode, credits, category, xmlNode) VALUES(#{prog.chanID},#{prog.start},#{prog.stop},#{prog.title},#{prog.sub_title},#{prog.desc},#{prog.episode},#{prog.credits},#{prog.category},#{prog.xmlNode})")
        dbh.query query
        hours_in(prog.start_time, prog.stop_time).each { |hour|
            query = "INSERT INTO Listing (channelID, start, showing) VALUES(#{prog.chanID},#{prog.start},'#{hour}')"
            begin
                dbh.query query
            rescue MysqlError => e
                LOG.error "Error in database query. Error code: #{e.errno} Message: #{e.error}"
                LOG.error "Problem with Listing insert for programme #{prog.title} (already in db?): \n#{query}" 
            end
        }
    end
}

# update filenames if needed
query = "SELECT channelID, start, xmlNode"
databasequery("SELECT channelID, title, `sub-title`, episode, number, p.xmlNode as xmlNode,
               DATE_FORMAT(start, '#{DATE_TIME_FORMAT_XML}') as start, 
               DATE_FORMAT(p.stop, '#{DATE_TIME_FORMAT_XML}') as stop, 
               DATE_FORMAT(start, '#{DATE_TIME_FORMAT_STRING}') as start_string, 
               DATE_FORMAT(p.stop, '#{DATE_TIME_FORMAT_STRING}') as stop_string,
               filename
               FROM Programme p JOIN Channel USING(channelID)
               JOIN Scheduled USING(channelID, start)").each_hash {|show_row|

    prog = Prog.new(XML::Parser.string(show_row['xmlNode'].to_s).parse, show_row['number'])
    start_string = prog.start_time.localtime.strftime(DATE_TIME_FORMAT_STRING_RUBY)
    #start_string = formatToRuby(show_row['start']).localtime.strftime(DATE_TIME_FORMAT_STRING_RUBY)

    filename = [show_row['title'],show_row['episode'],show_row['sub-title'],start_string,show_row['number']].delete_if{|val| val.nil?}.join("_-_")

    filename = format_filename(filename)

    unless filename == show_row['filename']
        LOG.debug("filename: #{filename} \nreplacing: #{show_row['filename']}")
        filename = Mysql.escape_string(filename)
        setpart = "SET filename = '#{filename}' WHERE channelID = '#{show_row['channelID']}' and start = '#{show_row['start']}'"
        dbh.query("UPDATE Scheduled " + setpart)
        dbh.query("UPDATE Recorded " + setpart)
    end
}

dbh.close()
