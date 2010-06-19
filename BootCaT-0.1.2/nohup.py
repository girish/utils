import os
for i in xrange(0,22):
	print "nohup ./retrieve_and_clean_pages_from_url_list.pl -g ../seeds/Dutch_frequent_words_500.txt -k 60/105/0.13 ../collect_urls/Dutch_Newqueries_from_q20000_q10000_n3_cleaned_url_list.txt_part_%d.txt > ../cleaned_corpus/Dutch_Newqueries_from_q20000_q10000_n3_cleaned_corpus.txt_60_105_0.13_part_%d.txt &" %(i,i)
	os.system("nohup ./retrieve_and_clean_pages_from_url_list.pl -g ../seeds/Dutch_frequent_words_500.txt -k 60/105/0.13 ../collect_urls/Dutch_Newqueries_from_q20000_q10000_n3_cleaned_url_list.txt_part_%d.txt > ../cleaned_corpus/Dutch_Newqueries_from_q20000_q10000_n3_cleaned_corpus.txt_60_105_0.13_part_%d.txt &" %(i,i))
