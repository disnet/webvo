#!/usr/bin/env ruby

require "mysql"
require "xml/libxml"

def load_config
    config = Hash.new
    File.read('webvo.conf').each { |line|
        line_reg = line.match(/\s*(.*?)\s*=\s*(.*)/)
        config[line_reg[1]] = line_reg[2] unless line_reg.nil?
    }
    return config
end

constants = load_config

XML_FILE_NAME = constants[:XML_FILE_NAME.to_s]
XMLTV_CONFIG = constants[:XMLTV_CONFIG.to_s]
SERVERNAME = constants[:SERVERNAME.to_s]
USERNAME = constants[:USERNAME.to_s]
USERPASS = constants[:USERPASS.to_s]
DBNAME = constants[:DBNAME.to_s]
VIDEO_PATH = constants[:VIDEO_PATH.to_s]
LOG_PATH = constants[:LOG_PATH.to_s]
ENCODER_BIN = constants[:ENCODER_BIN.to_s]
CONFIG_PATH = constants[:CONFIG_PATH.to_s]
FILE_PADDING = constants[:FILE_PADDING.to_i]

LENGTH_OF_DATE_TIME = 14

DEFAULT_LISTING_HOURS = 3

SUPPORTED_ENCODING_SCHEMES= [".mpg", ".avi"]
SUPPORTED_FILE_TYPES = [".mpg", ".avi"]

XML_HEADER = "Content-Type:text/xml\n\n<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<!DOCTYPE tv SYSTEM \"xmltv.dtd\">\n<tv source-info-url=\"http://labs.zap2it.com/\" source-info-name=\"TMS Data Direct Service\" generator-info-name=\"XMLTV\" generator-info-url=\"http://www.xmltv.org/\">"

XML_FOOTER = "</tv>"

JSON_HEADER = "Content-Type:text\n\n"

DATE_FORMAT_STRING = "%Y%m%d"
DATE_TIME_FORMAT_STRING = "%Y-%m-%d_[%H.%i.%S]"
DATE_TIME_FORMAT_STRING_RUBY = "%Y-%m-%d_[%H.%M.%S]"
DATE_TIME_FORMAT_XML= "%Y%m%d%H%i%S"
DATE_TIME_FORMAT_RUBY_XML= "%Y%m%d%H%M%S"

def error_if_not_equal(value, standard, error_string)
  if value != standard:
    puts "<error>Error: " + error_string +"</error>"
    puts XML_FOOTER
    exit
  end
end

