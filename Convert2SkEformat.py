# -*- coding: utf-8 -*-
#!/usr/bin/env python
import sys
import os
import commands
import re
import codecs

directory= sys.argv[1]
outputFile= sys.argv[2]

files= commands.getoutput("find %s -type f  " %(directory)).split("\n")

f= codecs.open(outputFile, "w", 'utf-8')

for file in files:
    print file
    f.write('<doc name="%s">\n' %(file.split("/")[-1]))
    paraid= 0
    for tmp_line in open(file).readlines():
        f.write('<p id="%d">\n' %(paraid))
        paraid += 1
        tmp_line= tmp_line.decode("utf-8", 'ignore')
        pattern= u"[\.'\u0964']"
        reg= re.compile(pattern)
        lines= reg.split(tmp_line)
        sentid= 0
        for line in lines:
            line= line.strip()
            if len(line) <= 5:
                continue;
            f.write('<s id="%d">\n' %(sentid))
            sentid += 1
            words= line.split()
            for word in words:
                pattern= u"((^[\~\`\!\@\#\$\%\^\&\*\(\)\-\_\+\=\\\|\,\<\>\.\/\?\;\:\'\"\{\}\[\]]+)|([\~\`\!\@\#\$\%\^\&\*\(\)\-\_\+\\\|\=\,\<\>\.\/\?\;\:\'\"\{\}\[\]'\u0964']+$))"
                pattern= re.compile(pattern)
                word_split= pattern.split(word)
                if word_split[0]!="":
                    f.write(word_split[0]+"\n")
                    if len(word_split) > 1 and word_split[1]!=None and word_split[1]!="":
                            f.write(word_split[1]+"\n")
                else:
                    if word_split[1]!=None and word_split[1]!='':
                        f.write(word_split[1]+"\n")
                    if word_split[4]!="":
                        f.write(word_split[4]+"\n")
                    if len(word_split) > 5 and word_split[5]!=None and word_split[5]!='':
                        f.write(word_split[5]+"\n")
            f.write(".\n")
            f.write("</s>\n")
        f.write("</p>\n")
    f.write("</doc>\n")
f.close()
