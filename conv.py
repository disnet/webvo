#!/usr/bin/python
import os
MOVIE_PATH='/home/public_html/webvo/movies/'

files = os.listdir(MOVIE_PATH)

for m in files:
    if m[-4:] == '.mpg':
        if os.path.exists(MOVIE_PATH + m[:-4] + '.avi') == False:
            command = 'mencoder %s -o %s.avi -ovc lavc -oac lavc' % (m,m[:-4])
            print "\n\nLOG: %s\n\n" % command
            os.system(command)
        else:
            print '\n\nSkipping %s because already converted\n\n' % m
