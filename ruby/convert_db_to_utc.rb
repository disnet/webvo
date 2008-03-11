#!/usr/bin/env ruby

require 'util'
#need to make sure db has proper foreign key "restraints"
puts "Setting up foreign keys"
queries = Array.new

queries << "ALTER TABLE Recorded DROP FOREIGN KEY Recorded_ibfk_1"
queries << "ALTER TABLE Recorded ADD FOREIGN KEY(channelID, start) REFERENCES Programme(channelID, start) ON UPDATE CASCADE"

queries << "ALTER TABLE Scheduled DROP FOREIGN KEY Scheduled_ibfk_1"
queries << "ALTER TABLE Scheduled ADD FOREIGN KEY(channelID, start) REFERENCES Programme(channelID, start) ON UPDATE CASCADE"

queries << "ALTER TABLE Listing DROP FOREIGN KEY Listing_ibfk_1"
queries << "ALTER TABLE Listing ADD FOREIGN KEY(channelID, start) REFERENCES Programme(channelID, start) ON DELETE CASCADE ON UPDATE CASCADE"

queries << "ALTER TABLE Programme DROP FOREIGN KEY Programme_ibfk_1"
queries << "ALTER TABLE Programme ADD FOREIGN KEY(channelID) REFERENCES Channel(channelID) ON DELETE CASCADE ON UPDATE CASCADE"

dbh = databaseconnect

queries.each {|query|
    puts "Executing:", query
    begin
        dbh.query query
        puts dbh.query("show warnings").each{|warn| puts warn} if dbh.warning_count > 0
    rescue MysqlError => e
        puts "Error in database query. Error code: #{e.errno} Message: #{e.error}"
    end
}

unless dbIsUtc
    puts "converting db"
    query = "SELECT channelID, 
             DATE_FORMAT(start, '#{DATE_TIME_FORMAT_XML}') as start, 
             DATE_FORMAT(stop, '#{DATE_TIME_FORMAT_XML}') as stop, 
             xmlNode from Programme ORDER BY start DESC"
    dbh.query(query).each {|result| 
        chanID = result[0]
        start = result[1]
        stop = result[2]
        prog = Prog.new(XML::Parser.string(result[3].to_s).parse, nil)
        prog.set_mysql_output
        query = "UPDATE Programme SET start = #{prog.start}, stop = #{prog.stop} WHERE channelID = #{prog.chanID} and start = '#{start}'"
        begin
            dbh.query query
            puts dbh.query("show warnings").each{|warn| puts warn} if dbh.warning_count > 0
        rescue MysqlError => e
            if e.errno == 1062
                # this assumes that if the updated row would be a duplicate that it has no references in Scheduled and Recorded
                query = "DELETE FROM Programme WHERE channelID = #{prog.chanID} and start = '#{start}'"
                retry
            else
                puts "Error in database query:\n#{query}\n Error code: #{e.errno} Message: #{e.error}"
                puts "Conversion incomplete"
                exit
            end
        end

        query = "DELETE FROM Listing WHERE channelID = #{prog.chanID} and start = #{prog.start}"
        dbh.query query

        hours_in(prog.start_time, prog.stop_time).each { |hour|
            query = ("INSERT INTO Listing (channelID, start, showing) VALUES(#{prog.chanID},#{prog.start},'#{hour}')")
            #query = "UPDATE Listing SET showing = '#{hour}' WHERE channelID = #{prog.chanID} and start = #{prog.start}"
            begin
                dbh.query query
            rescue MysqlError => e
                puts "Error in database query:\n#{query}\n Error code: #{e.errno} Message: #{e.error}"
                exit
            end
        }
        GC.start
    }

    puts "converted db"
end

# delete foreign keys because they cause problems with getfromzap2it deleting a 
# programme that is scheduled

queries = Array.new

queries << "ALTER TABLE Recorded DROP FOREIGN KEY Recorded_ibfk_1"
queries << "ALTER TABLE Scheduled DROP FOREIGN KEY Scheduled_ibfk_1"

queries.each {|query|
    puts "Executing:", query
    begin
        dbh.query query
        puts dbh.query("show warnings").each{|warn| puts warn} if dbh.warning_count > 0
    rescue MysqlError => e
        puts "Error in database query. Error code: #{e.errno} Message: #{e.error}"
    end
}

dbh.close
