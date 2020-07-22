#!/bin/bash

########################################################################
## Value
########################################################################
SCRIPTFILE=$0
[ -L ${SCRIPTFILE} ] && SCRIPTFILE=$(readlink ${SCRIPTFILE})
SCRIPTNAME=$(basename ${SCRIPTFILE%.*})
sys=$(dirname ${SCRIPTFILE})
srcfile=${sys}/staticsource.tex


########################################################################
## Function
########################################################################

#usage
usage(){
    echo "USAGE: ${scriptname} <LOGFILE> <IMGFILE> <TEXFILE>"
    echo "EXAMPLE: ${scriptname} log.txt img.eps out.tex"
    exit 0
}

#getting full path    
fullpath(){
    exedir=`pwd`
    cd $1
    fullpath_return=`pwd`
    cd ${exedir}
}


################################################################################
## MAIN
################################################################################
if [ "$1" = "-u" ] || [ $# -lt 3 ];then
    usage
elif [ ! -e $1 ] || [ ! -e $2 ] ;then
    usage
elif [ -e $1 ] && [ -e $2 ] ;then
    log=$1
    img=$2
    lab=${img%.eps}
    out=$3
    
    fullpath $(dirname $(basename ${img}))
    imgdir=${fullpath_return}
    #xspec_log=$(cat ${log}|${sed} -n '/#=====/,$p'|${sed} '/exec rm -f/,$d'|${sed} '/= 1:/d'|${sed} '/XSPEC12>/d')

    cat ${srcfile} | sed -e "s%(IMAGE_DIR)%${imgdir}% ;s%(IMAGE)%${img}%; s%(CAPTION)%${lab}%; s%(LABEL)%${lab}%; s%(XSPEC_LOG)%${xspec_log}%" > ${out}

    cat ${log}|sed -n '/#=====/,$p'|sed '/exec rm -f/,$d'|sed '/XSPEC12>/d' > extracted_xspec_log
    line_number_for_insert=$(grep -n "(XSPEC_LOG)" ${srcfile}|cut -d ':' -f 1)
    sed -i "${line_number_for_insert}r extracted_xspec_log" ${out} && rm -f extracted_xspec_log
    cd $(dirname ${out})
    platex $(basename ${out})
    dvips $(basename ${out%.tex}.dvi)
    dvipdf $(basename ${out%.tex}.dvi)

fi


#EOF#
