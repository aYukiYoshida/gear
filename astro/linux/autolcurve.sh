#!/bin/bash

################################################################################
## mklc.sh
################################################################################
## lcurveを対話形式ではなく、一発でlight curveを作成する。
##


################################################################################
## Update
################################################################################
# Ver.  | Date       | Author   | 内容
#---------------------------------------------------------------
# 1.0.0 | 2015.06.06 | yyoshida | prototype
# 1.1.0 | 2016.05.30 | yyoshida | tunit指定記述追加
# 1.2.0 | 2016.05.30 | yyoshida | hardness ratio機能追加
#


################################################################################
## Value
################################################################################
version="1.1.0"
author="Y.Yoshida"
lcurve=`which lcurve`
keyprint=`which fkeyprint`
sed=/bin/sed
awk=/usr/bin/awk
maxnewbin=100000 #lcurve parameter


################################################################################
## Function
################################################################################
title(){
    cat <<EOF 
Version ${version}
Written by ${author}

EOF
}


usage(){
cat <<EOF
USAGE
   `basename $0` <LCFITS> [BINSIZE] [OUTPUT] [CLOBBER] [-h LCFITS] [-m NUM]

EXAMPLE
   `basename $0` LCFITS=x0_nbg.lc BINSIZE=64 OUTPUT=x0_nbg_lc.qdp

PARAMETERS
  <LCFITS>   :  Lightcurve FITS File
  [BINSIZE]  :  BINSIZE of Lightcurve (Default : 128)
  [OUTPUT]   :  Output Lightcurve (QDPFILE)
  [CLOBBER]  :  If you set "CLOBBER=YES" output will be overwritten

OPTION
  -h LCFITS : hardness ratio mode. 
  -m NUM    : multi layer plot mode. filelist should be inputed. 
  
EOF
    exit 1
}


title ## show title
################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o uh:m: -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"

while true ;do
  case $1 in
      -u) usage 
	  ;;
      -m) FLG_m=TRUE
	  m_num=$2
	  shift 2 ;;
      -h) FLG_h=TRUE
	  h_lcfits=$2
	  shift 2 ;;
      --) shift ; break 
	  ;;
       *) usage 
	  ;;
  esac
done


################################################################################
## Set parameter
################################################################################

##Input
var1=$1 #;echo ${var1}
var2=$2 #;echo ${var2}
var3=$3 #;echo ${var3}
var4=$4 #;echo ${var4}

for var in ${var1} ${var2} ${var3} ${var4};do
    IFS='='
    set -- ${var}
    par=$1
    val=$2
    #echo "${par}" #DEBUG
    #echo "${val}" #DEBUG
    case ${par} in
        "LCFITS"|"lcfits") lcfits=${val} ;;
        "BINSIZE"|"binsize") binsize=${val} ;;
        "OUTPUT"|"output") output=${val} ;;
	"CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) usage;;
    esac
done #for var in ${var1} ${var2} ${var3} ${var4} ;do

#echo "LCFITS ${lcfits}" #DEBUG
#echo "BINSIZE ${binsize}" #DEBUG
#echo "OUTPUT ${output}"  #DEBUG
#echo "Overwrite ${FLG_OW}" #DEBUG

#Output


################################################################################
## Checking source
################################################################################
if [ $# -eq 0 ] ;then
    usage
else
    if [ ! -e ${lcfits} ]||[ _ = _${lcfits} ] ;then
	echo "`basename $0` couldn't find <LCFITS>"
	File_FLG=FALSE
    fi

    if [ "${FLG_h}" = "TRUE" ]&&[ "${FLG_m}" = "TRUE" ];then
	echo "`basename $0` cann't execute with both option, \"-h\" and \"-m\" at the same time."
	File_FLG=FALSE
    fi

    if [ "${File_FLG}" = "FALSE" ];then
	echo "`basename $0` has not been executed."
	exit 1
    fi
    
    if [ _${binsize} = _ ];then
	binsize=128
    fi

    if [ _ = _${output} ] ;then
	if [ "${FLG_h}" = "TRUE" ];then
	    output=${lcfits%.lc}_hdratio.qdp
	else
            output=${lcfits%.lc}_lc.qdp
	fi
    fi

    if [ "${FLG_OW}" = "YES" ]||[ "${FLG_OW}" = "yes" ] ;then
        rm -f ${output} ${output%.qdp}.pco
    fi

    if [ -f ${output} ] ;then
        echo ""
        echo "${output} already exists !!" # 1>&2
        echo -n "Overwrite ?? (y/n) >> "
        read answer
        case ${answer} in
            y|Y|yes|Yes|YES)
		rm -f ${output} ${output%.qdp}.pco
                ;;
            
            n|N|no|No|NO)
                echo "`basename $0` has not been executed."
                exit 1
                ;;
            *)
                echo "`basename $0` has not been executed."
                exit 1
        esac
    fi