def databaseconnect()
    begin
        dbh = Mysql.real_connect(
            "#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
    rescue MysqlError => e
        #log.error("Unable to connect to database. Error code: #{e.errno} Message: #{e.error}")
        puts ("Unable to connect to database. Error code: #{e.errno} Message: #{e.error}")
        puts XML_FOOTER
        exit
    end
    return dbh
end

def databasequery(query_str)
    dbh = databaseconnect()
    begin
        result = dbh.query(query_str)
    rescue MysqlError => e
        #log.error("Error in database query. Error code: #{e.errno} Message: #{e.error}")
        puts "<error>Error in database query. Error code: #{e.errno} Message: #{e.error}</error>"
        puts XML_FOOTER
        exit
    ensure
        dbh.close if dbh
    end
    return result
end

def hours_in (start, stop, return_time = false)
    startTime = formatToRuby(start)
    stopTime = formatToRuby(stop)
    hours = []
    hour = startTime - startTime.min * 60 - startTime.sec
    while hour < stopTime
        if return_time == false
            hours << hour.strftime(DATE_TIME_FORMAT_RUBY_XML)
        else
            hours << hour
        end
        hour += 60 * 60
    end
    return hours
end

def minutes_overlap (start, stop, range_start, range_stop)
    start = range_start if start < range_start
    stop = range_stop if stop > range_stop
    (stop - start).to_i/60
end

def format_filename (name)
    # is '-' a good replacement for the replaced chars in the filename?
    name.gsub(/\/|\\|:|\*|\?|"|<|>/,'-').gsub(/ /, "_")
end

def formatToRuby (xmlform_data)
   return xmlform_data if xmlform_data.instance_of? Time
   year = xmlform_data[0..3].to_i
   month = xmlform_data[4..5].to_i
   day = xmlform_data[6..7].to_i
   hour = xmlform_data[8..9].to_i
   minute = xmlform_data[10..11].to_i
   second = xmlform_data[12..13].to_i
   Time.local(year,month,day,hour,minute,second)
end

#this function finds the available free space on the hard drive
def freespace()
    #runs UNIX free space command
    readme = IO.popen("df #{VIDEO_PATH}")
    space_raw = readme.read
    readme.close 

    #get information from the command line as to how much space is available
    space_match = space_raw.match(/\s(\d+)\s+(\d+)\s+(\d+)/)
    space = Hash.new(0)
    unless space_match.nil?
        space['total'] = space_match[1]
        space['used'] = space_match[2]
        space['available'] = space_match[3]
    end

    return space
end

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
    attr_reader :channel, :size, :start_time, :stop_time
    TIME_FORMAT = "%A %m/%d/%Y %I:%M %p"
    def initialize(xmlNode, channel, size = "0")
        @xmlNode = xmlNode
        @channel = channel
        @size = size

        @start_time = formatToRuby(@xmlNode["start"][0..13])
        @stop_time = formatToRuby(@xmlNode["stop"][0..13])
        set_mysql_output
    end
    def id
        self.chanID + self.start
    end
    def chanID
        format @xmlNode["channel"]
    end
    def past?
        if @stop_time < Time.now
            return true
        else
            return false
        end
    end
    def start
        format @xmlNode["start"][0..13]
    end
    def start_readable
        format @start_time.strftime(TIME_FORMAT)
    end
    def start_s
        @xmlNode["start"][0..13]
    end
    def stop
        format @xmlNode["stop"][0..13]
    end
    def stop_readable
        format @stop_time.strftime(TIME_FORMAT)
    end
    def stop_s
        @xmlNode["stop"][0..13]
    end
    def title
        format @xmlNode.find('title').first.content
    end
    def sub_title
        node = @xmlNode.find('sub-title')
        if node.first.nil?
            return format(nil)
        else
            return format(node.first.content)
        end
    end
    def desc
        node = @xmlNode.find('desc')
        if node.first.nil?
            return format(nil)
        else
            return format(node.first.child)
        end
    end
    def episode
        onscreen_ep = nil
        @xmlNode.find('episode-num').each {|ep| 
            onscreen_ep = ep.content if ep['system'] == 'onscreen' or onscreen_ep.nil?
        }
        format onscreen_ep
    end
    def credits
        format @xmlNode.find('credits').first
    end
    def category
        cats = String.new
        @xmlNode.find('category').each {|cat| cats += cat.child.to_s + ","}
        format (cats[0...cats.length-1])
    end
    def xmlNode
        format @xmlNode
    end
    def set_mysql_output
        @format_block = lambda {|item|
            if item.nil?
                return "NULL"
            else
                "'" + Mysql.escape_string(item.to_s).gsub("\\n","\n") + "'"
            end
        }
        @format_style = "MySQL"
    end
    def set_json_output
        @format_block = lambda {|item| 
            return "&nbsp;" if item.nil?
            item.to_s.gsub(/'/,"&#39;")
        }
        @format_style = "JSON"
    end
    private
    def Prog.sqlify(node)
        if node.nil?
            "NULL"
        else
            "'" + Mysql.escape_string(node.to_s).gsub("\\n","\n") + "'"
        end
    end
    def format(item)
        @format_block.call(item)
    end
end

class List_Output
    CHANNEL = "channels"
    NAME = "names"
    DATETIME = "datetime"
    LISTING = "listing"
    def initialize(type, start = Time.new, stop = Time.new)
        @type = type
        @list = Hash.new
        @start = start
        @stop = stop
        @prog_html = lambda {|prog|
            progclass = prog.past? ? '"programmePast"' : '"programme"'
            progcolspan = '"' + minutes_overlap(prog.start_time, prog.stop_time, @start, @stop).to_s + '"'
            "<td id=\"#{@type}#{prog.id}\" class=#{progclass} colspan=#{progcolspan}>#{prog.title}</td>"
        }
    end
    def add(group, progid)
        unless @list.has_key? group
            @list[group] = Array.new
        end
        @list[group] = @list[group] << progid
    end
    def change_type(type)
        @type = type
    end
    def to_s
        temp_list = Array.new
        if @type == LISTING
            @list.sort{|a,b| a[0].to_i <=> b[0].to_i}.each {|arr|
                temp_list << "<tr><td class=\"channelName\">#{arr[0]}</td>"
                #this assumes that @prog was populated in the proper order
                arr[1].each {|aprog|
                    temp_list << @prog_html.call(aprog)
                }
                temp_list << "</tr>\n"
            }
            temp_list.to_s
        else
            @list.each {|key, val|
                temp_list << "{ '#{key}': [ '#{val.join("','")}'] }"
            }
            retstr = "'#{@type}': [ \n"
            retstr += temp_list.join(",\n") + "]"
        end
    end
end

class JSON_Output
    SEARCH = "search"
    #have to deal with date range to fully implement listing
    LISTING = "listing"
    SCHEDULED = "scheduled"
    RECORDED = "recorded"

    def initialize(type, start = Time.now, stop = Time.new)
        @start = formatToRuby start
        @stop = formatToRuby stop
        @type = type
        type_changed
        @progs = Array.new
        @scheduled = Hash.new
        @recorded = Hash.new
    end
    def add_programme(prog)
        prog.set_json_output
        @progs << prog
    end
    def add_recorded(prog)
        return nil unless @type == SEARCH
        prog.set_json_output
        @recorded[prog.episode + prog.title] = true
    end
    def add_scheduled(prog)
        return nil unless @type == SEARCH
        prog.set_json_output
        key = prog.episode + prog.title
        unless @scheduled.has_key? key
            @scheduled[key] = Array.new
        end
        @scheduled[key] = @scheduled[key] << prog.start_time
    end
    def to_s
        programme_node = Array.new
        programme_html = List_Output.new(List_Output::LISTING, @start, @stop) 
        chan_list = List_Output.new(List_Output::CHANNEL)
        name_list = List_Output.new(List_Output::NAME)
        datetime_list = List_Output.new(List_Output::DATETIME)
        @progs.each {|aprog| 
            programme_node << @progblock.call(aprog)
            chan_list.add(aprog.chanID, aprog.id)
            name_list.add(aprog.title, aprog.id)
            datetime_list.add(aprog.start, aprog.id)
            programme_html.add(aprog.channel, aprog) if @type == LISTING
            #programme_html += @prog_html.call(aprog) if @type == LISTING
        }
        progStr = programme_node.join(",\n")
        @header_html += programme_html.to_s.gsub(/\n/, "") + "</table>',\n" if @type == LISTING

        retstr = "{ 'type': '#{@type}',\n"
        retstr += @header_html
        retstr += "'programmes': [\n"
        retstr += progStr + " ]"

        retstr += ",\n'lists': {\n"
        retstr += chan_list.to_s
        retstr += ",\n" + name_list.to_s
        retstr += ",\n" + datetime_list.to_s
        retstr +=  " \n}\n"

        retstr += "}"
    end
    private
    def get_class(prog)
        prog.set_json_output
        key = prog.episode + prog.title
        if @scheduled.has_key? key
            if @scheduled[key].include? prog.start_time
                return "programme scheduledSearched" 
            else
                return "programme scheduledOtherSearched" 
            end
        elsif @recorded.has_key? key
            return "programme recordedSearched"
        end
        return "programme"
    end
    def type_changed
        @header_html = "'header': '"
        if @type == LISTING
            minutes_in_range = (@stop - @start).to_i/60
            @header_html += "<table id=\"schedule_table\" class=\"schedule_table\"><tr class=\"empty\">"
            (minutes_in_range + 1).times { @header_html += "<td/>" }
            @header_html += "</tr><tr>"
            @header_html += "<th>Ch.</th>"
            hours_in(@start, @stop, true).each {|hour| 
                @header_html += "<th colspan=\"30\">#{hour.strftime("%I:00%p")}</th>"
                @header_html += "<th colspan=\"30\">#{hour.strftime("%I:30%p")}</th>"
            }
            @header_html += "</tr>"
            @progblock = lambda {|prog|
                retstr = "{ 'id':'#{prog.id}',"
                retstr += "'html_id': '#{@type}#{prog.id}',"
                retstr += "'start': '#{prog.start}',"
                retstr += "'stop': '#{prog.stop}',"
                retstr += "'title': '#{prog.title}',"
                retstr += "'sub_title': '#{prog.sub_title}',"
                retstr += "'episode': '#{prog.episode}',"
                retstr += "'desc': '#{prog.desc}' }"
            }
        else
            @header_html += "<tr>"
            @header_html += "<th>Title</th>"
            @header_html += "<th>Episode Title</th>"
            @header_html += "<th>Episode</th>"
            @header_html += "<th>Description</th>"
            @header_html += "<th>Start</th>"
            @header_html += "<th>End</th>"
            @header_html += "<th>Channel</th>"
            @header_html += "<th>Size</th>" if @type == RECORDED
            @header_html += "<th>Checkbox</th>"
            @header_html += "</tr>', \n"

            @progblock = lambda {|prog|
                retstr = "{ 'id':'#{prog.id}',"
                retstr += "'html_id': '#{@type}#{prog.id}',"
                retstr += "'start': '#{prog.start}',"
                retstr += "'stop': '#{prog.stop}',"
                retstr += "'html': '<tr id=\"#{@type}#{prog.id}\" class=\"#{get_class(prog)}\">"
                retstr += "<td>#{prog.title}</td>"
                retstr += "<td>#{prog.sub_title}</td>"
                retstr += "<td>#{prog.episode}</td>"
                retstr += "<td>#{prog.desc}</td>"
                retstr += "<td>#{prog.start_readable}</td>"
                retstr += "<td>#{prog.stop_readable}</td>"
                retstr += "<td>#{prog.channel}</td>"
                retstr += "<td>#{prog.size}</td>" if @type == RECORDED

                #TODO: david, rubyfy this kludge please
                if @type == SEARCH
                    retstr += "<td><input name=\"searchCheck\" type=\"checkbox\" value=\"#{prog.id}\"/></td></tr>' }"
                elsif @type == SCHEDULED
                    retstr += "<td><input type=\"checkbox\" value=\"#{prog.id}\"/></td></tr>' }"
                elsif @type == RECORDED
                    retstr += "<td><input type=\"checkbox\" value=\"#{prog.id}\"/></td></tr>' }"
                else  
                    retstr += "<td><input type=\"checkbox\" value=\"#{prog.id}\"/></td></tr>' }"
                end
            }
        end
    end
end

class PaddedTime
    def PaddedTime.start
        Time.now + load_config["FILE_PADDING"].to_i
    end
    def PaddedTime.stop
        Time.now - load_config["FILE_PADDING"].to_i
    end
    def PaddedTime.strstart
        PaddedTime.start.strftime(DATE_TIME_FORMAT_RUBY_XML)
    end
    def PaddedTime.strstop
        PaddedTime.stop.strftime(DATE_TIME_FORMAT_RUBY_XML)
    end
end

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

#return the show that should currently be recording, or nil
def getNextShow()
    #todo: implement priority checking
    #this query only grabs shows that should currently be recording
    #assume shows do not overlap, just the padded times overlap
    shows = Array.new
    now_showing = "SELECT DATE_FORMAT(start, '#{DATE_TIME_FORMAT_XML}') as start, 
                   DATE_FORMAT(s.stop, '#{DATE_TIME_FORMAT_XML}') as stop, 
                   number, filename, p.xmlNode as xmlNode, channelID, priority
                   FROM Scheduled s JOIN Channel USING (channelID)
                   JOIN Programme p USING(channelID, start)
                   WHERE start <= #{PaddedTime.strstart}
                   AND s.stop > #{PaddedTime.strstop}"
 
    databasequery("SELECT * FROM (#{now_showing}) as sub1
                   WHERE priority = (SELECT max(priority) FROM (#{now_showing}) as sub2 )").each_hash { |show_hash| 
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
