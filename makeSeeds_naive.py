import sys,re
f=open(sys.argv[1], "r")
lines= f.readlines()
count=0
for line in lines[6000:8000]:
	word= line.split("\t")
	#if len(word[0]) > 4 :
	#if re.search(u"[^\uAC00-\uD7A3]",word[0])==None:
		#nothing
	#  	print word[0]
	#else:
	#	word[0]
	print word[0]
		
	#count=count+1
	#if count == 5000:
		#break
