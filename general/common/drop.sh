#!/bin/bash

###########################################################################
## Value
###########################################################################
#date=`date +"%Y%m%d"`
author="Y.Yoshida"
os=`uname`


###########################################################################
## Function
###########################################################################
usage(){
    local box=$1
    if [[ _${box} = _ ]];then
        box_name="the target directory in the Dropbox"
    else
        box_name=`basename ${box}`
    fi
    echo "USAGE" 
    echo "    `basename $0` [OPTION] FILE... [-f DIRECTORY]"
    echo "OPTION"
    echo "    -c,--copy         Copy file to ${box_name}"
    echo "    -d,--dust         Trash all files in ${box_name}"
    echo "    -f,--fetch        Fetch file from ${box_name}"
    echo "    -h,--help         Show this help message"
    echo "    -l,--list         List files in ${box_name}"
    echo "    -u,--usage        Synonymous with -h or --help"
    echo "    -t,--transport    Change target directory to transport"
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
        case $os in
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

lstdir(){
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
    FLG_L=0
    FLG_T=0
    FLG_F=0
    FLG_D=0

    GETOPT=`getopt -q -o cdf:hlut --long copy,dust,fetch,help,list,usage,transport -- "$@"` ; [ $? != 0 ] && usage
    eval set -- "$GETOPT"

    while true ;do
        case $1 in
            -h|-u|--help|--usage) 
                usage ;;
            -l|--list) 
                FLG_L=1
                shift ;;
            -d|--dust) 
                FLG_D=1
                shift ;;
            -c|--copy) 
                FLG_C=1
                shift ;;
            -t|--transport) 
                FLG_T=1
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
    # echo "FLG_L=${FLG_L}" ## DEBUG
    # echo "FLG_T=${FLG_T}" ## DEBUG
    # echo "FLG_F=${FLG_F}" ## DEBUG
    # echo "FLG_D=${FLG_D}" ## DEBUG

    if [ ${FLG_T} -eq 1 ];then
        dropbox=$HOME/Dropbox/transport
    else
        dropbox=$HOME/Dropbox/pocket
    fi

    [ ! -d ${dropbox} ] && mkdir -p ${dropbox} 

    # LIST
    if [ ${FLG_L} -eq 1 ];then
        lstdir ${dropbox}
    elif [ ${FLG_D} -eq 1 ];then
        dustshoot ${dropbox}
    fi

    # FETCH
    if [ ${FLG_F} -eq 1 ];then
        if [ -z ${dstdir} ]||[ ! -d ${dstdir} ]||[ ${dstdir} = ${dropbox} ];then
            abort "Please enter destination !!"
        else
            if [ $# -eq 0 ];then
                mv ${dropbox}/* ${dstdir}
            else
                while [ $# -ne 0 ];do
                    if [ -e ${dropbox}/$1 ];then
                        mv ${dropbox}/$1 ${dstdir}
                    else
                        echo "`basename $0` couldn't find \"$1\"." 1>&2
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
                    cp -r $1 ${dropbox}
                else
                    mv $1 ${dropbox}
                fi
            else
                echo "`basename $0` couldn't find \"$1\"." 1>&2
            fi
            shift 1        
        done
    fi
fi



#EOF#
