#!/bin/bash

############################################
#               Useful MEMO                #
############################################

################################################################################
## Set Command & Value
################################################################################

## Value
author="Y.Yoshida"
version="3.1"
os=$(uname)
host=$(hostname)
shellscript=$0 #; echo ${shellscript} ##DEBUG
cmdname=$(basename ${shellscript})
logLevelCriteria=1
if [ -L ${shellscript} ];then
    shellscript=$(readlink $0) #; echo ${shellscript} ##DEBUG
fi
srcdir=$(dirname ${shellscript})/static #; echo ${srcdir} ##DEBUG

################################################################################
## Set Function
################################################################################
logger(){
    local lvl=$1
    local txt=$2
    case ${lvl} in
        0) local sta="DEBUG" ;;
        1) local sta="INFO" ;;
        2) local sta="ERROR" ;;
    esac
    [ ${lvl} -ge ${logLevelCriteria} ] && echo "[${sta}] ${txt}"
}

abort(){
    local evt=$1
    case ${evt} in
        "InitLetter")     local message="Initializing letters were exceeded !!" ;;
        "NullInput")      local message="Please input file name !!" ;;
        "ExceededInput")  local message="Input was exceeded !!" ;;
        "NoExistInput")   local message="Input was not found !!" ;;
        "InvalidOption")  local message="Invalid input option !!" ;;
        "MultipleOption") local message="-e, -l and -d options cannot be specified at the same time !!" ;;
        "ZeroQuery")      local message="Insufficient query !!" ;;
        *)                local message="Abort !!" ;;
    esac
    logger 2 "${message}"
    exit 1
}

