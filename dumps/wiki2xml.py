import os
import sys
import commands

wiki2xml= os.path.join(sys.path[0],"wiki2xml/php/wiki2xml_command.php")

files = commands.getoutput("find %s -type f | grep '\.txt' " %(sys.argv[1])).split("\n")
dirs= commands.getoutput("find %s -type d" %(sys.argv[1])).split("\n")
if not os.path.exists("out_%s" %(sys.argv[1])):
	os.mkdir("out_%s" %(sys.argv[1]))
for dir in dirs:
	path= os.path.join("out_%s" %(sys.argv[1]), dir)
	if not os.path.exists(path):
		os.mkdir(path)
for file in files:
	outfile= file.replace(".txt", ".xml")
	os.system("ulimit -t 5 && php %s %s out_%s/%s" %(wiki2xml, file, sys.argv[1], outfile))
	print file
