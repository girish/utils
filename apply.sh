#!/bin/bash
#$1 --- command
#$2 --- directory
#$3 ---- lang name (same as the directory name u created in lang directory) 
#Take directories in directory and apply command on directory
#asumming directory just contains many directories on which command should be run
#after splitting
#run each one with screen -S -md

outfile=languages/$3/tmp/${1////-}-scriptfile

for direc in `ls -d ${2%%/}/*`
do
    echo `readlink -f $1` $direc
done > $outfile
lines=`cat $outfile | wc -l`

split -l $(($lines/8)) -d $outfile ${outfile}-splits

for direc in ${outfile}-splits*
do
#    screen -S $3 -md sh $direc
    echo $direc
done

