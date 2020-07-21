#!/usr/bin/zsh

##############################################################################
## Function
##############################################################################
cmdname=`basename $0`

usage(){
    echo "USAGE: ${cmdname} [-r|-l|-t] [-a] <FILE>" 1>&2
    exit 0
}

is_postscript(){
    local image_file=$1
    local check_result=$(file ${image_file})
    if [[ ${check_result} = *PostScript* ]];then
        echo 1  # postscript
    else
        echo 0  # otherwise
    fi
}

mkeps(){
    local image_file=$1
    local rotation_flag=$2
    local filetype=$(is_postscript x1_phase_09_01_circle7.ps)

    if [ ${filetype} -eq 1 ];then
        local ps_file=${image_file}
    else
        local ps_file=${image_file%.*}.ps
        convert ${image_file} ps2:${ps_file} && rm -f ${image_file}
    fi

    #ps2eps ${defopt} -R + ${finpsfl}
    case ${frotflg} in
        rig|RIG) /usr/bin/ps2eps --ignoreBB -f -l -R + ${ps_file} ;;
        lef|LEF) /usr/bin/ps2eps --ignoreBB -f -l -R - ${ps_file} ;;
        usd|USD) /usr/bin/ps2eps --ignoreBB -f -l -R ^ ${ps_file} ;;
        *) /usr/bin/ps2eps --ignoreBB -f -l ${ps_file} ;;
    esac
    rm -f ${ps_file} 
    #echo "${finpsfl%.ps}.eps was generated !!"
}


##############################################################################
## Option
##############################################################################
FLG_R=0
FLG_L=0
FLG_T=0

GETOPT=`getopt -q -o rltua -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"

while true ;do
    case $1 in
        -u) usage ;;
        -r) FLG_R=1; ROTFLG="rig"; shift ;;
        -l) FLG_L=1; ROTFLG="lef"; shift ;;
        -t) FLG_T=1; ROTFLG="usd"; shift ;;
        --) shift; break ;;
        *)  usage ;;
    esac
done


##############################################################################
## Main
##############################################################################
if [ $# -eq 0 ]&&[ "${FLG_A}" != "TRUE" ];then
    #echo $#  ## DEBUG
    usage
else
    if [ ${FLG_R} -eq 1 -a ${FLG_L} -eq 1 ]||[ ${FLG_L} -eq 1 -a ${FLG_T} -eq 1 ]||[ ${FLG_T} -eq 1 -a ${FLG_R} -eq 1 ];then
	    usage
    else
        for image_file in $@ ;do
            if [ -e ${psfile} ];then
                mkeps ${image_file} ${ROTFLG}
            else
                echo "${cmdname} couldn't find ${image_file}."
            fi
        done
    fi
fi


#EOF#
