#!/bin/bash

################################################################################
## Function
################################################################################

usage(){
    echo "Make multiple PDF files into one file"
    echo "USAGE: `basename $0` [-o OUTPUT] [-r|--remove-each-file] FILE1 FILE2 ..." 1>&2
    exit 1
}


################################################################################
## Option
################################################################################
FLG_R=FALSE

GETOPT=`getopt -q -o o:ur -l "remove-each-file" -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"

while true ;do
  case $1 in
      -o) output=$2 ;shift 2
	  ;;
      -r|--remove-each-file) FLG_R=TRUE
			     shift
			     ;;
      -u) usage 
          ;;
      --) shift ; break
          ;;
      *) usage
          ;;
  esac
done


################################################################################
## Main
################################################################################

if [ _${output} = _ ];then
    output=`date +"%Y%m%d_%H:%M:%S"`
fi

if [ $# -ne 0 ];then
    gs -dNOPAUSE -dBATCH -q -sDEVICE=pdfwrite -sOutputFile=${output%.*}.pdf $@

    if [[ ${FLG_R} = TRUE ]];then
	for eachfile in $@ ;do
	    [ -e ${eachfile} ]&&rm -f ${eachfile}
	done
	echo "`basename $0`: all input files were removed"
    fi
    echo "`basename $0`: ${output%.*}.pdf was generated"

else
    echo "Please input PDF files"
fi


#EOF#
