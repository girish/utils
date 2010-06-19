import sys

queries= open(sys.argv[1]).readlines()

num_of_files= len(queries)/5000

for num in xrange(num_of_files):
    f= open(sys.argv[1]+"_part_"+str(num)+"_urls.txt", "w")
    for querynum in range(num*5000, (num+1)*5000):
        f.write(queries[querynum])
    f.close()

f= open(sys.argv[1]+"_part_"+str(num_of_files)+"_urls.txt", "w")    
for querynum in xrange(num_of_files*5000, len(queries)):
    f.write(queries[querynum])
f.close()