# -*- coding: utf-8 -*-
import simplejson
import sys
import os
import commands
import codecs

inputdir= sys.argv[1]
#Input directory containing all the urls in json format

outputfile= codecs.open(sys.argv[2], "w", "utf-8")

files= commands.getoutput("find %s -type f" %(inputdir)).split("\n")

allURLS= {}
for file in files:
    print file;
    output= simplejson.load(open(file))
    for (query, results) in output.items():
        for result in results:
            if not allURLS.has_key(result[0]):
                allURLS[result[0]]= result[1]

items= allURLS.items()

#items.sort()

for (url, size) in items:
    outputfile.write("%s\t%s\n" %(url, size))

outputfile.close()
