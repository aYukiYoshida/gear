#!/bin/bash -u

################################################################################
## Value
################################################################################
command=`basename $0`

################################################################################
## Function
################################################################################

usage(){
    echo "${command} -- Change Text Encooding "
    echo ""
    echo "USAGE: ${command} <OPTION> <FILE>"
    echo "OPTIONS:"
    echo "    -h) show this help message"
    echo "    -s) change encood of <FILE> to Shift-JIS"
    echo "    -e) change encood of <FILE> to EUC-JP"
    echo "    -w) change encood of <FILE> to UTF-8"
    echo "    -a) change encood for all text and tex file in directory"
}

change(){
    local option=$1
    local file=$2
    nkf --in-place ${option} ${file}
    NAME=`nkf -g $2`
    echo "${command} change encood of $2 to ${NAME}"
}


################################################################################
## OPTION
################################################################################
FLG_E=0
FLG_S=0
FLG_W=0
option=""

GETOPT=`getopt -q -o husew --long help,usage -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"

while true ;do
    case $1 in
        -h|--help|-u|--usage) usage; exit 0;;
        -e) FLG_E=1; option=$1; shift ;;
        -s) FLG_S=1; option=$1; shift ;;
        -w) FLG_W=1; option=$1; shift ;;
        --) shift; break ;;
        *) usage ;;
    esac
done

# echo $FLG_E
# echo $FLG_S
# echo $FLG_E

################################################################################
## Main
################################################################################
if [ ${FLG_E} -eq 1 -a ${FLG_S} -eq 1 ]||[ ${FLG_E} -eq 1 -a ${FLG_W} -eq 1 ]||[ ${FLG_S} -eq 1 -a ${FLG_W} -eq 1 ];then
    usage; exit 1
elif [ -n ${option} ];then
    echo "Enter one option at least" && exit 1
else
    file=$1 # input file
    if [ -e ${file} ];then 
        change ${OPTION} ${file}
    else
        echo "${file} is not found"
    fi
fi



#EOF
