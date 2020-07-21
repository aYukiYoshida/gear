#!/bin/bash

################################################################################
## Redaction history
################################################################################
# Ver.  | Date       | Author   | ����
#-------------------------------------------------------------------------------
# 1.0.0 | 2013.XX.XX | yyoshida | prototype
# 1.1.0 | 2014.08.16 | yyoshida | �¹ԥ��ޥ�ɤ�function��
# 1.2.0 | 2014.08.16 | yyoshida | list command�����ѹ�
# 1.3.1 | 2014.08.16 | yyoshida | �¹ԥ��ޥ�ɤηٹ��ɲ�
# 2.0.0 | 2015.10.01 | yyoshida | scrpit�¹ԥ��ޥ�����������ѹ�
# 2.1.0 | 2015.10.01 | yyoshida | server�Ȥ�sample fileƱ����ǽ�ɲ�
# 2.2.0 | 2016.02.24 | yyoshida | ���ʬ�������ѹ�
# 2.2.1 | 2016.05.05 | yyoshida | aebarycen,xisnxbgen�ɲ�


################################################################################
## Set Command & Value
################################################################################

## values
author="Y.Yoshida"
version="2.2.0"
scriptname=$(basename $0)
[ -L ${scriptname} ] && scriptname=$(readlink ${scriptname})
sys=$(cd $(dirname ${scriptname}); pwd)
srcdir=${sys}/static #; echo ${srcdir} ##DEBUG

## command
rm="/bin/rm -rf"
mv="/bin/mv -f"
mkdir="/bin/mkdir -p"
sed="/bin/sed"
cp="/bin/cp -f"
editor="/usr/bin/emacs23 --geometry=90x40 --font=9x15"
arfgen=`which xissimarfgen`
barycen=`which aebarycen`
grppha=`which grppha` 
lcmath=`which lcmath`
mathpha=`which mathpha`
xselect=`which xselect`
xspec=`which xsp`
nxbgen=`which xisnxbgen`



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
    echo "${scriptname} -- special scripts written by ${author} version ${version}"
    echo ""
}


