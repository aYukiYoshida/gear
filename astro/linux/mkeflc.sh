#!/bin/bash

################################################################################
## mkeflc.sh
################################################################################


################################################################################
## Update
################################################################################
# Ver.  | Date       | Author   | 内容
#---------------------------------------------------------------
# 1.0.2 | 2012.09.10 | yyoshida | -c optionの追加 
# 1.1.0 | 2012.12.11 | yyoshida | optionの記述の仕方の変更 
# 1.2.0 | 2014.08.17 | yyoshida | parameter入力の仕方の変更 
# 1.2.1 | 2014.08.17 | yyoshida | add parameter <CLOBBER>
# 1.3.0 | 2015.07.30 | yyoshida | del <EFSPCO> &add <OUTPUT>,<PERIOD>
#       |            |          | 
#



################################################################################
## Value
################################################################################
version="1.3.0"
author="Y.Yoshida"
shname=`basename $0`
efold=`which efold`
keyprint=`which fkeyprint`
sed=/bin/sed
awk=/usr/bin/awk
norm=1
dpdt=0.0



################################################################################
## Function
################################################################################
usage(){
cat <<EOF
USAGE:
 ${shname} [OPTION] <LCFITS> <PERIOD> [OUTPUT] [BINSIZE] [EPOCH] [DERIVATE] [CLOBBER]

EXAMPLE:
 ${shname} LCFITS=x0_nbg.lc OUTPUT=x0_nbg_eflc.qdp \\
 PERIOD=10.25 BINSIZE=64 EPOCH=15471.28

OPTION:
  -c)   make folded lightcurve in counts/sec

PARAMETER:
   LCFITS   :   Lightcurve FITS file
   OUTPUT   :   Output QDP file
   PERIOD   :   Folding Period in second
   DERIVATE :   Period derivative
   EPOCH    :   EPOCH in TJD (MJD-40000)
   BINSIZE  :   BIN number in Phase (Default : 128)
   CLOBBER  :   If you set "CLOBBER=YES" output will be overwritten

Ver${version} Written by ${author}
EOF
    exit 1
}


log(){
    echo ${shname}: $@
}


################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o hc -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"

while true ;do
  case $1 in
      -h) usage 
	  ;;
      -c) FLG_C="TRUE"
	  norm=0 
	  shift 
	  ;;
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
var5=$5 #;echo ${var5}
var6=$6 #;echo ${var6}
var7=$7 #;echo ${var6}

for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6} ${var7};do
    IFS='='
    set -- ${var}
    par=$1
    val=$2
    #echo "${par}" #DEBUG
    #echo "${val}" #DEBUG
    case ${par} in
        "LCFITS"|"lcfits") lcfits=${val} ;;
        "PERIOD"|"period") bp=${val} ;;
	"OUTPUT"|"output") output=${val} ;;
	"DERIVATE"|"derivate") dpdt=${val} ;;
        "BINSIZE"|"binsize") phasebin=${val} ;;
        "EPOCH"|"epoch") epoch=${val} ;;
	"CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) usage;;
    esac
done #for var in ${var1} ${var2} ${var3} ${var4} ${var5};do

#echo "LCFITS ${lcfits}" #DEBUG
#echo "PERIOD ${bp}" #DEBUG
#echo "OUTPUT ${output}" #DEBUG
#echo "BINSIZE ${phasebin}" #DEBUG
#echo "EPOCH ${epoch}" #DEBUG
#echo "Overwrite ${FLG_OW}" #DEBUG


################################################################################
## Checking source
################################################################################
if [ $# -eq 0 ] ;then
    usage
else
    if [ ! -e ${lcfits} ] ;then
	log "Input FITS file of ${lcfits} was not found"
	File_FLG=FALSE
    elif [ _ = _${lcfits} ] ;then
	log "Please enter <LCFITS> !!"
	File_FLG=FALSE
    fi
    
    if [ _${bp} = _ ] ;then
	log "Please enter <PERIOD> !!"
	File_FLG=FALSE
    fi

    if [ "${File_FLG}" = "FALSE" ];then
	exit 1
    fi


#Output
    if [ _${output} = _ ];then       
	if [ "${FLG_C}" = "TRUE" ];then
	    output=${lcfits%.lc}_eflc_cps.qdp
	else
	    output=${lcfits%.lc}_eflc.qdp
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
                echo "${shname} has not been executed."
		exit 1
                ;;
            *)
                echo "${shname} has not been executed."
		exit 1
        esac
    fi
#OutputEND

    if [ _${phasebin} = _ ];then
	phasebin=128
    fi	

    if [ _${epoch} = _ ];then
	epoch=INDEF
    fi	

fi


#echo ${norm} ##DEBUG


################################################################################
##  make folded light curve
################################################################################
	
###Set Newbins_Interval

${efold} normalization=${norm} dpdot=${dpdt} << EOF 1>/dev/null
1
${lcfits}
-
${epoch}
${bp}
${phasebin}
INDEF
${interval_frame}
default
yes
/null
we ${output}
quit
EOF
	
rm -f ${lcfits%.lc}.fef
log "${output} was generated"

#EOF#
