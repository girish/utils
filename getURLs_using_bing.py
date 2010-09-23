#!/usr/bin/env python

import sys
import os
import simplejson
import urllib
from mybingapi import *

inputfile= sys.argv[1]
#Input file containing queries

outputfile= sys.argv[2]
#Outputs the results in json format


appid= sys.argv[3]
# Bing appid

bing = Bing(sys.argv[3]);

countryCode= sys.argv[4]
language= sys.argv[4]
queries= open(inputfile).readlines()

if len(queries) > 10000:
    print "Query limit Exceeded"
    exit()
    
results= {}

for query in queries:
    query= query.strip()
    query = "%s language:%s"%(query,language)
    print query
    try:
    	#info= bing.search(query, countryCode)
    	info= bing.search(query)
    except:
        print 'some error'
    
    if info['SearchResponse']['Web']['Total'] >= 10:
        results[query]= []
        results_list= info['SearchResponse']['Web']['Results']
        for result in results_list:
            url= result['Url']
            size= -1
            results[query].append([url, size])
            #print url

simplejson.dump(results, open(sys.argv[2], "w"))
