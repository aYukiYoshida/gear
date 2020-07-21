#!/bin/bash

#############################
##compile of C language
#############################

gcc="/usr/bin/gcc -lm"

file=$1 #file : clangauge file
exe=${src%.c}
obj=${src%.c}.o


cc -c ${src}
cc -o ${exe} ${obj} -lm
rm -f ${obj}

