import sys
import re
import os


os.system("find %s -type f -ls | sort -k 7 -r -n | awk '{ print $11 }' > %s " %(sys.argv[1], sys.argv[2]))
