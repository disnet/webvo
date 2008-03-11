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

require 'mysql'
require 'util'

puts XML_HEADER

dbh = Mysql.real_connect("#{SERVERNAME}","#{USERNAME}","#{USERPASS}","#{DBNAME}")
dbh.query("SELECT xmlNode FROM Channel").each { |chan|
    puts chan
}
stop_day = dbh.query("SELECT DATE_FORMAT(stop,'#{DATE_FORMAT_STRING}') FROM Programme ORDER BY stop DESC LIMIT 1").fetch_row
#start_day = Time.now.strftime(DATE_FORMAT_STRING)
start_day = dbh.query("SELECT DATE_FORMAT(start,'#{DATE_FORMAT_STRING}') FROM Programme ORDER BY start ASC LIMIT 1").fetch_row
puts "<programme_date_range start='"+ start_day.to_s + "' stop='" + stop_day.to_s + "'></programme_date_range>\n"

puts XML_FOOTER
dbh.close()
