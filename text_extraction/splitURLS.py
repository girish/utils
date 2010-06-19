import sys
URLS= open(sys.argv[1]).readlines()
count= len(URLS)
total_files= count/5000
for filenum in xrange(total_files):
    f= open("%s_part_%d.txt" %(sys.argv[1], filenum), "w")
    for URL in URLS[filenum*5000:(filenum+1)*5000]:
        f.write(URL)
    f.close()

for URL in URLS[total_files*5000:-1]:
    f= open("%s_part_%d.txt" %(sys.argv[1], total_files), "w")
    f.write(URL)
    f.close()
