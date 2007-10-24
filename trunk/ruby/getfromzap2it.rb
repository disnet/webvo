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
conf = conf.gsub(/timezone: \+[0-9]*/,'timezone: ' + zone)

f = File.open(XMLTV_CONFIG,'w')
f.write(conf)
f.close

#this is a hack to make the nil? test work on tvbox, like it does on the Feisty image
#this appears to work on the Feisty image
class XML::Node::Set
    def nil?
        if self.length == 0
            return true
        end
        false
    end
end

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
 
# Class for programme sql entry formatting
class Prog
    def initialize(xmlNode)
        @xmlNode = xmlNode
    end
    def chanID
        Prog.sqlify @xmlNode["channel"]
    end
    def start
        Prog.sqlify @xmlNode["start"][0..13]
    end
    def start_s
        @xmlNode["start"][0..13]
    end
    def stop
        Prog.sqlify @xmlNode["stop"][0..13]
    end
    def stop_s
        @xmlNode["stop"][0..13]
    end
    def title
        Prog.sqlify @xmlNode.find('title').first.content
    end
    def sub_title
        node = @xmlNode.find('sub-title')
        if node.first.nil?
            return "NULL"
        else
            return Prog.sqlify(node.first.content)
        end
    end
    def desc
        node = @xmlNode.find('desc')
        if node.first.nil?
            return "NULL"
        else
            return Prog.sqlify(node.first.child)
        end
    end
    def episode
        @xmlNode.find('episode-num').each {|ep| return Prog.sqlify(ep.content) if ep['system'] == 'onscreen'}
        return "NULL"
    end
    def credits
        node = @xmlNode.find('credits')
        if node.first.nil?
            return "NULL"
        else
            return Prog.sqlify(node.first)
        end
    end
    def category
        cats = String.new
        @xmlNode.find('category').each {|cat| cats += cat.child.to_s + ","}
        Prog.sqlify(cats[0...cats.length-1])
    end
    def xmlNode
        Prog.sqlify @xmlNode
    end
    private
    def Prog.sqlify(node)
        "'" + Mysql.escape_string(node.to_s).gsub("\\n","\n") + "'"
    end
end

system( "tv_grab_na_dd --config-file " + XMLTV_CONFIG + " --output " + XML_FILE_NAME + " --days 14 ")

xmldoc = XML::Document.file(XML_FILE_NAME)

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
    prog = Prog.new(programme)
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
        hours_in(prog.start_s, prog.stop_s).each { |hour|
            query = ("INSERT INTO Listing (channelID, start, showing) VALUES(#{prog.chanID},#{prog.start},'#{hour}')")
            begin
                dbh.query query
            rescue
                LOG.debug("Problem with Listing insert for programme #{prog.title} (already in db?): \n#{query}")
            end
        }
    end
}
dbh.close()
