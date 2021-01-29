#!/bin/bash
set -Ceu


##--------------------------------------------------------------------------------
## Set Command & Value
##--------------------------------------------------------------------------------
AUTHOR="Y.Yoshida"
VERSION=3.0
SCRIPTFILE=$0
[ -L ${SCRIPTFILE} ] && SCRIPTFILE=$(readlink $0)
SCRIPTNAME=$(basename ${SCRIPTFILE%.*})


##--------------------------------------------------------------------------------
## Function
##--------------------------------------------------------------------------------
title(){
    echo "${SCRIPTNAME} written by ${AUTHOR} (v${VERSION})"
    echo ""
}

usage(){
    title
    echo "USAGE"
    echo "    ${SCRIPTNAME} [OPTION] <SOURCE> <DESTINATION>"
    echo "OPTIONS"
    echo "    -h    Show this help script"
    echo "    -u    Synonymous with -h or --help"
    echo ""
}

show_dir(){
    local src=$1
    local out=$2
    echo "source      : ${src}"
    echo "destination : ${dst}"
}

gensymlink(){
    echo ""
    echo "Generate symbol links following files and directory."
    echo "========================================================================================"

    for i in $@ ;do
        echo "  ${i}"
        ln -sf ${src_fullpath}/${i}
    done
    echo "========================================================================================"
    echo "Finish."
}


##--------------------------------------------------------------------------------
## parse options
##--------------------------------------------------------------------------------
optstrings="uh"

for char in {a..z}; do
    [[ ${optstrings} == *${char}* ]] && eval opt_flag_${char}=0
done

parsedopts=$(getopt -q -o ${optstrings} -- "$@"); [ $? != 0 ] && usage
eval set -- "$parsedopts"

while true ;do
    case $1 in
        -h|-u) usage; exit 0 ;;
        --) shift; break ;;
        *) usage; exit 1 ;;
    esac
done


##--------------------------------------------------------------------------------
## Main
##--------------------------------------------------------------------------------
if [ $# -ne 2 ];then
    usage; exit 1
else
    src=$1
    dst=$2; [ -e ${dst} ] || mkdir ${dst}
    cwd=$(command pwd)
    dst_fullpath=$(command cd ${dst}; pwd)
    src_fullpath=$(command cd ${src}; pwd)
    src_list=$(command ls ${src_fullpath})
    echo ${src_list}
    title && show_dir ${src} ${dst}
    cd ${dst} && gensymlink ${src_list} && cd ${cwd}
fi

#EOF#