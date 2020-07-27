#!/bin/bash

###########################################################################
## Value
###########################################################################
# date=$(date +"%Y%m%d")
OS=$(uname)
SCRIPTFILE=$0
[ -L ${SCRIPTFILE} ] && SCRIPTFILE=$(readlink ${SCRIPTFILE})
SCRIPTNAME=$(basename ${SCRIPTFILE%.*})

TARGET=$HOME/Dropbox/pocket
TARGET_NAME=$(basename ${TARGET})
[ ! -d ${TARGET} ] && mkdir -p ${TARGET} 


###########################################################################
## Function
###########################################################################
usage(){
    echo "USAGE" 
    echo "    ${SCRIPTNAME} [OPTION] FILE... [-f DIRECTORY]"
    echo "OPTION"
    echo "    -c,--copy         Copy file to ${TARGET_NAME}"
    echo "    -d,--dust         Trash all files in ${TARGET_NAME}"
    echo "    -f,--fetch        Fetch file from ${TARGET_NAME}"
    echo "    -h,--help         Show this help message"
    echo "    -l,--list         List files in ${TARGET_NAME}"
    echo "    -u,--usage        Synonymous with -h or --help"
    exit 0
}

abort(){
    local message=$1
    echo ${message} 1>&2
    exit 1
}

dustshoot(){
    local box=$1
    if [ ! -d ${box} ];then
	    echo "There is no file or directory in ${box}"
    else
        case ${OS} in
            "Linux")
                trash-put ${box}/*
                ;;
            "Darwin")
                mv ${box}/* $HOME/.Trash 2>/dev/null
                ;;
        esac    
	    echo "Trash all files in ${box}"
    fi
    exit 0    
}

list_target_directory(){
    local box=$1
    echo ${box}
    ls --color -FBGh --ignore=".DS_Store" --ignore=".dropbox" --ignore="Icon?" ${box}
    exit 0
}


###########################################################################
## MAIN
###########################################################################
if [ $# -eq 0 ];then
    usage
else

    # Initialization of Flags
    FLG_C=0
    FLG_F=0

    GETOPT=$(getopt -q -o cdf:hlu --long copy,dust,fetch,help,list,usage -- "$@")
    [ $? != 0 ] && abort "Invalid option"
    eval set -- "$GETOPT"

    while true ;do
        case $1 in
            -h|-u|--help|--usage) usage ;;
            -l|--list) list_target_directory ${TARGET} ;;
            -d|--dust) dustshoot ${TARGET} ;;
            -c|--copy) 
                FLG_C=1
                shift ;;
            -f|--fetch) 
                FLG_F=1
                dstdir=$2
                shift 2 ;;
            --) shift;break ;;
            *) usage ;; 
        esac
    done

    # echo "FLG_C=${FLG_C}" ## DEBUG
    # echo "FLG_F=${FLG_F}" ## DEBUG

    # FETCH
    if [ ${FLG_F} -eq 1 ];then
        if [ -z ${dstdir} ]||[ ! -d ${dstdir} ]||[ ${dstdir} = ${TARGET} ];then
            abort "Please enter destination !!"
        else
            if [ $# -eq 0 ];then
                mv ${TARGET}/* ${dstdir}
            else
                while [ $# -ne 0 ];do
                    if [ -e ${TARGET}/$1 ];then
                        mv ${TARGET}/$1 ${dstdir}
                    else
                        echo "${SCRIPTNAME} couldn't find \"$1\"." 1>&2
                    fi
                    shift 1                
                done
            fi
        fi

    # DROP
    else
        while [ $# -ne 0 ];do
            if [ -e $1 ];then
                if [ ${FLG_C} -eq 1 ];then
                    cp -r $1 ${TARGET}
                else
                    mv $1 ${TARGET}
                fi
            else
                echo "${SCRIPTNAME} couldn't find \"$1\"." 1>&2
            fi
            shift 1        
        done
    fi
fi



#EOF#
