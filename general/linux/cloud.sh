#!/bin/bash -u

################################################################################
## Set Values
################################################################################
AUTHOR="Y.Yoshida"
SCRIPTFILE=$(basename $0)
SCRIPTNAME=${SCRIPTFILE%.*}

## Backup dirctory
BACK=$HOME/Irearmo/backup
#datdir=tmp
LOGFILE=${BACK}/${SCRIPTNAME}backup.log


###########################################################################
## Function
###########################################################################
usage(){
    echo "USAGE"
    echo "   ${SCRIPTNAME} <OPTION>"
    echo ""
    echo "OPTION"
    echo "   -b,--backup        backup"
    echo "   -r,--restoration   restoration"
    echo "   -c,--check         check last running"
    echo "   -h,--help          show this help script"
    echo ""
    echo "written by ${AUTHOR}"
    exit 0
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


## List
chk(){
    local bak=$1
    local log=$2
    echo ${bak}
    ls --color -FABGh --show-control-chars --ignore=".DS_Store" --ignore="Icon?" --ignore=".grive" --ignore=.grive_state --ignore=".trash" ${bak}
    cat ${log}
}


################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o brcuh -l backup,restoration,check,usage,help -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ##DEBUG

FLG_C=0
FLG_B=0
FLG_R=0

while true ;do
    case $1 in
        -h|--help|-u|--usage) usage;;
        -c|--check)       FLG_C=1; shift;;
        -b|--backup)      FLG_B=1; shift;;
        -r|--restoration) FLG_R=1; shift;;
        --) shift; break;;
        *) usage;;
    esac
done

#echo "\$@=$@" ##DEBUG
#echo "\$#=$#" ##DEBUG


#checking
if [ ${FLG_C} -eq 1 ]&&[ ${FLG_R} -eq 0  -a ${FLG_B} -eq 0 ];then
	chk ${BACK} ${LOGFILE}
	
#restoration
elif [ ${FLG_R} -eq 1 ]&&[ ${FLG_C} -eq 0 -a ${FLG_B} -eq 0 ];then
    rsync -avilz --delete --progress --update $BACK/Works/ $HOME/Works
    log ${LOGFILE} "RESTORATION"
	
#backup
elif [ ${FLG_B} -eq 1 ]&&[ ${FLG_R} -eq 0 -a ${FLG_C} -eq 0 ];then 
    rsync -avilz --delete --progress --update --exclude "Tools" $HOME/Works/ $BACK/Works
    log ${LOGFILE} "BACKUP"
    
else
    usage
fi


#EOF#

