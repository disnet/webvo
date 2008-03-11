#!/usr/bin/env ruby

require 'mysql'
require 'util'

DB_FILE = "Webvo.sql"

dbh = Mysql.real_connect(
    "#{SERVERNAME}","#{USERNAME}","#{USERPASS}",nil)

unless dbh.list_dbs.include?(DBNAME)
    dbh.query("CREATE DATABASE #{DBNAME}")
    dbh.select_db(DBNAME)
    dbSchema = File.read(CONFIG_PATH+DB_FILE).gsub(/--.*/,"")
    dbh.query(dbSchema){}
    #system("mysql --user=#{USERNAME} --password=#{USERPASS} #{DBNAME} < #{CONFIG_PATH+DB_FILE}")
end
