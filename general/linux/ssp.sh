#!/bin/bash

########################################################################################
## psファイルを1シートに複数載せるcommond
## 通称※清水スペシャル(SSP)
########################################################################################

########################################################################################
## Function
########################################################################################

usage(){
echo "USAGE: `basename $0` <-n NUMBER> [-o OUTPUT] FILE1 FILE2 ..." 1>&2
exit 1
}


########################################################################################
## Option
########################################################################################

GETOPT=`getopt -q -o o:n:u -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"

while true ;do
  case $1 in
      -n) num=$2 ;shift 2
          ;;
      -o) output=$2 ;shift 2
	  ;;
      -u) usage 
          ;;
      --) shift ; break
          ;;
      *) usage
          ;;
  esac
done


########################################################################################
## Main
########################################################################################

if [ _${num} = _ ];then
    usage
fi

if [ _${output} = _ ];then
    output=`date +"%Y%m%d_%H:%M:%S"`
fi

#cat $@ |gs -dBATCH -dNOPAUSE -q -sDEVICE=pswriter -sPAPERSIZE=a4 -dNOPLATFONTS -sOutputFile=- | psnup -${num} > ${output%.*}.ps

gs -dBATCH -dNOPAUSE -q -sDEVICE=epswrite -sPAPERSIZE=a4 -dNOPLATFONTS -sOutputFile=- $@ |psnup -${num} > ${output%.*}.ps
echo "OUTPUT : ${output%.*}.ps"

#ps2pdf ${output%.*}.ps && rm -f ${output%.*}.ps

