#!/bin/bash

#################
## bpsearch.sh ##
#################

#efsearchでベストの周期を細かく調べていくのを楽にするスクリプト。

################################################################################
## Update
################################################################################
# Ver.  | Date       | Author   | 
#-------------------------------------------------------------------------------
# 1.0.0 | 2012.XX.XX | yyoshida | prototype
# 1.1.0 | 2015.05.13 | yyoshida | option導入
# 2.0.1 | 2015.05.13 | yyoshida | parameterのinput方法変更
# 2.1.0 | 2015.05.19 | yyoshida | OUTPUTをadditional parameterに変更
# 3.0.0 | 2015.05.19 | yyoshida | search開始のperiodを入力して実行するように変更と同時に
#       |            |          | efsearchのPCOを不要に変更
# 3.0.1 | 2015.06.10 | yyoshida | add parameter of NPS
#


##################################################################################
## Value
##################################################################################
author="Y.Yoshida"
version="3.0.1"
cat=/bin/cat
sed=/bin/sed
awk=/usr/bin/awk
search=`which efsearch`
keyprint=`which fkeyprint`




##################################################################################
## Title
##################################################################################
${cat} <<EOF
Version ${version}
Written by ${author}

EOF


##################################################################################
## Function
##################################################################################
usage(){
    ${cat} <<EOF
<Usage>
  `basename $0` <LCFITS> <PERIOD> <RESOLUTION> [NPS] [OUTPUT] [CLOBBER]

<EXAMPLE>
  `basename $0` LCFITS=x0_nbg.lc PERIOD=130 RESOLUTION=0.01 OUTPUT=x0_efs.qdp 

<PARAMETERS>
  LCFITS     : Lightcurve FITS file
  PERIOD     : initial value of period 
  RESOLUTION : efsearch Resolution value
  NPS        : Number of Period to efsearch
  OUTPUT     : Output QDP file
  CLOBBER    : If you set "CLOBBER=YES" output will be overwritten
EOF
    exit 1
}




################################################################################
## OPTION
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

#echo $@ ##DEBUG


################################################################################
## MAIN
################################################################################
if [ $# -eq 0 ];then
    usage
else
    var1=$1 #;echo ${var1}
    var2=$2 #;echo ${var2}
    var3=$3 #;echo ${var3}
    var4=$4 #;echo ${var4}
    var5=$5 #;echo ${var5}
    var6=$6 #;echo ${var6}
fi

for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6};do
    IFS='='
    set -- ${var}
    par=$1
    val=$2
   # echo "${par}" #DEBUG
   # echo "${val}" #DEBUG
    case ${par} in
        "LCFITS"|"lcfits") lcfits=${val} ;;
        "PERIOD"|"period") BP=${val} ;;
        "RESOLUTION"|"resolution") Resolution=${val} ;;
        "OUTPUT"|"output") output=${val} ;;
	"NPS"|"nps") NPS=${val} ;;
	"CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) usage;;
    esac
done #for var in ${var1} ${var2} ${var3} ${var4} ;do


if [ ! -e ${lcfits} ];then
    echo "`basename $0` couldn't find \"${lcfits}\" file."
    FLG_ERR="TRUE"
fi
if [ _${BP} = _ ];then
    echo "Please enter <PERIOD> value."
    FLG_ERR="TRUE"
fi
if [ _${Resolution} = _ ];then
    echo "Please enter <RESOLUTION> value."
    FLG_ERR="TRUE"
fi 
if [ "${FLG_ERR}" = "TRUE" ] ;then
    echo "`basename $0` has not been executed."
    exit 1 
fi
    

if [ _${NPS} = _ ] ;then
    NPS=128
fi

${cat} <<EOF
`basename $0` is searching BestPeriod with following value
Period                       :  ${BP}
Resolution                   :  ${Resolution}
Number of Periods to Search  :  ${NPS}
EOF
    
    
if [ _${output} = _ ] ;then
    output=${lcfits%.lc}_efs.qdp
fi


if [ "${FLG_OW}" = "YES" ]||[ "${FLG_OW}" = "yes" ] ;then
    rm -f ${output}
    rm -f ${output%.qdp}.pco
fi

if [ -f ${output} ] ;then
    echo ""
    echo "${output} already exists !!" # 1>&2
    echo -n "Overwrite ?? (y/n) >> "
    read answer
    case ${answer} in
	y|Y|yes|Yes|YES)
	    rm -f ${output}
	    rm -f ${output%.qdp}.pco
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


## Setup efsearch value
    
Epoch=INDEF
PhaseBin=256
Newbin_Interval=INDEF
    
## Search Best Period
${search} << EOF 1>/dev/null
${lcfits}
-
${Epoch}
${BP}
${PhaseBin}
${Newbin_Interval}
${Resolution}
${NPS}
default
yes
/null
we ${output}
q
EOF

${cat} <<EOF

`basename $0` finished and generated ${output}
Please check calculated BestPeriod with "bpshow.sh"
% bpshow.sh ${output%.qdp}.pco
EOF


rm -f ${lcfits%.lc}.fes



#EOF#