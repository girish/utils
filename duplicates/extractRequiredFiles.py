import os
import sys

files= open(sys.argv[1]).readlines()
targetDirectory= sys.argv[2]

if not os.path.isdir(targetDirectory):
	print "Argument2 should be a directory"
	exit()

for file in files:
	file= file.strip()
	print "cp %s %s" %(file, targetDirectory)
	os.system("cp %s %s" %(file, targetDirectory))
