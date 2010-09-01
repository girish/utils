#!/bin/bash
while read line
do
    screen -S 1 -md $line
    #echo $direc
done < $1

