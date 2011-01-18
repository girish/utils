# -*- coding: utf-8 -*-
#!/usr/bin/env python
import sys
import os
import commands
import re
import codecs


outputFile= sys.argv[2]

#files= commands.getoutput("find %s -type f  " %(directory)).split("\n")

f= codecs.open(outputFile, "w", 'utf-8')
files= codecs.open(sys.argv[1],'r','utf-8')
#files=`find indo_corpus_factory_final -type f | xargs`

for line in files.xreadlines():
    file,src=line.split()
    id='-'.join(filter(None,re.split('[^0-9]', file)))
    file='/corpora2/vert/corpus_collection/'+file
    doc=u"<doc id=\"%s\" src=%s>\n" %(id,src.decode('utf-8'))
    print file,doc
    f.write(doc)
    paraid= 0
    for tmp_line in open(file).readlines():
        f.write('<p id="%d">\n' %(paraid))
        paraid += 1
        tmp_line= tmp_line.decode("utf-8", 'ignore')
        lines= tmp_line.split(".")
        sentid= 0
        for line in lines:
            if len(line) <= 5:
                continue;
            f.write('<s id="%d">\n' %(sentid))
            sentid += 1
            words= line.split()
            for word in words:
                try:
                    pattern= u"([\~\`\!\@\#\$\%\^\&\*\(\-\_\+\\\|\=\,\<\>\.\/\?\;\:\'\"\{\}\[\]\)]+)"
                    pattern= re.compile(pattern)
                    word_split= pattern.split(word)
                    f.write('\n'.join(word_split).strip())
                    f.write("\n")
                except:
                    pass

            f.write(".\n")
            f.write("</s>\n")
        f.write("</p>\n")
    f.write("</doc>\n")
f.close()
