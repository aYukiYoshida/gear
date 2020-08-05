#!/bin/bash -u

################################################################################
## Set Command & Value
################################################################################

## values
AUTHOR="Y.Yoshida"
SCRIPTFILE=$0
[ -L ${SCRIPTFILE} ] && SCRIPTFILE=$(readlink ${SCRIPTFILE})
SCRIPTNAME=$(basename ${SCRIPTFILE%.*})
sys=$(dirname ${SCRIPTFILE})
srcdir=${sys}/static #; echo ${srcdir} ##DEBUG
CONFIG_FILE=${srcdir}/.config

LOG_LEVEL_CRITERIA=1
COMMAND_NOT_FOUND=0


################################################################################
## Function
################################################################################

## Clean
clean(){
	local bkupflnum=`/bin/ls -1 ${srcdir}|sed -n '/~/p'|wc -l`
	[ ${bkupflnum} -ne 0 ] && /bin/rm -f *~*
}


## Title
title(){
    echo "${SCRIPTNAME} -- special scripts written by ${AUTHOR}"
    echo ""
}


## Usage
usage(){
    title #show title
    echo "USAGE"
    echo "    ${SCRIPTNAME} [OPTION] [-r COMMAND]"
    echo "OPTIONS"
    echo "  -d,--delete    Delete useful memo"    
    echo "  -e,--edit      Edit useful memo"
    echo "  -h,--help      Show this help script"
    echo "  -l,--list      List useful memos"
    echo "  -u,--usage     Synonymous with -h or --help"
    echo "  -r,--run       Run script file(s)"    
	echo "COMMAND"
	echo "  arf    Run script for xissimarfgen (suffix=_arfge.txt)"
	echo "  bry    Run script for aebarycen    (suffix=_barycen.txt)"
    echo "  grp    Run script for grppha       (suffix=_grp.txt)"
	echo "  lcm    Run script for lcmath       (suffix=_lcmath.txt)"
	echo "  mpi    Run script for mathpha      (suffix=_mathpha.txt)"
	echo "  nxb    Run script for xisnxbgen    (suffix=_nxbgen.txt)"
	echo "  xsl    Run script for xselect      (suffix=_xsl.xco)"
	echo "  xsp    Run script for xspec        (suffix=_xspfit.xcm)"
    exit 0
}


logger(){
    local level=$1
    local message=$2
    case ${level} in
        0) local context="DEBUG" ;;
        1) local context="INFO" ;;
        2) local context="WARNING" ;;        
        3) local context="ERROR" ;;
    esac
    [ ${level} -ge ${LOG_LEVEL_CRITERIA} ] && echo "[${context}] ${message}"
}


abort(){
    local evt=$1
    case ${evt} in
        InvalidInput) local message="Invalid arguments !!" ;;
        InvalidInputNumber) local message="Input is excess or deficiency !!" ;;        
        InvalidOption) local message="Invalid input option !!" ;;
		NotInput) local message="Please enter the file name" ;;
        NotFoundCommand) local message="Not found necessary command !!" ;;
        NotFoundScript) local message="Not found Script file !!" ;;
        NotFoundFile) local message="Not found shown file !!" ;;
        *) local message="Abort !!" ;;
    esac
    logger 3 "${message}"
    exit 1
}


## Check command
check_command(){
    local command=$1
    which ${command} > /dev/null 2>&1
    if [ $? -eq 1 ];then
        COMMAND_NOT_FOUND=1
        logger 2 "Command not found: ${command}"
    fi
    logger 0 "COMMAND_NOT_FOUND=${COMMAND_NOT_FOUND}"
}


## List 
list(){
    title #show title
    ls ${srcdir}
}


## Editor
edit(){
    local file=$1
	local edtopt="--font=9x15 -bg black -fg white" 
	$EDITOR ${edtopt} ${file} &
}


## Make New MEMO
mknewmemo(){
	local fname=$1
    cat /dev/null > ${srcdir}/${fname}
    echo "################################################################################" >> ${srcdir}/${fname}
    echo ${fname} >> ${srcdir}/${fname}
    echo "################################################################################" >> ${srcdir}/${fname}    
    cat ${srcdir}/.template >> ${srcdir}/${fname}
    edit ${srcdir}/${fname}
}


## notification
notify(){
	local command=$1
	local datetime=$2
	local USER_EMAIL_ADDRESS=""
	local LINE_NOTIFICATION_ACCESS_TOKEN=""

	[ -e ${CONFIG_FILE} ] && source ${CONFIG_FILE}
	if [[ x${USER_EMAIL_ADDRESS} != x ]];then
		cat ${srcdir}/.notification|sed "s%(COMMAND)%${command}%;s%(DATETIME)%${datetime};s%(ADDRESS)%${USER_EMAIL_ADDRESS}%"|sendmail -i -t
	elif [[ x${LINE_NOTIFICATION_ACCESS_TOKEN} != x ]];then
		local message=$(cat ${srcdir}/.notification|sed '1,3d'|sed "s%(COMMAND)%${command}%;s%(DATETIME)%${datetime}%")
		curl -X POST -H "Authorization: Bearer ${LINE_NOTIFICATION_ACCESS_TOKEN}" -F "message=${message}" https://notify-api.line.me/api/notify|jq
	else
		logger 2 "No notification"
	fi
}


