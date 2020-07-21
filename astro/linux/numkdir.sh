#!/bin/bash

################################################################################
## make directry for nustar analysis
################################################################################

dir=$1

if [ "x" = "x${dir}" ];then
    echo "Please enter the directry name for `basename $0`"
    exit 1

elif [ ! -d ${dir} ];then
    echo "${dir} does not exist"
    exit 1

else
    #archive
    if [ -e ${dir}/archive ];then
	echo "The directory of archive have already existed"
    else
    	mkdir -p ${dir}/archive
	for tgt in ${dir}/* ;do
	    if [[ $(basename ${tgt}) != archive ]];then
		mv ${tgt} ${dir}/archive
	    fi
	done
    fi

    #reprocess
    if [ -e ${dir}/reprocess ];then
	echo "The directory of reprocess have already existed"
    else
	mkdir -p ${dir}/reprocess
    fi

    #analysis
    if [ -e ${dir}/analysis ];then
	echo "The directory of analysis have already existed"
    else
	mkdir -p ${dir}/analysis

	mkdir -p ${dir}/analysis/img/raw
	mkdir -p ${dir}/analysis/img/energydiv

	mkdir -p ${dir}/analysis/spec/src
	mkdir -p ${dir}/analysis/spec/src/model
	mkdir -p ${dir}/analysis/spec/src/BestfitModel
	mkdir -p ${dir}/analysis/spec/src/qdpfile
	mkdir -p ${dir}/analysis/spec/src/log
	mkdir -p ${dir}/analysis/spec/src/report
	mkdir -p ${dir}/analysis/spec/src/parameter/
	
	mkdir -p ${dir}/analysis/lc/src
	mkdir -p ${dir}/analysis/lc/energydiv
	
	mkdir -p ${dir}/analysis/reg/src
	mkdir -p ${dir}/analysis/gti
    fi
fi

#EOF#