## Clean
clean(){
    local bkupflnum=`ls -1|sed -n '/~/p'|wc -l` 
    [ ${bkupflnum} -ne 0 ] && rm -f ${srcdir}/*~*
    logger 0 "All backup files were deleted !!"
}

## Title
title(){
    echo "${cmdname} -- useful scripts written by ${author} version ${version}"
    echo ""
}

## Usage
usage(){
    title #show title
    echo "USAGE"
    echo "    ${cmdname} [OPTION] <INPUT>"
    echo "OPTIONS"
    [ ${host} = "sir" ] && echo "  -b,--backup     Backup all useful memos"
    echo "  -d,--delete     Delete useful memo"    
    echo "  -e,--edit       Edit useful memo"
    echo "  -h,--help       Show this help script"
    echo "  -i,--initial    Select initial"
    echo "  -l,--list       List useful memos"
    echo "  -r,--random     Show Randomly useful memo"
    echo "  -s,--search     Search useful memo"
    echo "  -u,--usage      Synonymous with -h or --help"
    echo "  -D,--Debug      Run in debug mode"    
    echo ""
    exit 0
}

## List
list(){
    title         
    ls ${srcdir}
}

## List determinated initial
ilist(){
    local init=$1
    title 
    mkdir ${srcdir}/.${init}
    cp ${srcdir}/${init}* ${srcdir}/.${init}
    ls ${srcdir}/.${init}
    rm -rf ${srcdir}/.${init}
}

## serach file name
searchFile(){
    local query=$1
    title 
    mkdir ${srcdir}/.query
    find ${srcdir} -name ${query}|xargs -i cp {} ${srcdir}/.query
    ls ${srcdir}/.query
    rm -rf ${srcdir}/.query
}

## Display randomly useful memo
randomlyDisplay(){
    local totalNum=`ls -1 ${srcdir}|wc -l`
    local random=`od -vAn --width=4 -tu4 -N4 < /dev/urandom`
    local sample=$(($random % $totalNum))
    local target=`ls -1 ${srcdir}|awk -v s=${sample} 'FNR==s{print $1}'`
    less ${srcdir}/${target}
    exit 0
}

## Make links
mklnk(){
    local today=`date +"%Y%m%d"`
    local latestDate="########"
    local latestHost="hostname"
    if [ -e ${srcdir}/.symlnklog ];then
        local latestDate=`cat ${srcdir}/.symlnklog|sed -n 's/date://p'`
        local latestHost=`cat ${srcdir}/.symlnklog|sed -n 's/host://p'`
    fi
    if [ ${latestDate} != ${today} ] || [ ${latestHost} != ${host} ];then
        local srcary=(asciiart photoionization abundance sh sh sh sh sh sh sh sh blackbody shock iraf statistics clang cron chandra ubuntu dis45 iraf absorption_edge ps apropos diff jobs statistics make egrep gzfile gzfile headas cbanner pkill tex flux xispi emacs nova tau text literature acknowledgement cite final_checks impact_factor shock iraf shutdown nice statistics join ssh diff emacs newton newton xspec)
        local lnkary=(aa absori abund shell bash zsh variable var test redirect escape bbody bremss cl confidence cpp crontab cxo debian dis45x ecl edge eps fapropos fdiff fg ftest gmake grep gunzip gzip heasoft kbanner kill latex luminosity makepi mule novae opticaldepth txt paper paper_acknowledgement paper_cite paper_final_checks paper_impact_factor power-law pyraf reboot renice sigma sjoin slogin tkdiff xemacs xmm-newton xmm xsp)
        cd ${srcdir}
        for i in `seq ${#srcary[@]}` ;do
            declare -i n=${i}-1
            ln -sf ${srcary[${n}]} ${lnkary[${n}]}
            i_str=`echo ${i}|awk '{printf("%2s\n",$1)}'`
            logger 0 "(${i_str}/${#srcary[@]}) link ${srcary[${n}]} to ${lnkary[${n}]}"
        done
        [ -e ${srcdir}/.symlnklog ] && rm -f ${srcdir}/.symlnklog
        echo "Latest interior symbol links create log" > ${srcdir}/.symlnklog
        echo "date:${today}" >> ${srcdir}/.symlnklog
        echo "host:${host}" >> ${srcdir}/.symlnklog
        logger 0 "Interior symbol links were created !!"
    else
        logger 0 "Interior symbol links are not created !!"
        logger 0 "Today(${today}) Interior symbol links have been created once !!"
    fi
}

## Editor
editFile(){
    local file=$1
    case $os in
	"Linux")
	    local edtopt="--font=9x15 -bg black -fg white" 
	    $EDITOR ${edtopt} ${file} &
	    ;;
	"Darwin")
	    $EDITOR ${file}
	    ;;
    esac    
}

## Make New UMEMO
mknewmemo(){
    local fname=$1
    cat /dev/null > ${srcdir}/${fname}
    echo "################################################################################" >> ${srcdir}/${fname}
    echo ${fname} >> ${srcdir}/${fname}
    echo "################################################################################" >> ${srcdir}/${fname}    
    cat ${srcdir}/.template >> ${srcdir}/${fname}
    editFile ${srcdir}/${fname}
}

## Backup
backup(){
    local today=`date +"%Y%m%d"`
    local time=`date +"%Y/%m/%d %k:%M:%S"`
    local bakdir=$HOME/Works/Memo/umemo
    local readme=${bakdir}/${today}/README

    if [ ! -d ${bakdir}/${today} ];then
        cp -r ${srcdir} ${bakdir}/${today}
        message="Copy all usefull file into following directory."
    else
        rsync -avi --delete --update ${srcdir}/ ${bakdir}/${today}
        message="Updata usefull file revised on today into follow directory."
    fi

    cat /dev/null > ${readme}
    echo "From ${srcdir} to ${bakdir}/${today}" >> ${readme}
    echo "In last ${cmdname} backed up at ${time}"  >> ${readme}
    echo ${message} >> ${readme}
    echo "${bakdir}/${today}"  >> ${readme}
	exit 0
}

################################################################################
##　STARTUP
################################################################################
clean
mklnk


################################################################################
## OPTION
################################################################################
FLG_I=0
FLG_E=0
FLG_L=0
FLG_S=0
FLG_D=0

if [ ${host} = "sir" ];then
    GETOPT=`getopt -q -o hubli:edDs:r -l help,usage,backup,list,initial:,edit,delete,Debug,search:,random -- "$@"`
    [ $? != 0 ] && abort "InvalidOption"
else
    GETOPT=`getopt -q -o huli:edDs:r -l usage,help,backup,list,initial:,edit,delete,Debug,search:,random -- "$@"`
    [ $? != 0 ] && abort "InvalidOption"
fi

logger 0 "$@" ##DEBUG

eval set -- "$GETOPT"

logger 0 "$@" ##DEBUG

while true ;do
    case $1 in
        -h|-u|--usage|--help) usage ;;
        -b|--backup) backup ;;
        -r|--random) randomlyDisplay;;
        -D|--Debug) logLevelCriteria=0; shift;;
        -l|--list) FLG_L=1; shift;;
        -e|--edit) FLG_E=1; shift;;
        -i|--initial) FLG_I=1; initial=$2; shift 2;;
        -s|--search) FLG_S=1; query=$2; shift 2;;
        -d|--delete) FLG_D=1; shift;;
        --) shift ; break ;;
        *) abort "InvalidOption" ;;
    esac
done

logger 0 "\$@=$@" ##DEBUG
logger 0 "\$#=$#" ##DEBUG
logger 0 "\$initial=${initial}"  ##DEBUG
logger 0 "\$query=${query}"  ##DEBUG


################################################################################
## MAIN
################################################################################

#listとeditを同時にできなくする
if ([ ${FLG_L} -eq 1 ] && [ ${FLG_E} -eq 1 ]) || ([ ${FLG_D} -eq 1 ] && [ ${FLG_E} -eq 1 ]) || ([ ${FLG_L} -eq 1 ] && [ ${FLG_D} -eq 1 ]);then
    abort "MultipleOption"
else
    if [ ${FLG_L} -eq 1 ];then
        if [ ${FLG_I} -eq 1 ];then
            if [ ${#initial} -ne 1 ];then
                abort "InitLetter"
            else
                ilist ${initial}
            fi
        elif [ ${FLG_S} -eq 1 ];then
            if [ ${#query} -lt 1 ];then
                abort "ZeroQuery"
            else
                searchFile ${query}
            fi
        else
            list
        fi
	else
        if [ $# -eq 0 ];then    
            if [ ${FLG_I} -eq 1 ];then
                if [ ${#initial} -ne 1 ];then
                    abort InitLetter
                else
                    ilist ${initial}
                fi
            elif [ ${FLG_S} -eq 1 ];then
                if [ ${#query} -lt 1 ];then
                    abort "ZeroQuery"
                else
                    searchFile ${query}
                fi
            else
                list
            fi
            echo ""
            echo -n "Enter file name >> "
            read inputfile
            [ -z ${inputfile} ] && abort NullInput
        elif [ $# -eq 1 ];then
            inputfile=$1 ; logger 0 "input=${inputfile}"
        else
            abort ExceededInput
        fi

        if [ -e ${srcdir}/${inputfile} ];then
            if [ ${FLG_E} -eq 1 ];then
                logger 1 "${inputfile} exists. Open ${inputfile}."
                editFile ${srcdir}/${inputfile} 
            elif [ ${FLG_D} -eq 1 ];then
                logger 1 "${inputfile} exists. Delete ${inputfile} ??"
                echo -n "(y/n) >> "
                read response; logger 0 "response: ${response}"
                case ${response} in
                    "y"|"Y") rm -f ${srcdir}/${inputfile}; logger 1 "Delete ${inputfile}" ;;
                    "n"|"N") logger 1 "Not delete ${inputfile}" ;;
                esac
            else
        		less ${srcdir}/${inputfile}
            fi
        else
            if [ ${FLG_E} -eq 1 ];then
                logger 1 "Not Found ${inputfile}. Make and Open New File."
                mknewmemo ${inputfile}
            else
                abort NoExistInput
            fi
        fi
	fi
fi


#EOF#