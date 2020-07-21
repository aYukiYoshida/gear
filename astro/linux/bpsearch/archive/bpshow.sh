#!/bin/bash

###############
## bpshow.sh ##
###############

#efsearchで作成したPCO fileを読み込み、efsearchで調べたベストの周期を表示する。


################################################################################
## Update
################################################################################
# Ver.  | Date       | Author   | 内容
#-------------------------------------------------------------------------------
# 1.0.0 | 2012.**.** | yyoshida | prototype
# 1.1.0 | 2015.05.18 | yyoshida | add option 
# 1.1.1 | 2015.05.18 | yyoshida | add -n option 


################################################################################
## Set Command & Value
################################################################################
cat=/bin/cat
sed=/bin/sed



################################################################################
## Function
################################################################################
usage(){
    cat <<EOF
USAGE:
   `basename $0` [OPTION] <efsearch PCO FILE>
EXAMPLE: 
   `basename $0` x2_nbg_efs.pco

OPTION:
   -h)  Show Usage
   -n)  Present only BestPeriod value
EOF
    exit 1 
} 



################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o un -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"
while true ;do
  case $1 in
      -h) usage 
          ;;
      -n) FLG_N="TRUE"
	  shift
	  ;;
      --) shift ; break 
          ;;
       *) usage 
          ;;
  esac
done


################################################################################
## MAIN
################################################################################
head=$1
if [ _${head} = _ ];then
    usage

elif [ -e ${head} ];then
    if [ "${FLG_N}" = "TRUE" ];then
	sed -n "/Best Period/p" ${head}|awk '{printf "%17.15f\n" , $8}'
    else
	sed -n "/Best Period/p" ${head}|awk '{printf "Best Period = %17.15f\n" , $8}'
    fi
else
    echo "`basename $0` couldn't find $1"
fi


#EOF#