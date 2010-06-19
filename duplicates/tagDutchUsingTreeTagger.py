import sys
import commands
import os

files= commands.getoutput("find %s -type f" %(sys.argv[1])).split("\n")
outdir= sys.argv[2]

if not os.path.isdir(outdir):
    if os.path.isfile(outdir):
        print "Please give directory as input"
        exit()
    os.system("mkdir %s" %(outdir))

for file in files:
    print "tree-tagger-dutch %s > %s/%s.tagged" %(file, outdir, file)
    os.system("tree-tagger-dutch %s > %s/%s.tagged" %(file, outdir, file.split("/")[-1]))
