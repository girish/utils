import sys
import os
import commands
import re

directory= sys.argv[1]
outputFile= sys.argv[2]

files= commands.getoutput("find %s -type f  " %(directory)).split("\n")

out= open(outputFile, "w")
story= 0
for file in files:
	print file
	out.write("<doc id=\"%d\" name=\"%s\">\n" %(story, file))
	lines= open(file).readlines()
	para= 0
	for line in lines:
		line= line.strip()
		unicode_line= line.decode("utf-8", "replace")
                line= unicode_line.encode("utf-8", "replace")
		sent= 0
		sentCheck= 1
		out.write("<p id=\"%d\">\n" %(para))
		line= line.replace("   ", " . ")
		words= line.split()
		for word in words:
			if sentCheck==1:
				out.write("<s id=\"%d\">\n" %(sent))
				sentCheck= 0
			word= word.strip()
			if word[0]=='<':
				continue
			rightRefinedWord= word.rstrip(",;:\"\'\?\!\]\[\}\{\)\(")
			refinedWord= (word.lstrip(",;:\"\'\?\!\]\[\}\{\)\(")).strip()
			left= (rightRefinedWord.replace(refinedWord, "")).strip()
			right= (word.replace(rightRefinedWord, "")).strip()
			if left!="":
				out.write(left+"\n")
			if refinedWord!="":
				out.write(refinedWord+"\n")
				if refinedWord==".":
					out.write("</s>\n")
					sentCheck= 1
					sent+=1
			if right!="":
				out.write(right+"\n")
		if sentCheck==0:
			out.write("</s>\n")
		out.write("</p>\n")
		para += 1
	out.write("</doc>\n")	
	story += 1
	
def getinvertIndex(directory):
    invertIndex= {} # { word:{ document_name:frequency } }
    