## Usage
## Usage
usage(){
    title #show title
	echo ""
    echo "USAGE"
    echo "    ${scriptname} [OPTION] [-r COMMAND]"
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


## List 
list(){
    title #show title
    ls ${srcdir}
}


## Editor
editFile(){
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
    editFile ${srcdir}/${fname}
}


runner(){
    cmd_in=$1
    src_in=$2
    key_in=$3
    dir_in=$4

    ls *_${src_in} > /dev/null 2>&1
    if [ $? -eq 0 ];then

	if [ "${key_in}" = "xsp" ];then
	    for i in *_${src_in} ;do
		${cmd_in} < ${i} && ${rm} ${i}       
            done

	elif [ "${key_in}" = "mpi" ];then
	    if [ ! -d ${dir_in} ];then
		${mkdir} ${dir_in}
	    fi
	    for i in *_${src_in} ;do
		${cmd_in} "clobber=yes" "backscal=%" "errmeth=Gauss" < ${i} |tee ${dir_in}/${i%.txt}.log && ${rm} ${i}       
            done

	elif [ "${key_in}" = "arf" ]||[ "${key_in}" = "grp" ]||[ "${key_in}" = "nxb" ];then
	    if [ ! -d ${dir_in} ];then
		${mkdir} ${dir_in}
	    fi
	    for i in *_${src_in} ;do
		${cmd_in} "clobber=yes" < ${i} |tee ${dir_in}/${i%.txt}.log && ${rm} ${i}       
            done

	elif [ "${key_in}" = "xsl" ];then
	    if [ ! -d ${dir_in} ];then
		${mkdir} ${dir_in}
	    fi

	    lognum=$(ls -1 ${dir_in}|sed -n '/.log/p'|wc -l)
	    [ ${lognum} -ge 1 ]&&rm -f ${dir_in}/*.log

	    for i in *_${src_in} ;do
		${cmd_in} < ${i} |tee ${dir_in}/${i%.xco}.log && ${rm} ${i}       
	    done

	else
	    if [ ! -d ${dir_in} ];then
		${mkdir} ${dir_in}
	    fi
	    for i in *_${src_in} ;do
		${cmd_in} < ${i} |tee ${dir_in}/${i%.txt}.log && ${rm} ${i}       
            done 
	fi
    else
	echo "Not Found Script file for ${key_in}."
	echo "${scriptname} has not been executed. "
    fi
}


################################################################################
## OPTION
################################################################################

GETOPT=`getopt -q -o hler: -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ##DEBUG

while true ;do
    case $1 in
		-h) usage ;;
		-l) FLG_L="TRUE"
			shift
			;;
		-e) FLG_E="TRUE"
			shift
			;;
		-r) FLG_R="TRUE"
			key=$2
			shift 2
			;;
		--) shift ; break ;;
		*)  usage ;;
    esac
done

#echo $@ ##DEBUG


################################################################################
## Main
################################################################################

clean #clear jyama file

#list��edit��Ʊ���ˤǤ��ʤ�����
if [ "${FLG_L}" = "TRUE" ] && [ "${FLG_E}" = "TRUE" ] ;then
    usage
else
	# List
    if [ "${FLG_L}" = "TRUE" ];then 
		list
    # Edit
    elif [ "${FLG_E}" = "TRUE" ];then 
		if [ $# = 0 ];then
			list; echo " "
			echo -n "Enter edit file name >> "
			read editfile
        elif [ $# = 1 ];then
            editfile=$1
            #echo "input=${editfile}" ##DEBUG
        else
            echo "Input was exceeded!!"
            exit 1
	fi


	if [ _${editfile} = _ ];then
            echo "Please Enter Edit File Name !!"
	    exit 1
	elif [ -e ${dir}/${editfile}.txt ] ;then
	    echo "${editfile} exists. Open ${editfile}."
	    ${editor} ${dir}/${editfile}.txt & 
	else
	    echo "Not Found ${editfile}. Make and Open New File."
	    mknewmemo ${editfile}
	    ${editor} ${dir}/${editfile}.txt &
	fi
    
        
    elif [ "${FLG_R}" = "TRUE" ];then ## runner
		case ${key} in 
			arf) # Run Script of xissimarfgen
				cmd=${arfgen}
				src="arfgen.txt"
				dir="ARFGenLog"
				;;
			bry) # Run Script of aebarycen
				cmd=${barycen}
				src="barycen.txt"
				dir="BarycenLog"
				;;
			grp) # Run Script of grppha
				cmd=${grppha}
				src="grp.txt"
				dir="GRPPHALog"
				;;
			lcm) # Run Script of lcmath
				cmd=${lcmath} 
				src="lcmath.txt"
				dir="LCMathLog"
				;;
			mpi) # Run Script of mathpha
				cmd=${mathpha} 
				src="mathpha.txt"
				dir="MathPHALog"
				;;
			nxb) # Run Script of mathpha
				cmd=${nxbgen} 
				src="nxbgen.txt"
				dir="NXBGenLog"
				;;
			xsl) # Run Script of xselect
				cmd=${xselect} 
				src="xsl.xco"
				dir="XselectLog"
				;;
			xsp|fit) # Run Script of xspec 
				cmd=${xspec} 
				src="xspfit.xcm" 
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
            echo "Input was exceeded!!"
        fi
        
        if [ _${shownfile} = _ ] ;then
            echo "Please Enter File Name !!"
		else
			if [ -e ${srcdir}/${shownfile} ] ;then
				less ${srcdir}/${shownfile}
			else
				echo "Not Found ${shownfile} !!"
				echo "${shownfile} doesn't exist !!"
	    fi
	fi
    fi
fi


#EOF#
