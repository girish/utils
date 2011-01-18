import os
import commands
import sys
"languages/korea/corpus_filtered/languages-korea-urls-final_list_part_0.txt_dir-1125.txt"
"languages/serbia/corpus_filtered/languages-serbia-urls-combined_part02_dir-3621.txt"
"languages/serbia/html_data/combined_part09_dir/20.html"
files = open('languages/%s/data/files.non_duplicates.sor'%(sys.argv[1]),'r').xreadlines()
ifile=0
index_prefix_prev=0
file_hash={}
for file in files:
    bfile=os.path.basename(file)
    index_prefix=bfile.split('_dir')[0]
    file_name=bfile.split('-')[-1]
    if index_prefix != index_prefix_prev:
        index_prefix_prev = index_prefix
        ifile=open(index_prefix_prev.replace('-','/')+"_info",'r')
        for line in ifile.xreadlines():
            line=line.split()
            #print line[0],line[1]
            file_hash[os.path.basename(line[0])]=line[1]
    h=file_hash[file_name.replace('txt','html').strip()]
    print file.strip() + " " + h




