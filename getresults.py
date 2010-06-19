from yahoosearch_json import search
import sys
import pickle

seeds= open(sys.argv[1]).readlines()
scores= {}
for seed in seeds:
    seed= seed.strip()
    results= search(seed)
    scores[seed]= results['totalResultsAvailable']

pickle.dump(scores, open(sys.argv[2], "w"))
