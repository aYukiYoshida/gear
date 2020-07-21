#!/bin/bash

################################################################################
## Redaction history
################################################################################
# Version | Date       | Author   | Description
#-------------------------------------------------------------------------------
#     2.0 | 2017.09.07 | yyoshida | prototype
#     2.1 | 2019.03.07 | yyoshida | add long options
#


################################################################################
## Set Command & Value
################################################################################

## Value
author="Y.Yoshida"
version="2.1"

srcdir="$HOME"
bakdir="$HOME/Irearmo/backup"
wrkdir=Works

#datdir=tmp
logfile=${bakdir}/$(basename $0)backup.log

## Command
rm="/bin/rm -rf"
link="/bin/ln -sf"
rsync="/usr/bin/rsync -avilz --delete --progress --update"
rm="/bin/rm -rf"
ls='/bin/ls --color -FABGh --show-control-chars --time-style="+%Y-%m-%dT%H:%M:%S" --ignore=".DS_Store" --ignore="Icon?" --ignore=".grive" --ignore=.grive_state --ignore=".trash'


###########################################################################
## Function
###########################################################################
usage(){
    cat <<EOF
USAGE
   `basename $0` <OPTION>

OPTION
   -b,--backup        backup
   -r,--restoration   restoration
   -c,--check         check last running
   -h,--help          show this help script

Ver${version} written by ${author}
EOF
    exit 1
}

message(){
    local logfl=$1
    local script=$2
    local clobber_arg=$3

    case ${clobber_arg} in
	"true"|"True"|"TRUE") clobber=1 ;;
	"false"|"False"|"FALSE") clobber=0 ;;
    esac

    if [ ${clobber} -eq 1 ];then
	echo ${script} | tee ${logfl}
    else
	echo ${script} | tee -a ${logfl}
    fi
}

log(){
    local logfl=$1
    local mode=$2

    message ${logfl} "" true
    message ${logfl} "In last `basename $0` was executed $(date +"at %H":"%M":"%S on %m %d %Y")" false
    
    message ${logfl} "MODE : ${mode}" false
    
}


sync(){
    local src=$1
    local out=$2
    
    ${rsync} ${src} ${out}
}


## List
chk(){
    local bak=$1
    local log=$2
    echo ${bak}
    ${ls} ${bak}
    cat ${log}
}




################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o brcu -l backup -l restoration -l check -l help -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ##DEBUG

while true ;do
  case $1 in
      -h|--help) usage
          ;;
      -c|--check) FLG_c="TRUE"
	  shift
	  ;;
      -b|--backup) FLG_b="TRUE" #;echo ${FLG_b}
	  shift
	  ;;
      -r|--restoration) FLG_r="TRUE" #;echo ${FLG_r}
	  shift
	  ;;
      --) shift ; break 
          ;;
       *) usage 
          ;;
  esac
done

#echo "\$@=$@" ##DEBUG
#echo "\$#=$#" ##DEBUG


#checking
if [ "${FLG_c}" = "TRUE" ]&&[ "x${FLG_r}" = "x" -a "x${FLG_b}" = "x" ];then
	chk ${bakdir} ${logfile}
	
#restoration
elif [ "${FLG_r}" = "TRUE" ]&&[ "x${FLG_c}" = "x" -a "x${FLG_b}" = "x" ];then 
    sync ${bakdir}/${wrkdir}/ ${srcdir}/${wrkdir}     
    log ${logfile} "RESTORATION"
	
#backup
elif [ "${FLG_b}" = "TRUE" ]&&[ "x${FLG_r}" = "x" -a "x${FLG_c}" = "x" ];then 
    sync ${srcdir}/${wrkdir}/ ${bakdir}/${wrkdir}
    log ${logfile} "BACKUP"
    
else
    usage
fi


#EOF#

