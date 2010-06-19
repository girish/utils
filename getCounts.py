import sys
import pickle

def compare(item1, item2):
    if item1[1] < item2[1]:
        return 1;
    elif item1[1] > item2[1]:
        return -1;
    else:
        return 0;

s= pickle.load(open(sys.argv[1]))
items= s.items()
items.sort(compare)
for item in items:
	print item[0],"\t", item[1]
print "Number of Hits ===>> ", items[len(items)*90/100][1]
