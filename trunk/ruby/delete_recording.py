#!/usr/bin/python
import cgi,sys,os

print "Content-Type:text/xml\n\n"

form = cgi.FieldStorage()
if not form.has_key("prog_id"):
    print "<error>must include programme ID</error>"
    sys.exit()

progID = form["prog_id"].value

t = os.popen('ruby delete_recording.rb ' + progID, 'r')

print t.read()
