#!/bin/bash

#directory内のfileおよびdirectoryすべてをリンクづけする。


################################################################################
## Update
################################################################################
# Ver.  | Date       | Author   | 内容
#-------------------------------------------------------------------------------
# 1.0.0 | 2012.04.XX | yyoshida | prototype
# 2.0.0 | 2015.05.15 | yyoshida | Redrawn



################################################################################
## Set Command & Value
################################################################################
version=2.0.0
author=yyoshida
exedir=`pwd`
srcdir=$1
outdir=$2


################################################################################
## Function
################################################################################
title(){
cat <<EOF

               **  `basename $0` Version ${version} Written by ${author}  **

EOF
}


usage(){
    cat <<EOF 
Usage   : %`basename $0` <link source directory> <link destination>
Example : %`basename $0` /data09/yyoshida/data data_copy
EOF
    exit 1
}

fullpath(){
    cd $1
    fullpath_return=`pwd`
}


showdir(){
    src=$1
    out=$2
    cat <<EOF
source directory : ${src}
output directory : ${out}
EOF
}

linkgen(){
    cat <<EOF

Generate links following files and directory.  
========================================================================================
EOF

for i in $@ ;do
    echo " ${i}"
    ln -sf ${fullpath_return}/${i%/}
done
    cat <<EOF
========================================================================================
Finish.

EOF
}

################################################################################
## Option
################################################################################
GETOPT=`getopt -q -o u -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ##DEBUG

while true ;do
  case $1 in
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

#echo $#
#exit 1

if [ $# -ne 2 ];then
    usage
else
    title ## Title

    if [ ${outdir} = . ];then
	fullpath ${outdir}
	outdir=${fullpath_return}
	
    elif [ -d ${outdir} ];then
	fullpath ${outdir}
	outdir=${fullpath_return}
	
    else
	mkdir ${outdir}
	fullpath ${outdir}
	outdir=${fullpath_return}
    fi
    
    cd ${exedir}
    
    fullpath ${srcdir}
    srcdir=${fullpath_return}
    #echo ${srcdir}
    allsrc=`\ls ${srcdir}`
    #echo ${allsrc}

    showdir ${srcdir} ${outdir}

    cd ${outdir}

    linkgen ${allsrc}
    
    cd ${exedir}
fi

#EOF#