################################################################################
##  make light curve
################################################################################

    ## for hardness ratio
    if [ "${FLG_h}" = "TRUE" ];then 
	if [ ! -e ${h_lcfits} ]||[ _ = _${lcfits} ] ;then
	    echo "`basename $0` couldn't find <LCFITS> !!"
	    File_FLG=FALSE
	fi
	
	if [ "${File_FLG}" = "FALSE" ];then
	    echo "`basename $0` has not been executed."
	    exit 1
	fi
	
    ## Search <MAXIMUMNEWBINSIZE>
	echo "Input FITS Files  :  ${lcfits}"
	echo "                     ${h_lcfits}"
	echo "`basename $0` is generating ${output} with following value:"
	echo "time binsize  :  ${binsize}"
	
	${lcurve} "tunit=1" << EOF |tee temp.txt 1>/dev/null
2
${lcfits}
${h_lcfits}
-
${binsize}
${maxnewbin}
autolcurve.flc
no
EOF
	
    ##Set <MAXIMUMNEWBINSIZE>
	maxnewbin=`sed -n '/(giving/p' temp.txt|awk '{printf "%d\n",$2*$5}'`
	#echo ${maxnewbin} #DEBUG
	
	
	${lcurve} "tunit=1" << EOF 1>/dev/null
2
${lcfits}
${h_lcfits}
-
${binsize}
${maxnewbin}
autolcurve.flc
yes
/null
3
we ${output}
quit
EOF
	
	rm -f  temp.txt autolcurve.flc
	cat <<EOF
Finish !! 
`basename $0` generated ${output}
EOF
	
	
    ## for lcurve multi layer plot
    elif [ "${FLG_m}" = "TRUE" ];then
	if [ ${m_num} -lt 2 ]||[ ${m_num} -ge 5 ];then
	    echo "`basename $0` must be executed without -m option!!"
	    File_FLG=FALSE
	fi
	
	if [ "${File_FLG}" = "FALSE" ];then
	    echo "`basename $0` has not been executed."
	    exit 1
	fi
	
	echo "Input listfile:${lcfits} included ${m_num} FITS Files"
	sed '/\/\/\//d' ${lcfits} |sed 's/^/   /g'
	echo "`basename $0` is generating ${output} with following value:"
	echo "time binsize  :  ${binsize}"
	
	${lcurve} "tunit=1" << EOF |tee temp.txt 1>/dev/null
${m_num}
@${lcfits}
-
${binsize}
${maxnewbin}
autolcurve.flc
no
EOF
    
    
	
    ###Set <MAXIMUMNEWBINSIZE>
	maxnewbin=`sed -n '/(giving/p' temp.txt|awk '{printf "%d\n",$2*$5}'`
	#echo ${maxnewbin} #DEBUG


	${lcurve} "tunit=1"<< EOF 1>/dev/null
${m_num}
@${lcfits}
-
${binsize}
${maxnewbin}
autolcurve.flc
yes
/null
${m_num}
we ${output}
quit
EOF

	rm -f  temp.txt autolcurve.flc
	cat <<EOF

Finish !! 
`basename $0` generated ${output}
EOF


    else 
	echo "Input FITS File  :  ${lcfits}"
	echo "`basename $0` is generating ${output} with following value:"
	echo "time binsize  :  ${binsize}"
    
	${lcurve} "tunit=1" << EOF |tee temp.txt 1>/dev/null
1
${lcfits}
-
${binsize}
${maxnewbin}
autolcurve.flc
no
EOF
    
    
	
    ###Set <MAXIMUMNEWBINSIZE>
	maxnewbin=`sed -n '/(giving/p' temp.txt|awk '{printf "%d\n",$2*$5}'`
	#echo ${maxnewbin} #DEBUG


	${lcurve} "tunit=1"<< EOF 1>/dev/null
1
${lcfits}
-
${binsize}
${maxnewbin}
autolcurve.flc
yes
/null
we ${output}
quit
EOF

	rm -f  temp.txt autolcurve.flc
	cat <<EOF

Finish !! 
`basename $0` generated ${output}
EOF

    fi
fi

#EOF#
