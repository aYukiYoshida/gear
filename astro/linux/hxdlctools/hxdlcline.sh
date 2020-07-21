#!/bin/bash

#SCF Effect GAIN CORRECTION 


################################################################################
## Redaction History
################################################################################
# Ver.  | Date       | Author   | 内容
#-------------------------------------------------------------------------------
# 1.0.0 | 2015.06.03 | yyoshida | prototype
# 1.1.0 | 2015.06.04 | yyoshida | headerのNAXIS1,NAXIS2の書き換え部分追加
# 1.1.1 | 2015.06.04 | yyoshida | input file name stdout
# 1.1.2 | 2015.06.08 | yyoshida | add script of appending GTI Extension


################################################################################
#Set Parameter
################################################################################
linefile=$1
basefile=$2
outfile=$3
version="1.1.1"
author="Y.Yoshida"


################################################################################
#Command
################################################################################
rm="/bin/rm -f"
sed="/bin/sed"
fdump="`which fdump` columns=\"\" rows=-"
fcreate=`which fcreate`
fappend=`which fappend`
lcline="/data09/yyoshida/Data/Suzaku/A0535_262/Tools/hxdlcline"


################################################################################
#Function
################################################################################
usage(){
cat <<EOF 
Usage   : `basename $0` <LINELC> <BASEDLC> [OUTPUT]
Example : `basename $0` pin_nxb.lc pin_pse.lc pin_nxb_lined.lc
EOF
exit 1
}


title(){
cat <<EOF
Version ${version} 
Written by ${author}
EOF
}


line(){
    linelc=$1
    baselc=$2
    flag=$3
    outlc=$4
    ${fdump} ${linelc}+1 linetemp.dat "prhead=no" #fdumpでtimeとrateをlcからとりだす。
    ${fdump} ${baselc}+1 basetemp.dat "prhead=no" #fdumpでtimeとrateをlcからとりだす。
    sed '1,/count/d' linetemp.dat|awk '{print $2,$3,$4,$5}' > line.dat 
    sed '1,/count/d' basetemp.dat|awk '{print $2,$3,$4,$5}' > base.dat 
    #lc1.dat,lc2.dat=>input of lcuniform.c
    ${fdump} ${linelc}+1 headtemp.dat "prdata=no" #fdumpでheaderをlcファイルからとりだす。
    sed '/NAXIS1/d' headtemp.dat| sed '/NAXIS2/d' > head.dat
    ${lcline} #lineout.datができる
cat <<EOF

Input original file : ${linelc}
revised based on time column of ${baselc}
generated lightcurve fits file : ${outlc}
`basename $0` has done.
EOF

    #column descriptor file for "fcreate"
    cat << EOF > cdf.dat
TIME D s
RATE E count/s
ERROR E count/s
FRACEXP E
EOF

    ${fcreate} cdf.dat lineout.dat "headfile=head.dat" ${outlc} "extname=RATE" "clobber=${flag}"
    row_num=`wc -l lineout.dat` 
    ${rm} linetemp.dat basetemp.dat line.dat base.dat lineout.dat
    ${rm} headtemp.dat head.dat cdf.dat
    ${fappend} ${linelc}+2 ${outlc} "pkeywds=yes"

}



################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o u: -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"
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
#Checking Source
################################################################################

if [ $# -lt 2 ] ;then
    usage
else
    
    if [ ! -f ${linefile} ] ;then
	echo "`basename $0` couldn't find \"${linefile}\"."
	File_FLG=FALSE
    elif [ ! -f ${basefile} ] ;then
	echo "`basename $0` couldn't find \"${basefile}\"."
	File_FLG=FALSE
    fi

    if [ "${File_FLG}" = "FALSE" ];then
	exit 1
    fi

fi

################################################################################
#Main
################################################################################
if [ _${outfile} = _ ] ;then
    outfile=${linefile%.lc}_lined.lc
fi
title

if [ ! -f ${outfile} ] ;then
    line ${linefile} ${basefile} no ${outfile}
else
    echo ""
    echo "${outfile} already exists !!" # 1>&2
    echo -n "Overwrite ?? (y/n) >> "
    read answer
    case ${answer} in
        y|Y|yes|Yes|YES)
	    line ${linefile} ${basefile} yes ${outfile}
            ;;

        n|N|no|No|NO)
            echo "`basename $0` has not been executed. "
            ;;

        *)
            echo "`basename $0` has not been executed. "
    esac
fi


#EOF#