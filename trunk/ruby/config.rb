#!/usr/bin/env ruby

require 'mysql'
require 'util'

DB_FILE = "Webvo.sql"
STARTUP_FILE = "webvo"
SCRIPT_LOCATION = "/etc/init.d/webvo"
SCRIPT_START = "/etc/rc2.d/S80webvo"
SCRIPT_STOP = "/etc/rc1.d/K10webvo"

#todo: dynamically define the webvo dir in the startup script?

dbh = Mysql.real_connect(
    "#{SERVERNAME}","#{USERNAME}","#{USERPASS}",nil)

# setup database
unless dbh.list_dbs.include?(DBNAME)
    dbh.query("CREATE DATABASE #{DBNAME}")
    dbh.select_db(DBNAME)
    dbSchema = File.read(CONFIG_PATH+DB_FILE).gsub(/--.*/,"")
    dbh.query(dbSchema){}
    #system("mysql --user=#{USERNAME} --password=#{USERPASS} #{DBNAME} < #{CONFIG_PATH+DB_FILE}")
end
dbh.close

# setup record to autorun at computer boot
start_script = File.open(SCRIPT_LOCATION, File::WRONLY|File::TRUNC|File::CREAT)
start_script << File.read(CONFIG_PATH+STARTUP_FILE)
start_script.close
File.symlink(SCRIPT_LOCATION, SCRIPT_START) unless Dir[SCRIPT_START].length > 0
File.symlink(SCRIPT_LOCATION, SCRIPT_STOP) unless Dir[SCRIPT_STOP].length > 0
system(SCRIPT_LOCATION + " start")
