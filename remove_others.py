import sys
import re
import codecs

filestring= codecs.open(sys.argv[1], encoding="UTF-8").read()
start=u"\u0B80"
end=u"\u0BFF"
range="[^%s-%s\s,.\d]"%(start,end)
filestring=re.sub(range,'', filestring)
filestring=re.sub('\d{6,}','', filestring)
sys.stdout.write(filestring.encode('UTF-8'))

