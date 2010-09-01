import sys
import os
import commands

finalDest= "languages/%s/merged_bte"%(sys.argv[1])#sys.argv[1]
dirs= commands.getoutput('ls -d languages/%s/html_data_bte/combined_part*'%(sys.argv[1])).split('\n')
if not os.path.exists(finalDest):
    os.mkdir(finalDest)

for dir in dirs:
    files= commands.getoutput("find %s -type f" %(dir)).split("\n")
    for file in files:
        try:
            ext=file.replace('html_data_bte','urls').replace('/','-')
            print "mv %s %s" %(file, os.path.join(finalDest, ext))
            os.system("mv %s %s" %(file, os.path.join(finalDest, ext)))
        except:
            continue
        #os.system("mv %s %s/%d.html" %(file, finalDest, filenum))
