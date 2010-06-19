import sys
f=open(sys.argv[1], "r")
total_files= int(sys.argv[2])
max= total_files*10/100
min= total_files*5/100

lines= f.readlines()
for line in lines:
	word= line.split("\t")
	if int(word[1])<=max:
		if int(word[1])>=min:
			print word[0]
		else:
			break
