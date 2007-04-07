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
#form_space.rb
#returns the amount of space on the hard drive and how much is free

require "cgi"

f = File.new('webvo.conf','r')
conf = f.read
f.close

video_path = conf.match(/(\s*VIDEO_PATH\s*)=\s*(.*)/)
VIDEO_PATH = video_path[2]

  puts "Content-Type:text/xml\n\n"

  #runs UNIX free space command
  readme = IO.popen("df #{VIDEO_PATH}")
  space_raw = readme.read
  readme.close 
  
  #gets information from the command line as to how much space is available
  space_match = space_raw.match(/\s(\d+)\s+(\d+)\s+(\d+)/)
  total = space_match[2]
  available = space_match[3]

  puts "<tv>"
  puts "<available>" + available.to_s + "</available>"
  puts "<total>" + total.to_s + "</total>"
  puts "</tv>"
