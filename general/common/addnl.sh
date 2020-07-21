#!/bin/sh

##################################
# change text cood
##################################


################################################################################
## Update
################################################################################
# Ver | Date       | Author   | Description
#---------------------------------------------------------------
# 1.0 | 2019.01.30 | yyoshida | prototype
# 1.1 | 2019.07.25 | yyoshida | modify judgment about input argment 
#

################################################################################
## Value
################################################################################
command=`basename $0`


################################################################################
## Function
################################################################################
usage(){
    cat <<EOF

${command} -- add number of line

USAGE:
  % ${command} [-o OUTPUT] [-r] <filename>

OPTIONS:
 -h) show this help message
 -o) assign output file name
 -r) remove input file
 -i) inplace input file

EOF
    exit 0
}

logging(){
    echo "${command}: $@"
}

gen(){
    local innput=$1
    local output=$2
    digit=$(wc -l ${innput}|awk '{printf "%d\n",log10($1)+1};function log10(x){return log(x)/log(10)}') 
    nl -n rz -h n -f n -b a -w ${digit} ${innput} > ${output}
}

finish(){
    local output=$1
    logging "${output} was generated"
}

removeinput(){
    local innput=$1
    rm -f ${innput}
    logging "${innput} was removed"
}

inplaceinput(){
    local orgfile=$1
    local newfile=$2
    mv -f ${newfile} ${orgfile}
    logging "${orgfile} was updated with line numbers added"
}


################################################################################
## OPTION
################################################################################
FLG_O=0
FLG_R=0
FLG_I=0
GETOPT=`getopt -q -o huo:ri -- "$@"` ; [ $? != 0 ] && usage

#echo $@  #DEBUG
eval set -- "$GETOPT"
#echo $@  #DEBUG

while true ;do
    #echo $1  #DEBUG
    case $1 in
	-h|-u) usage 
               ;;
	-o) FLG_O=1
	    out_file=$2
            shift 2
            ;;
	-r) FLG_R=1
            shift 
            ;;
	-i) FLG_I=1
            shift 
            ;;
	--) shift ; break 
            ;;
	*) usage 
           ;;
    esac
done


################################################################################
## Set parameter
################################################################################
inn_file=$1
if [ -z ${inn_file} ];then
    logging "Please input file !!"
    exit 1
elif [ ${FLG_O} -eq 1 -a ${FLG_I} -eq 1 ];then
    logging "-o and -i options cannot be used at the same time !!"
    exit 1
else
    ################################################################################
    ## Main
    ################################################################################
    if [ ! -e ${inn_file} ];then
        logging "Input file does not exist !!"
        exit 1
    else
        if [ ${FLG_O} -eq 0 ]||[ ${FLG_I} -eq 1 ];then
            extension=${inn_file##*.}
            out_file=${inn_file%.*}_wnl.${extension}
        fi

        gen ${inn_file} ${out_file}

        if [ ${FLG_I} -eq 1 ];then
            inplaceinput ${inn_file} ${out_file}
        else
            finish ${out_file}
            if [ ${FLG_O} -eq 0 ]&&[ ${FLG_R} -eq 1 ];then
                removeinput ${inn_file}
            fi
        fi
    fi
fi

#EOF
