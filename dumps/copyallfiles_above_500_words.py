import os
import sys
import commands

files= commands.getoutput("find %s -type f | grep '\.xml'" %(sys.argv[1])).split("\n")
count= 0

for file in files:
	#print count
	word_count=commands.getoutput("wc -w %s" %(file)).split(" ")[0]
	if int(word_count) > 500 :
		print word_count
		print file
		os.system("cp %s %s/%d.txt" %(file, sys.argv[2], count))
	count +=1
