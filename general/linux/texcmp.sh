#!/bin/bash

########################################################################################
## Function
########################################################################################

usage(){
echo "USAGE: `basename $0` <TexFILE> [-o OUTPUT]" 1>&2
exit 1
}

tex2pdf(){
texfile=$1
outfile=$2
platex ${texfile}
dvipdfmx -o ${outfile} ${texfile%.tex}.dvi 
}

tex2ps(){
texfile=$1
outfile=$2
platex ${texfile}
dvips ${texfile%.tex}.dvi -o ${outfile}
}

########################################################################################
## Option
########################################################################################
GETOPT=`getopt -q -o o:h -- "$@"` ; [ $? != 0 ] && usage 
#echo "$@ after GETOPT" ##DEBUG
eval set -- "$GETOPT"
#echo "$@ after SET" ##DEBUG
while true ;do
  case $1 in
      -o) output=$2 ;shift 2
          ;;
      -h) usage 
          ;;
      --) shift ; break
          ;;
      *) #echo "in case script" ##DEBUG
	 usage
          ;;
  esac
done

########################################################################################
## Set Value
########################################################################################

input=$1 
#echo "INPUT=${input}" ## DEBUG
#echo "OUTPUT=${output}" ## DEBUG
if [ "x${input}" = "x" ] ;then
    #echo "Enter the Tex file" ## DEBUG
    usage 
else
    if [ "x${output}" = "x" ];then
	output="${input%.tex}.pdf"
    fi
fi
#echo "OUTPUT=${output}" ## DEBUG
ext=${output#*.} #;echo "EXTENTION=${ext}" ## DEBUG
case ${ext} in
    pdf) tex2pdf ${input} ${output};;
    ps) tex2ps ${input} ${output};;
    *) usage;;
	
esac 