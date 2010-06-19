import sys
import commands
from pprint import pprint

files= commands.getoutput("find %s -type f " %sys.argv[2]).split("\n")
frequent_words= {}

f= open(sys.argv[1], "r")
for word in f.readlines():
    #print word
    word= word.strip().split()[0]
    frequent_words[word] = 1

#pprint(frequent_words)

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
                    if tot_words <= 500: 		#340 is the avg number of words in 5KB document
                        distinct_words[word]=1
                if word!="":
                   tot_words += 1
    #size= int(commands.getoutput("du -sh %s" %file).split()[0].strip("K"))
    #print word_count, size
    #print (word_count+0.0)/size
    if tot_words > 0 :
    	list.append([len(distinct_words.keys()), (word_count+0.0)/tot_words, file])
    f.close()
    
list.sort(reverse=True)
for element in list:
   print element
print list[len(list)*4/5]
