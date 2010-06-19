# -*- coding: utf-8 -*-
import os
import commands
import sys
import re

inputUrllist= open(sys.argv[1]).readlines()
outputDir= sys.argv[1]+"_dir"
url_file= open(sys.argv[1]+"_info","w")
if not os.path.isdir(outputDir):
    os.system("mkdir %s" %(outputDir))
urls_info=[]
file= 0
for line in inputUrllist:
    line= line.strip()
    (url, size)= line.split("\t")
    url= '"' + url + '"'
    file_extension= ((url.split("/")[-1]).split(".")[-1]).lower()
    pattern1= "((a)|(ai)|(aif)|(aifc)|(aiff)|(asc)|(avi)|(bcpio)|(bin)|(bmp)|(bz2)|(c)|(cdf)|(cgi)|(cgm)|(class)|(cpio)|(cpp?)|(cpt)|(csh)|(css)|(cxx)|(dcr)|(dif)|(dir)|(djv)|(djvu)|(dll)|(dmg)|(dms)|(doc)|(dtd)|(dv)|(dvi)|(dxr)|(eps)|(etx)|(exe)|(ez)|(gif)|(gram)|(grxml)|(gtar)|(gz)|(h)|(hdf)|(hqx)|(ice)|(ico)|(ics)|(ief)|(ifb)|(iges)|(igs)|(iso)|(jnlp)|(jp2)|(jpe)|(jpeg)|(jpg)|(js)|(kar)|(latex)|(lha)|(lzh)|(m3u)|(mac)|(man)|(mathml)|(me)|(mesh)|(mid)|(midi)|(mif)|(mov)|(movie)|(mp2)|(mp3)|(mp4)|(mpe)|(mpeg)|(mpg)|(mpga)|(ms)|(msh)|(mxu))$"
    pattern2="((nc)|(o)|(oda)|(ogg)|(pbm)|(pct)|(pdb)|(pdf)|(pgm)|(pgn)|(pic)|(pict)|(pl)|(png)|(pnm)|(pnt)|(pntg)|(ppm)|(ppt)|(ps)|(py)|(qt)|(qti)|(qtif)|(ra)|(ram)|(ras)|(rdf)|(rgb)|(rm)|(roff)|(rpm)|(rtf)|(rtx)|(s)|(sgm)|(sgml)|(sh)|(shar)|(silo)|(sit)|(skd)|(skm)|(skp)|(skt)|(smi)|(smil)|(snd)|(so)|(spl)|(src)|(srpm)|(sv4cpio)|(sv4crc)|(svg)|(swf)|(t)|(tar)|(tcl)|(tex)|(texi)|(texinfo)|(tgz)|(tif)|(tiff)|(tr)|(tsv)|(txt)|(ustar)|(vcd)|(vrml)|(vxml)|(wav)|(wbmp)|(wbxml)|(wml)|(wmlc)|(wmls)|(wmlsc)|(wrl)|(xbm)|(xht)|(xhtml)|(xls)|(xml)|(xpm)|(xsl)|(xslt)|(xwd)|(xyz)|(z)|(zip))$"
    print file_extension
    if re.match(pattern1, file_extension)==None and re.match(pattern2, file_extension)==None :
        print "yes"
        if int(size)==-1 or (int(size) > 5000 and int(size) < 2000000):
	    os.system("wget --timeout=5 -O %s/%d.html -t 2 %s" %(outputDir, file, url))
            if os.path.exists("%s/%d.html" %(outputDir, file)):
                type= commands.getoutput("file %s/%d.html" %(outputDir, file))
                filesize=  os.path.getsize("%s/%d.html" %(outputDir, file))
                if type.find("text")!=-1 and filesize < 2000000 and filesize > 5000:
		    urls_info.append("%s/%d.html  %s\n" %(outputDir,file,url))	
                    file += 1
for line in urls_info:
  	url_file.write(line)

		    
