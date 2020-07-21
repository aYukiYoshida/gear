#!/bin/bash

################################################################################
## Update
################################################################################
# Version | Date       | Author   | ∆‚Õ∆
#-------------------------------------------------------------------------------
# 1.0     | 2017.02.20 | yyoshida | prototype


################################################################################
## Set Command & Value
################################################################################
version="1.0"
author="Y.Yoshida"
cat="/bin/cat"
lcmath=`which lcmath`
dentak="/usr/bin/bc -l"
echo="/bin/echo"


################################################################################
## Function
###############################################################################

title(){
    ${cat} <<EOT
###############################
## Add lightcurve FITS File
###############################
Version : ${version}
Written by ${author}

EOT
}

usage(){
    title #show title
    ${cat} <<EOF 
Usage   : `basename $0` LC_FILE1 LC_FILE2...  [-o OUTPUT]
Example : `basename $0` x0_nbg.lc x1_nbg.lc x3_nbg.lc -o xis_all.lc 

EOF
    exit 1
}

addlc(){
    lcfile=($@)  ## img file§Ú«€ŒÛ§À≥ «º
    seq=`echo $#-1|${dentak}`
    #echo ${seq}   ## DEBUG

    echo "Add following $# lightcurve files."
    for i in `seq 0 ${seq}` ;do
	echo ${lcfile[${i}]}
	cp ${lcfile[${i}]} f${i}.lc
    done
    
    ${lcmath} f0.lc f1.lc temp.lc 1.0 1.0 'addsubr=yes' 1>/dev/null
    mv temp.lc AddFile.lc
    rm -f f0.lc f1.lc
    
    if [ ${seq} -ge 2 ] ;then
	for i in `seq 2 ${seq}` ;do
	    ${lcmath} f${i}.lc AddFile.lc temp.lc 1.0 1.0 'addsubr=yes' 1>/dev/null
	    rm -f f${i}.lc
	    mv temp.lc AddFile.lc
	done
    fi
    
    mv AddFile.lc ${output}
    cat <<EOF

Output file : ${output}
EOF
}



################################################################################
## Option
###############################################################################
#echo $@  ##DEBUG
GETOPT=`getopt -q -o o:uh -- "$@"` ; [ $? != 0 ] && usage 
eval set -- "$GETOPT"

##echo ${GETOPT} ##DEBUG

while true ;do
  case $1 in
      -o) FLG_O="TRUE"
	  output=$2 ; shift 2
	  ;;
      -u|h) #echo "Uopt"
	  usage 
	  ;;
      --) shift ; break
	  ;;
      *) usage
	  ;;
  esac
done

################################################################################
## Check
###############################################################################
#echo "num=${num}"  ##DEBUG
#echo "FLG_N=${FLG_N}"  ##DEBUG
#echo "output=${output}"  ##DEBUG
#echo "FLG_O=${FLG_O}"  ##DEBUG
#echo $@  ##DEBUG
#echo "No1=$1" ##DEBUG
#echo "No2=$2" ##DEBUG
#echo "No3=$3" ##DEBUG
#echo "No4=$4" ##DEBUG


if  [ "${FLG_O}" != "TRUE" ];then
   usage
else
    title
################################################################################
## Main
###############################################################################


    if [ ! -e ${output} ];then
	addlc $@ 

    else
	echo "${output} already exists !!" # 1>&2
	echo -n "Overwrite ?? (y/n) >> "
	read answer
	case ${answer} in
            y|Y|yes|Yes|YES)
		rm -f ${output}
		addlc $@ 
		;;
	    
	    n|N|no|No|NO)
		echo "`basename $0` has not been executed. "
		;;
	    
            *)
		echo "`basename $0` has not been executed. "
	esac
    fi	
fi



#EOF#
