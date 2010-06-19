#!/usr/bin/python
# Extracts plain text from articles converted into "XML" using wiki2xml_all.
#
# Evan Jones <evanj@mit.edu>
# April, 2008
# Released under a BSD licence.
# http://evanjones.ca/software/wikipedia2text.html

import os
import sys
import commands

import wikisoup

def findXMLIterator(path):
    """Iterates over all .xml files in path."""
    for file in os.listdir(path):
        fullpath = os.path.join(path, file)
        if os.path.isdir(fullpath):
            for i in findXMLIterator(fullpath):
                yield i
        elif fullpath.endswith(".xml"):
            yield fullpath


files = commands.getoutput("find %s -type f | grep '\.xml' " %(sys.argv[1])).split("\n")
dirs= commands.getoutput("find %s -type d" %(sys.argv[1])).split("\n")

if not os.path.exists("out_%s" %(sys.argv[1])):
	os.mkdir("out_%s" %(sys.argv[1]))
	for dir in dirs:
	        path= os.path.join("out_%s" %(sys.argv[1]), dir)
	        if not os.path.exists(path):
	            os.mkdir(path)
								

# Extract the words from all the files in the subdirectories
#for xmlfile in findXMLIterator(sys.argv[1]):
for xmlfile in files:
    print xmlfile
    try:
	filename= os.path.join("out_%s" %(sys.argv[1]), xmlfile)
	output= open(filename, "w")
        output.write(wikisoup.extractWikipediaText(xmlfile).encode("UTF-8"))
	output.close()
    except:
	continue;
        #raise