runner(){
    local cmd_in=$1
    local src_in=$2
    local key_in=$3
    local dir_in=$4
	local datetime=$(LC_TIME=en_US.UTF-8 date +"%Y/%m/%d-%H:%M:%S")

    ls *_${src_in} > /dev/null 2>&1
    if [ $? -eq 0 ];then

		if [[ ${key_in} = xsp ]];then
			for i in *_${src_in} ;do
				${cmd_in} < ${i} && rm -rf ${i}       
			done

		elif [[ ${key_in} = mpi ]];then
			[ -d ${dir_in} ] || mkdir -p ${dir_in}
			for i in *_${src_in} ;do
				${cmd_in} "clobber=yes" "backscal=%" "errmeth=Gauss" < ${i} |tee ${dir_in}/${i%.txt}.log && rm -rf ${i}       
			done

		elif [[ ${key_in} = arf ]]||[[ ${key_in} = nxb ]]||[[ ${key_in} = grp ]];then
			[ -d ${dir_in} ] || mkdir -p ${dir_in}
			for i in *_${src_in} ;do
				${cmd_in} "clobber=yes" < ${i} |tee ${dir_in}/${i%.txt}.log && rm -rf ${i}       
			done

		elif [[ ${key_in} = xsl ]];then
			[ -d ${dir_in} ] || mkdir -p ${dir_in}

			lognum=$(ls -1 ${dir_in}|sed -n '/.log/p'|wc -l)
			[ ${lognum} -ge 1 ]&&rm -f ${dir_in}/*.log

			for i in *_${src_in} ;do
				${cmd_in} < ${i} |tee ${dir_in}/${i%.xco}.log && rm -rf ${i}       
			done

		else
			[ -d ${dir_in} ] || mkdir -p ${dir_in}

			for i in *_${src_in} ;do
				${cmd_in} < ${i} |tee ${dir_in}/${i%.txt}.log && rm -rf ${i}       
			done 
		fi

		# notification
		if [[ ${key_in} = xsp ]]||[[ ${key_in} = arf ]]||[[ ${key_in} = nxb ]]||[[ ${key_in} = xsl ]];then
			notify ${cmd_in} ${datetime}
		fi
    else
		abort NotFoundScript
    fi
}


################################################################################
## Check commands
################################################################################
for command in xselect xissimarfgen aebarycen grppha lcmath mathpha xsp xisnxbgen sendmail curl jq;do
    check_command ${command}
done

[ ${COMMAND_NOT_FOUND} -eq 1 ] && abort NotFoundCommand


################################################################################
## OPTION
################################################################################

GETOPT=`getopt -q -o hler: -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ##DEBUG

FLG_L=0
FLG_E=0
FLG_R=0

while true ;do
    case $1 in
		-h) usage ;;
		-l) FLG_L=1; shift ;;
		-e) FLG_E=1; shift ;;
		-r) FLG_R=1; key=$2; shift 2;;
		--) shift ; break ;;
		*)  usage ;;
    esac
done

#echo $@ ##DEBUG


################################################################################
## Main
################################################################################

clean #clear jyama file

if [ ${FLG_L} -eq 1 ] && [ ${FLG_E} -eq 1 ] ;then
    usage
else
	# List
    if [ ${FLG_L} -eq 1 ];then
		list

    # Edit
    elif [ ${FLG_E} -eq 1 ];then 
		if [ $# = 0 ];then
			list; echo " "
			echo -n "Enter edit file name >> "
			read editfile
        elif [ $# = 1 ];then
            editfile=$1
            #echo "input=${editfile}" ##DEBUG
        else
            abort InvalidInputNumber
		fi

		if [ _${editfile} = _ ];then
			abort NotInput
		elif [ -e ${dir}/${editfile}.txt ] ;then
			echo "${editfile} exists. Open ${editfile}."
			edit ${dir}/${editfile}.txt & 
		else
			echo "Not Found ${editfile}. Make and Open New File."
			mknewmemo ${editfile}
			edit ${dir}/${editfile}.txt &
		fi
        
	# runner
    elif [ ${FLG_R} -eq 1 ];then
		case ${key} in 
			arf) # Run Script of xissimarfgen
				cmd=xissimarfgen
				src="arfgen.txt"
				dir="ARFGenLog"
				;;
			bry) # Run Script of aebarycen
				cmd=aebarycen
				src="barycen.txt"
				dir="BarycenLog"
				;;
			grp) # Run Script of grppha
				cmd=grppha
				src="grp.txt"
				dir="GRPPHALog"
				;;
			lcm) # Run Script of lcmath
				cmd=lcmath 
				src="lcmath.txt"
				dir="LCMathLog"
				;;
			mpi) # Run Script of mathpha
				cmd=mathpha 
				src="mathpha.txt"
				dir="MathPHALog"
				;;
			nxb) # Run Script of mathpha
				cmd=xisnxbgen 
				src="nxbgen.txt"
				dir="NXBGenLog"
				;;
			xsl) # Run Script of xselect
				cmd=xselect 
				src="xsl.xco"
				dir="XselectLog"
				;;
			xsp|fit) # Run Script of xspec 
				cmd=xsp 
				src="xspfit.xcm"
				dir="XspecLog"
				;;
			*) # echo "CHECK" ##DEBUG
				usage ;;
		esac
		runner ${cmd} ${src} ${key} ${dir}
	
    else # Show files
        if [ $# = 0 ];then
	    	list  # show list 
            echo -n "Select file name !! >> "
            read shownfile
        elif [ $# = 1 ];then
            shownfile=$1
            # echo "input=${shownfile}" ##DEBUG
        else
            abort InvalidInputNumber
        fi
        
        if [ _${shownfile} = _ ] ;then
            abort NotInput
		else
			if [ -e ${srcdir}/${shownfile} ] ;then
				less ${srcdir}/${shownfile}
			else
				abort NotFoundFile
	    	fi
		fi
    fi
fi


#EOF#
