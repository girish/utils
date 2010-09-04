###################################
#create directories
function corpus_init(){
	if [ -z "$1" ]
	then
		echo "Missing argument: give language as first argument"
		return 1
	fi
	mkdir -p languages/$1/wiki_src
	mkdir -p languages/$1/data
	mkdir -p languages/$1/query_anlaysis
	mkdir -p languages/$1/urls
	mkdir -p languages/$1/wdump_files
	mkdir -p languages/$1/wdump_filtered
	mkdir -p languages/$1/wdump_txt
	mkdir -p languages/$1/wdump_xml
	mkdir -p languages/$1/html_data
	mkdir -p languages/$1/html_data_bte
	mkdir -p languages/$1/merged_bte
	mkdir -p languages/$1/corpus_filtered
	mkdir -p languages/$1/tmp
}
corpus_dld(){
  if [ -z "$1" ] 
  then
    echo "Missing argument: give language as first argument"
    return 1
  fi
  if [ -z "$2" ] 
  then
    echo "Missing argument: give language code as second argument eg: enwiki"
    echo "Language codes are iso 639-1 codes"
    return 1
  fi
  feed_url="http://download.wikimedia.org/$2/latest/$2-latest-pages-articles.xml.bz2-rss.xml"
  latest_dump_date=`curl $feed_url | grep link | head -1 | perl -nle 'print /(\d+)/'`
  echo $latest_dump_date
  dump_link="http://download.wikimedia.org/$2/${latest_dump_date}/$2-${latest_dump_date}-pages-articles.xml.bz2"
  echo $dump_link
  wget $dump_link -P languages/$1/wiki_src
  bzip2 -d languages/$1/wiki_src/*

}


###################################
#download wiki and move it to languages/$1/wiki_src/
#make sure there are no space in $1
#function extract wiki

function corpus_ew(){
	python utils/dumps/xmldump2files.py languages/$1/wiki_src/* languages/$1/wdump_files
	#This command automatically creates a new output directory which contains plain xml files
	python utils/dumps/wiki2xml.py languages/$1/wdump_files 
	#This extracts plain text articles from the plain xml files.  
	python utils/dumps/wikiextract.py languages/$1/wdump_xml
	#This extracts the plain text articles which are above some threshold size
	python utils/dumps/copyallfiles_above_500_words.py languages/$1/wdump_txt languages/$1/wdump_filtered 
    
    python utils/dumps/invertedIndex.py languages/$1/wdump_filtered languages/$1/data/frequency_list.txt $2 #contains [A-Za-z]
}
function corpus_bqs(){
	sed -n 1,1000p languages/$1/data/frequency_list.txt | awk '{print $1}' > languages/$1/data/wiki_stop.txt
	sed -n 1001,6000p languages/$1/data/frequency_list.txt | awk '{print $1}' > languages/$1/data/wiki_seeds.txt

	# Generate 100 queries with length 1, 2 , 3, 4, 5 using the following command
	utils/BootCaT-0.1.2/build_random_tuples.pl -n1 -l100 languages/$1/data/wiki_seeds.txt > languages/$1/query_anlaysis/queries_n1.txt
	utils/BootCaT-0.1.2/build_random_tuples.pl -n2 -l100 languages/$1/data/wiki_seeds.txt > languages/$1/query_anlaysis/queries_n2.txt
	utils/BootCaT-0.1.2/build_random_tuples.pl -n3 -l100 languages/$1/data/wiki_seeds.txt > languages/$1/query_anlaysis/queries_n3.txt
	utils/BootCaT-0.1.2/build_random_tuples.pl -n4 -l100 languages/$1/data/wiki_seeds.txt > languages/$1/query_anlaysis/queries_n4.txt
	utils/BootCaT-0.1.2/build_random_tuples.pl -n5 -l100 languages/$1/data/wiki_seeds.txt > languages/$1/query_anlaysis/queries_n5.txt
	#Then get the results for the above queries. 
	python utils/getresults_bing.py languages/$1/query_anlaysis/queries_n1.txt languages/$1/query_anlaysis/results_n1.txt $2
	python utils/getresults_bing.py languages/$1/query_anlaysis/queries_n2.txt languages/$1/query_anlaysis/results_n2.txt $2
	python utils/getresults_bing.py languages/$1/query_anlaysis/queries_n3.txt languages/$1/query_anlaysis/results_n3.txt $2
	python utils/getresults_bing.py languages/$1/query_anlaysis/queries_n4.txt languages/$1/query_anlaysis/results_n4.txt $2
	python utils/getresults_bing.py languages/$1/query_anlaysis/queries_n5.txt languages/$1/query_anlaysis/results_n5.txt $2
	# Count the minimum hits for each query length
	q1=`python utils/getCounts.py languages/$1/query_anlaysis/results_n1.txt | tail -1 | awk '{print $NF}'`
	q2=`python utils/getCounts.py languages/$1/query_anlaysis/results_n2.txt | tail -1 | awk '{print $NF}'`
	q3=`python utils/getCounts.py languages/$1/query_anlaysis/results_n3.txt | tail -1 | awk '{print $NF}'`
	q4=`python utils/getCounts.py languages/$1/query_anlaysis/results_n4.txt | tail -1 | awk '{print $NF}'`
	q5=`python utils/getCounts.py languages/$1/query_anlaysis/results_n5.txt | tail -1 | awk '{print $NF}'`
    
    x=0
    q=2
    for i in $q1 $q2 $q3 $q4 $q5
    do
        ((x=x+1))
        if [ $i -le 10 ]
        then
            q=$x
            break
        fi
    done
    if [ $q -eq 5 ]
    then
        q=4
    fi

     utils/BootCaT-0.1.2/build_random_tuples.pl -n${q} -l30000 languages/$1/data/wiki_seeds.txt > languages/$1/query_anlaysis/queries_n${q}_l30000.txt
    split -l 5000 -d languages/$1/query_anlaysis/queries_n${q}_l30000.txt languages/$1/query_anlaysis/queries_n${q}_l30000_part
}
function ttttt(){
echo -n "python utils/getURLs_using_bing.py languages/$1/query_anlaysis/queries_n${q}_l30000_part00 languages/$1/urls/results0 9FD3867BFE26976AC2F5CEA2273211CF418A01EA $2
python utils/getURLs_using_bing.py languages/$1/query_anlaysis/queries_n${q}_l30000_part01 languages/$1/urls/results1 9FD3867BFE26976AC2F5CEA2273211CF5FE5C805 $2
python utils/getURLs_using_bing.py languages/$1/query_anlaysis/queries_n${q}_l30000_part02 languages/$1/urls/results2 9FD3867BFE26976AC2F5CEA2273211CF7087CBCF $2
python utils/getURLs_using_bing.py languages/$1/query_anlaysis/queries_n${q}_l30000_part03 languages/$1/urls/results3 9FD3867BFE26976AC2F5CEA2273211CF7087CBCF $2
python utils/getURLs_using_bing.py languages/$1/query_anlaysis/queries_n${q}_l30000_part04 languages/$1/urls/results4 9FD3867BFE26976AC2F5CEA2273211CF7087CBCF $2
python utils/getURLs_using_bing.py languages/$1/query_anlaysis/queries_n${q}_l30000_part05 languages/$1/urls/results5 9FD3867BFE26976AC2F5CEA2273211CF7087CBCF $2
" > languages/$1/tmp/get_urls
./parallel.sh languages/$1/tmp/get_urls
}
 

function tttttttttttt(){
#use parallel.sh to run above
python utils/combineallURLsDistinct.py languages/$1/urls/ languages/$1/urls/combined.txt
split -l 5000 -d languages/$1/urls/combined.txt languages/$1/urls/combined_part
ls languages/$1/urls/combined_part0* | awk '{print "python utils/downloadURLs.py " $1}'  > languages/$1/tmp/download_urls
./parallel.sh languages/$1/tmp/download_urls
ls -d languages/$1/html_data/combined_part0* | awk '{print "/home/girish/corpus_collection/utils/text_extraction/applybte.py " $1}'  > languages/$1/tmp/apply_bte
./parallel.sh languages/$1/tmp/apply_bte
python utils/moveallfiles.py $1
python utils/getGoodWordsRatio.py languages/$1/data/wiki_stop.txt languages/$1/wdump_filtered/ > languages/$1/data/good_words_ratio.txt
python utils/filtering/filtering.py languages/$1/data/wiki_stop.txt languages/$1/merged_bte/ languages/$1/corpus_filtered 36/0.25
 python utils/duplicates/sortDocumentsbySize.py languages/$1/corpus_filtered/ languages/$1/data/files.sorted
 perl utils/duplicates/optimizedIdentifyDuplicates.pl languages/$1/data/files.sorted languages/$1/data/files.non_duplicates languages/$1/data/files.duplicates
}
