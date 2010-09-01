#!/usr/bin/env python
import sys
import os
import commands
import re
#pattern= u"((^[\~\`\!\@\#\$\%\^\&\*\(\)\-\_\+\=\\\|\,\<\>\.\/\?\;\:\'\"\{\}\[\]]+)|([\~\`\!\@\#\$\%\^\&\*\(\)\-\_\+\\\|\=\,\<\>\.\/\?\;\:\'\"\{\}\[\]'\u0964']+$))"
pattern=u"([\~\`\!\@\#\$\%\^\&\*\(\)\-\_\+\=\\\|\,\<\>\.\/\?\;\:\'\"\{\}\[\]\s]+)"
pattern=re.compile(pattern)

def getinvertIndex(directory):
    invertIndex= {} # { word:{ document_name:frequency } }
    files= commands.getoutput("find %s -type f -size +10k " %(directory)).split("\n")
    #All the text files in a directory whose size greater than certain thrshold
    for file in files:
        print file
        f= open(file, "r")
        while 1:
            line= f.readline()
            if line=="":
                break
            else:
                for word in pattern.split(line):
                    word= word.strip(",.;\"\()[]\'")
                    if not invertIndex.has_key(word):
                        invertIndex[word]= {}
                    if not invertIndex[word].has_key(file):
                        invertIndex[word][file]= 0
                    invertIndex[word][file] += 1
        f.close()
    return invertIndex

def compare(item1, item2):  #Used in sorting seedwords
    if item1[1] < item2[1]:
        return 1;
    elif item1[1] > item2[1]:
        return -1;
    else:
        return 0;


if __name__=="__main__":
    invertIndex= getinvertIndex(sys.argv[1])
    counts= {}
    total={}
    word_count=0
    for key in invertIndex.keys():
        counts[key]= len(invertIndex[key])
        total[key]= 0
        for file in invertIndex[key].keys():
            total[key] += invertIndex[key][file]
    items= counts.items()
    items.sort(compare)
    f= open(sys.argv[2], "w")
    for (word, count) in items:
        #print "%s ----> %d" %(word, count)
        files= invertIndex[word].items()
        files.sort(compare)
        pattern1= "[0-9,;:\"\'\?\!<>.]"
        pattern2= "(^[a-zA-Z]+)"
        #reg= re.compile(pattern)
	#print word
        #.decode("utf-8", 'ignore')
        #if len(unicode_word) > 5 and re.search(pattern, word)==None:
        if re.search(pattern1, word)==None and re.search(pattern2, word)!=None:
            f.write("%s\t%d\t%d\n" %(word, count, total[word]))
	#if re.search(u"[^\uAC00-\uD7A3]",word)==None:
         #   unicode_word= word.decode("utf-8", "replace")
         #   word= unicode_word.encode("utf-8", "replace")
         #   f.write("%s\t%d\t%d\n" %(word, count, total[word]))
        #f.write("%s\t%d\n" %(word, total[word]))
        #for (file, count) in files:
        #    f.write("\t%s\t%d\n" %(file, count))
    #f.close()
