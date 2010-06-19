import sys

duplicates= open(sys.argv[1]).readlines();
allfiles= open(sys.argv[2]).readlines();
nonDuplicateFile= open(sys.argv[3], "w");


map= {}

for duplicate in duplicates:
    map[duplicate.split("\t")[0]]= 1

nonDuplicates= []
for file in allfiles:
    file= file.strip();
    if not map.has_key(file):
        nonDuplicates.append(file)
        #duplicate= duplicate.strip()
    
for file in nonDuplicates:
    nonDuplicateFile.write(file+"\n")

nonDuplicateFile.close()
