import sys
import commands
import os
from bte import html2text
os.sys
inputDir = os.path.abspath(sys.argv[1])

files= commands.getoutput("find %s -type f" %(inputDir)).split("\n")

bte=os.path.join(sys.path[0],'bte.py')
print bte
if not os.path.exists(outputDir):
    os.mkdir(outputDir)

for file in files:
    #temp_outfile= file[:(file.find((file.split("/")[-1]).split(".")[-1]))] + "txt"
    temp_file,ext=os.path.splitext(file)
    temp_outfile=temp_file+".txt"
    filename=os.path.basename(temp_outfile)
    dirname=os.path.dirname(temp_outfile)
    print temp_outfile
    outfile= os.path.join(outputDir,filename)
    if os.path.exists(temp_outfile):
        os.system("rm %s" %(temp_outfile))
    os.system("ulimit -t 5 && python %s %s" %(bte,file))
    os.system("mv %s %s" %(temp_outfile, outfile))
    print outfile
    #html_text= open(file).read()
    #text= html2text(html_text)
    #open(outfile, "w").write(text)
