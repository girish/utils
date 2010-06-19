import sys
import commands
from pprint import pprint
import os

frequent_words= {}
f= open(sys.argv[1], "r")
for word in f.readlines():
#    word= word.strip().split()[0]
    word= word.strip()
    frequent_words[word] = 1
    #print word
f.close()

files= commands.getoutput("find %s -type f" %sys.argv[2]).split("\n")

destDir= sys.argv[3]

if os.path.exists(destDir) and os.path.isdir(destDir):
   pass;
elif os.path.exists(destDir):
   print "%s is not a Directory" %(destDir)
else:
   os.mkdir(destDir)

#pprint(frequent_words)

(types,ratio) = sys.argv[4].split("/")
count_types= int(types) 
count_ratio= float(ratio)

words_in_5KB= 500 #int(sys.argv[5])		#words in 5KB documnet


list=[]

for file in files:
    word_count= 0
    tot_words= 0
    distinct_words= {}
    print file
    f= open(file, "r")
    while 1:
        line= f.readline()
        if line=="":
            break
        else:
            for word in line.split():
                word= word.strip(",.;\"()")
                if frequent_words.has_key(word):
                    word_count += 1
                    if tot_words <= words_in_5KB:
                        distinct_words[word]=1
                if word!="":
                   tot_words += 1
    #size= float(commands.getoutput("du -sh -k %s" %file).split()[0].strip("K"))
    #print word_count, size
    #print (word_count+0.0)/size
    if tot_words > 0:
   	 if (len(distinct_words.keys()) >= count_types) and (word_count+0.0)/tot_words >= count_ratio:
        	os.system("cp %s %s" %(file, destDir))
         
    if tot_words > 0:
    	print len(distinct_words.keys()), (word_count+0.0)/tot_words, file
    f.close()
