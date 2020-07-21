#!/bin/zsh

############################################
#        make QDP without PCO              #
############################################

#PCOなしでQDPを実行できるようにする。


################################################################################
## Function
################################################################################

usage(){
cat <<EOF 
===============================================
                   QDPENV
===============================================

Usage : `basename $0` [OPTION] <QDPFILENAME>

  [OPTION]
   -u)  Show Usage
   -a)  No need PCO for all QDP FILE
   -r)  Separate PCO from QDP

EOF
exit 1
}


env(){
    if [ ! -f ${qdp%.qdp}.pco ]; then
	echo "${qdp%.qdp}.pco is not found !!" 1>&2
    else
	cat ${qdp%.qdp}.pco >! ${qdp%.qdp}_temp.qdp
	sed "/.pco/d" ${qdp} >> ${qdp%.qdp}_temp.qdp
	rm ${qdp} -f
	cat <<EOF >> ${qdp%.qdp}_temp.qdp
time off
la f ${qdp}
EOF
	mv ${qdp%.qdp}_temp.qdp ${qdp}
	rm -f ${qdp%.qdp}.pco
    fi
}


rvs(){
    if [ ! -f ${qdp%.qdp}.pco ]; then
	PGPLOT_TYPE=/null
	qdp ${qdp} <<EOF 1>/dev/null
we ${qdp%.qdp}_temp.qdp
quit
EOF
	PGPLOT_TYPE=/xw
	echo "@${qdp%.qdp}.pco" >! ${qdp}
	    sed "/.pco/d" ${qdp%.qdp}_temp.qdp >> ${qdp}
	    mv ${qdp%.qdp}_temp.pco ${qdp%.qdp}.pco
	    rm -f ${qdp%.qdp}_temp.qdp
    else
	echo "${qdp%.qdp}.pco already exists !!" 1>&2	
    fi
}


################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o uar -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"

while true ;do
  case $1 in
      -u) usage 
	  ;;
      -a) FLG_A="TRUE" 
	  shift 
	  ;;
      -r) FLG_R="TRUE"
	  shift 
	  ;;
      --) shift ; break 
	  ;;
       *) usage 
	  ;;
  esac
done


################################################################################
## Main
################################################################################
if [ "${FLG_A}" = "TRUE" -a "${FLG_R}" = "TRUE" ];then
    for qdp in  *.qdp ;do
	rvs
    done
elif [ "${FLG_A}" = "TRUE" ];then
    for qdp in  *.qdp ;do
	env
    done
elif [ "${FLG_R}" = "TRUE" ];then
    qdp=$1
    if [ _${qdp} = _ ] ;then
	echo "Please enter QDP FILE !!" 1>&2
	exit 1
    elif [ -e ${qdp} ] ;then
	rvs
    else
	echo "${qdp} is not found !!" 1>&2
	exit 1
    fi
else
    qdp=$1
    if [ _${qdp} = _ ] ;then
	echo "Please enter QDP FILE !!" 1>&2
	exit 1
    elif [ -e ${qdp} ] ;then
	env
    else 
	echo "${qdp} is not found !!" 1>&2
	exit 1
    fi
fi


#EOF#