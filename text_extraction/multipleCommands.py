import os

for i in xrange(15, 20):
	os.system("screen -d -m nice -n 19 python applybte.py hindi_siva/splited_results/all_results_combined.txt_part_%d.txt_dir/ ../bte/hindi/all_results_combined.txt_part_%d.txt_dir_bte/ " %(i,i))
