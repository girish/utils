import yahoosearch_json
import sys
import os
import simplejson

inputfile= sys.argv[1]
#Input file containing queries

outputfile= sys.argv[2]
#Outputs the results in json format


appid= sys.argv[3]
# Yahoo appid

yahoosearch_json.APP_ID= appid


queries= open(inputfile).readlines()

if len(queries) > 5000:
    print "Query limit Exceeded"
    exit()
    
results= {}

for query in queries:
    query= query.strip()
    print query
    info= yahoosearch_json.search(query)
    	
    if info.has_key('totalResultsAvailable') and info['totalResultsAvailable'] >= 10:
        results[query]= []
        for result in info['Result']:
	    try:	
	            url= ((result["ClickUrl"]).decode("utf-8", "replace")).encode("utf-8", "replace")
	    except:
		    continue;	
		    pass;
            size= -1
            if result.has_key("Cache"):
                size= result['Cache']['Size']
            results[query].append([url, size])
            print url

simplejson.dump(results, open(sys.argv[2], "w"))
