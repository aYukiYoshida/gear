#!/bin/sh

#################################################################
#  Image extractor for postscript files                         #
#                                                               #
#  Copyright (c)2010 DAI Takei                                  #
#  All Rights Reserved                                          #
#                                                               #
#  History                                                      #
#  Release    : by DAI Takei                                    #
#                                                               #
#################################################################
version="1.00"

##############################
###      Subroutines       ###
##############################

for item in $@ ; do
    if [ -f ${item} ] ; then
	mkdir ${item%.*}_psimages
	number="`grep \"BeginDocument\" ${item}|awk '{print $2}'|wc -l`"
	counts="0"
	for image in `grep "BeginDocument" ${item} | awk '{print $2}'` ; do
	    filename="`echo ${image} | sed 's/.*\///g'`"
	    cat ${item} | sed -n '/'${filename}'/,$p' | sed '/EndDocument/,$d' | tail -n +2 | head -n -1 > ${item%.*}_psimages/${filename}
	    counts="`echo ${counts} | awk '{print $1+1}'`" ; echo "${counts}/${number}"
	done
    else
	cat /dev/null
    fi
done

exit 0
