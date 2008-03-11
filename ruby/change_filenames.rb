#!/usr/bin/env ruby

# This should be run when nothing is being recorded
# It renames files to become Windows friendly (and updates the db)
# DMH

require 'util'
require 'logger'

LOG = Logger.new(STDOUT)
LOG.level = Logger::DEBUG

Dir.chdir(VIDEO_PATH)
file_list = Dir["*"]
databasequery("SELECT filename FROM Recorded").each_hash { |recorded|
    show_name = recorded["filename"]

    new_filename = format_filename(show_name)
    unless new_filename == show_name
        LOG.debug "Renaming #{show_name} to #{new_filename} in database"
        databasequery("UPDATE Recorded SET filename = \"#{Mysql.escape_string(new_filename)}\"
                      where filename = \"#{Mysql.escape_string(show_name)}\"")
    end
}

file_list.each { |file|
    new_filename = format_filename(file)
    unless file == new_filename
            LOG.debug "Renaming #{file} to #{new_filename}"
            File.rename(file, new_filename)
    end
}

