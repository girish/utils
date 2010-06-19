import os

for i in xrange(0, 25):
	os.system("screen -d -m  python filtering.py ../seeds/thai/thai_frequent_words_500_words.txt ../bte/Thai_after_bte_word_seg/%d thai/%d 79/35.16/0.515 340 " %(i,i))
