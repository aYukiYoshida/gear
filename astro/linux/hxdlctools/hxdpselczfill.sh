#!/bin/bash


################################################################################
## Redaction History
################################################################################
# Ver.  | Date       | Author   | ∆‚Õ∆
#-------------------------------------------------------------------------------
# 1.0.0 | 2015.06.04 | yyoshida | prototype
# 1.0.1 | 2015.06.08 | yyoshida | add script of appending GTI Extension



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
lcfill="/data09/yyoshida/Data/Suzaku/A0535_262/Tools/hxdpselczfill"


################################################################################
#Function
################################################################################
usage(){
cat <<EOF 
Usage   : `basename $0` <INPUT> [OUTPUT]
Example : `basename $0` pin_pse.lc pin_pse_fill.lc 
EOF
exit 1
}


title(){
cat <<EOF
Version ${version} 
Written by ${author}
EOF
}


fill(){ #usage fill pin_pse.lc pin_pse_zfill.lc no
    pselc=$1
    outlc=$2
    flag=$3

    ${fdump} ${pselc}+1 pselctemp.dat "prhead=no" #extract lc data with fdump
    sed '1,/count/d' pselctemp.dat > pselc.dat # input of hxdpselczfill.c
    ${fdump} ${pselc}+1 head.dat "prdata=no" #extract header of lc with fdump
    ${lcfill} #pselcout.dat was generated
cat <<EOF

Input FITS file  : ${pselc}
Output FITS file : ${outlc}
`basename $0` has done.
EOF

    #column descriptor file for "fcreate"
    cat << EOF > cdf.dat
TIME D s
RATE E count/s
ERROR E count/s
FRACEXP E
EOF

    ${fcreate} cdf.dat pselcout.dat "headfile=head.dat" ${outlc} "extname=RATE" "clobber=${flag}"
    ${rm} pselctemp.dat pselc.dat pselcout.dat
    ${rm} head.dat cdf.dat
    ${fappend} ${pselc}+2 ${outlc} "pkeywds=yes" #append GTI Extension
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
    outfile=${infile%.lc}_zfill.lc
fi

title

if [ ! -f ${outfile} ] ;then
    fill ${infile} ${outfile} no
else
    echo ""
    echo "${outfile} already exists !!" # 1>&2
    echo -n "Overwrite ?? (y/n) >> "
    read answer
    case ${answer} in
        y|Y|yes|Yes|YES)
	    fill ${infile} ${outfile} yes
            ;;

        n|N|no|No|NO)
            echo "`basename $0` has not been executed. "
            ;;

        *)
            echo "`basename $0` has not been executed. "
    esac
fi


#EOF#