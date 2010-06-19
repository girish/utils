#!/usr/bin/env python

import sys
import os
import simplejson
import urllib
from mybingapi import *
import pickle

inputfile= sys.argv[1]
#Input file containing queries

outputfile= sys.argv[2]
#Outputs the results in json format

bing = Bing('773ABCCFE034C503D0E9DE0FD0B88F06D6815214');
#This apid is dedicated to this program.

countryCode= sys.argv[3]

queries= open(inputfile).readlines()

if len(queries) > 10000:
    print "Query limit Exceeded"
    exit()
    
scores= {}

for query in queries:
    query= query.strip()
    print query
    info= bing.search(query, countryCode)
    scores[query]= info['SearchResponse']['Web']['Total']
    print scores[query]
    
pickle.dump(scores, open(sys.argv[2], "w"))
#simplejson.dump(scores, open(sys.argv[2], "w"))
