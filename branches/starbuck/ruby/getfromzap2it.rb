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
require 'date'

f = File.open(XMLTV_CONFIG,'r')
conf = f.read
f.close

#replace the default zap2it timezone with the local timezone
zone = DateTime.now.zone
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

system( "tv_grab_na_dd --config-file " + XMLTV_CONFIG + " --output " + XML_FILE_NAME)

xmldoc = XML::Document.file(XML_FILE_NAME)

dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")

# Populate database (channels and programmes)
chan_array = Array.new
dbh.query("SELECT channelID FROM Channel").each { |cid| chan_array << cid[0] }

xmldoc.find('channel').each { |e|
    chan_id = e["id"].to_s
    chan_number = e.find_first('display-name').content.to_i
    if !chan_array.include?(chan_id)
        dbh.query("INSERT INTO Channel (channelID, number, xmlNode) VALUES ('#{chan_id}', '#{chan_number}', '#{e}')")
    end
}
xmldoc.find('programme').each { |programme|
    prog = Prog.new(programme)
    query = ("SELECT channelID, start FROM Programme WHERE start = #{prog.start} and channelID = #{prog.chanID}")
    if dbh.query(query).fetch_row.nil?
        query = ("INSERT INTO Programme (channelID, start, stop, title, `sub-title`, description, episode, credits, category, xmlNode) VALUES(#{prog.chanID},#{prog.start},#{prog.stop},#{prog.title},#{prog.sub_title},#{prog.desc},#{prog.episode},#{prog.credits},#{prog.category},#{prog.xmlNode})")
        dbh.query query
        hours_in(prog.start_s, prog.stop_s).each { |hour|
            query = ("INSERT INTO Listing (channelID, start, showing) VALUES(#{prog.chanID},#{prog.start},'#{hour}')")
            dbh.query query
        }
    end
}
dbh.close()
