import os
import sys
import commands

wiki2xml= os.path.join(sys.path[0],"wiki2xml/php/wiki2xml_command.php")

files = commands.getoutput("find %s -type f | grep '\.txt' " %(sys.argv[1])).split("\n")
dirs= commands.getoutput("find %s -type d" %(sys.argv[1])).split("\n")
if not os.path.exists(sys.argv[1].replace('files','xml')):
    os.mkdir(sys.argv[2].replace('files','xml'))
for dir in dirs[1:-1]:
    #path= os.path.join(sys.argv[2], dir)
    path=dir.replace('files','xml')
    print path
    if not os.path.exists(path):
        os.mkdir(path)
for file in files:
    outfile= file.replace(".txt", ".xml").replace('files','xml')
    os.system("ulimit -t 5 && php %s %s %s" %(wiki2xml, file, outfile))
    print file
