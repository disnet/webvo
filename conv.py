#!/usr/bin/python
import os
MOVIE_PATH='/home/public_html/webvo/movies/'

files = os.listdir(MOVIE_PATH)

for m in files:
    if m[-4:] == '.mpg':
        if os.path.exists(MOVIE_PATH + m[:-4] + '.avi') == False:
            pass1 = 'mencoder %s -o /dev/null -nosound -ovc xvid -xvidencopts aspect=1.3333:pass=1:bitrate=1000' %(m)
            pass2 = 'mencoder %s -o %s.avi -oac mp3lame -lameopts abr:br=128 -ovc xvid -xvidencopts aspect=1.3333:pass=2:bitrate=1000' % (m,m[:-4])
            print "\n\nLOG: %s\n" % pass1
            print "LOG: %s\n\n" % pass2
            os.system(pass1)
            os.system(pass2)
        else:
            print '\n\nSkipping %s because already converted\n\n' % m
