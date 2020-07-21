#!/bin/bash


################################################################################
## Redaction History
################################################################################
# Ver.  | Date       | Author   | ∆‚Õ∆
#-------------------------------------------------------------------------------
# 1.0.0 | 2015.06.08| yyoshida | prototype



################################################################################
#Set Parameter
################################################################################
infile=$1
outfile=$2
version="1.0.0"
author="Y.Yoshida"


################################################################################
#Command
################################################################################
rm="/bin/rm -f"
sed="/bin/sed"
fdump="`which fdump` columns=\"\" rows=-"
fcreate=`which fcreate`
fappend=`which fappend`
fparkey=`which fparkey`
fkeyprint=`which fkeyprint`
lcoffset="/data09/yyoshida/Data/Suzaku/A0535_262/Tools/hxdlcoffset"


################################################################################
#Function
################################################################################
usage(){
cat <<EOF 
Usage   : `basename $0` <INPUT> [OUTPUT]
Example : `basename $0` pin_nxb.lc pin_nxb_offset.lc 
EOF
exit 1
}


title(){
cat <<EOF
Version ${version} 
Written by ${author}
EOF
}


offset(){
    inlc=$1
    outlc=$2
    flag=$3

    timezero=`${fkeyprint} ${inlc}+1 TIMEZERO|${sed} -n 's/TIMEZERO=//p'|awk '{print $1}'`
    tstart=`${fkeyprint} ${inlc}+1 TSTART|${sed} -n 's/TSTART  =//p'|awk '{print $1}'`
    
    cat <<EOF

Input FITS file            :  ${inlc}
Output FITS file           :  ${outlc}
OBSERVATION START TIME (s) :  ${tstart}
Origin of TIME AXIS (s)    :  ${timezero} 
EOF

    ${fdump} ${inlc}+1 lctemp.dat "prhead=no" #extract lc data with fdump
    ${sed} '1,/count/d' lctemp.dat > lc.dat # input of hxdlcoffset.c
    ${fdump} ${inlc}+1 head.dat "prdata=no" #extract header of lc with fdump
    ${lcoffset} #lcoffset.dat will be generated


    #column descriptor file for "fcreate"
    cat << EOF > cdf.dat
TIME D s
RATE E count/s
ERROR E count/s
FRACEXP E
EOF

    ${fcreate} cdf.dat lcoffset.dat "headfile=head.dat" ${outlc} "extname=RATE" "clobber=${flag}"
    ${rm} lctemp.dat lc.dat lcoffset.dat
    ${rm} head.dat cdf.dat
    ${fappend} ${inlc}+2 ${outlc} "pkeywds=yes"
    ${fparkey} ${tstart} ${outlc}+1 TIMEZERO "add=no"
    newtimezero=`${fkeyprint} ${outlc}+1 TIMEZERO|${sed} -n 's/TIMEZERO=//p'|awk '{print $1}'`
    
    cat <<EOF

`basename $0` has done.
${outlc} was generated with following parameter.
OBSERVATION START TIME (s) :  ${tstart}
Origin of TIME AXIS (s)    :  ${newtimezero}
EOF
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
if [ $# -eq 0 ] ;then
    usage
else
    if [ _${infile} = _ ] ;then
	echo "Please enter <INPUT> !!"
	File_FLG=FALSE

    elif [ ! -e ${infile} ] ;then
	echo "`basename $0` couldn't find \"${infile}\"."
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
    outfile=${infile%.lc}_offset.lc
fi

title #Show title

if [ ! -f ${outfile} ] ;then
    offset ${infile} ${outfile} no
else
    echo ""
    echo "${outfile} already exists !!" # 1>&2
    echo -n "Overwrite ?? (y/n) >> "
    read answer
    case ${answer} in
        y|Y|yes|Yes|YES)
	    offset ${infile} ${outfile} yes
            ;;

        n|N|no|No|NO)
            echo "`basename $0` has not been executed. "
            ;;

        *)
            echo "`basename $0` has not been executed. "
    esac
fi


#EOF#