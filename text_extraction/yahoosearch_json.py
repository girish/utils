import urllib2
import urllib
try:
    import simplejson
except ImportError:
    import json as simplejson

# -*- coding: utf-8 -*-
#APP_ID = 'YahooDemo' # Change this to your API key
APP_ID = 'nRxvOEbV34Goib6H_FariToHJcjhtiezBQBZ2_SuLZtPx9Ic2odPP0YycLLuj4IRU8BIsA--' # Change this to your API key
SEARCH_BASE = 'http://search.yahooapis.com/WebSearchService/V1/webSearch'

class YahooSearchError(Exception):
    pass

def search(query, results=10, start=1, **kwargs):
    kwargs.update({
        'appid': APP_ID,
        'query': query,
        'results': results,
        'start': start,
        'output': 'json'
    })
    url = SEARCH_BASE + '?' + urllib.urlencode(kwargs)
    print url
    result = simplejson.load(urllib.urlopen(url))
  	
    if 'Error' in result:
        # An error occurred; raise an exception
        #raise YahooSearchError, result['Error']
	null={}
	null['totalResultsAvailable']=0;
	return null ;
    else:
	return result['ResultSet']

if __name__=="__main__":
    info = search('avinesh')
    print info['totalResultsAvailable']
