import urllib2
import urllib
try:
    import json
except ImportError:
    import simplejson as json


class BingException(Exception):
    pass

class Bing(object):
    def __init__(self, app_id):
        self.app_id = app_id
        self.end_point = 'http://api.search.live.net/json.aspx?Appid=%s&sources=web&'%app_id
                
    def search(self, query, cc='in'):
        query = urllib.quote_plus(query)
        final_url= self.end_point + "query=%s&cc=%s" %(query, cc)
        print final_url
        response = urllib.urlopen(final_url)
        data = json.load(response)
        if 'Errors' in data['SearchResponse']:
            data = data['SearchResponse']
            errors_list = [el['Message'] for el in data['Errors']]
            error_text = ','.join(errors_list)
            raise BingException(error_text)
        return data