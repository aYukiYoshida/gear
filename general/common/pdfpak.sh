#!/bin/bash

###########################################################################
## Value
###########################################################################
# date=$(date +"%Y%m%d")
OS=$(uname)
SCRIPTFILE=$0
[ -L ${SCRIPTFILE} ] && SCRIPTFILE=$(readlink ${SCRIPTFILE})
SCRIPTNAME=$(basename ${SCRIPTFILE%.*})


################################################################################
## Function
################################################################################

usage(){
    echo "Make multiple PDF files into one file"
    echo "USAGE: ${SCRIPTNAME} [-o OUTPUT] [-r|--remove-each-file] FILE1 FILE2 ..." 1>&2
    exit 0
}


abort(){
    local message=$1
    echo ${message} 1>&2
    exit 1
}


################################################################################
## Option
################################################################################
FLG_R=0

GETOPT=$(getopt -q -o o:uhr -l usage,help,remove-each-file -- "$@")
[ $? != 0 ] && usage
eval set -- "$GETOPT"

while true ;do
    case $1 in
        -o) output=$2; shift 2;;
        -r|--remove-each-file) FLG_R=1; shift ;;
        -u|-h|--usage|--help) usage ;;
        --) shift; break ;;
        *) abort "Invalid option" ;;
    esac
done


################################################################################
## Main
################################################################################

if [ _${output} = _ ];then
    output=$(date +"%Y%m%d_%H:%M:%S")
fi

if [ $# -ne 0 ];then
    gs -dNOPAUSE -dBATCH -q -sDEVICE=pdfwrite -sOutputFile=${output%.*}.pdf $@

    if [ ${FLG_R} -eq 1 ];then
        for eachfile in $@ ;do
            [ -e ${eachfile} ]&&rm -f ${eachfile}
        done
        echo "$(basename $0): all input files were removed"
    fi
    echo "${SCRIPTNAME}: ${output%.*}.pdf was generated"
else
    abort "No found input PDF file"
fi


#EOF#
