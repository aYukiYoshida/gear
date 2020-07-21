#!/bin/bash

################################################################################
## Redaction History
################################################################################
# Ver.  | Date       | Author   | ∆‚Õ∆
#-------------------------------------------------------------------------------
# 1.0.0 | 2015.06.12| yyoshida | prototype


################################################################################
#Set Parameter
################################################################################
version="1.0.0"
author="Y.Yoshida"

################################################################################
#Function
################################################################################
usage(){
cat <<EOF 
Usage   : `basename $0` <OPTION> <ENERGY>
Example : `basename $0` -x 10.0

OPTION
 -u) Show usage
 -x) XIS
 -p) HXD-PIN
 -g) HXD-GSO

PARAMETER
 <ENERGY>  :  Energy value in keV
EOF
exit 1
}

title(){
cat <<EOF
Version ${version} 
Written by ${author}
EOF
}


xispichan(){
#E=3.65*PI(eV)
#PI=E/3.65
E=$1
awk -v "e=${E}" 'BEGIN{printf "%d\n" ,round(e*1000/3.65)}
function round(num) {
    if (num > 0) {
        return int(num + 0.5);
    } else {
        return int(num - 0.5);
    }
}'

}



pinpichan(){
#E=0.375*(PI_PIN+1.0)[keV]
#PI=E/0.375-1
E=$1
awk -v "e=${E}" 'BEGIN{printf "%d\n" ,round(e/0.375-1)}
function round(num) {
    if (num > 0) {
        return int(num + 0.5);
    } else {
        return int(num - 0.5);
    }
}'
}

gsopichan(){
#E=2*(PI_SLOW+0.5)[keV]
#PI=E/2-0.5
E=$1
awk -v "e=${E}" 'BEGIN{printf "%d\n" ,round(e/2-0.5)}
function round(num) {
    if (num > 0) {
        return int(num + 0.5);
    } else {
        return int(num - 0.5);
    }
}'
}


################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o ux:p:g: -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"
while true ;do
  case $1 in
      -u) usage 
          ;;
      -x) FLG_X="TRUE"
	  energy=$2
	  shift 2
	  ;;
      -p) FLG_P="TRUE"
	  energy=$2
	  shift 2
	  ;;
      -g) FLG_G="TRUE"
	  energy=$2
	  shift 2
	  ;;
      --) shift ; break 
          ;;
       *) usage 
          ;;
  esac
done

#echo ${FLG_X} #DEBUG
#echo ${FLG_P} #DEBUG


################################################################################
## Main
################################################################################
#echo "XIS:${FLG_X}" ##DEBUG
#echo "PIN:${FLG_P}" ##DEBUG
#echo "GSO:${FLG_G}" ##DEBUG

if [ $# -ne 0 ] ;then
    usage
else
    if [ "${FLG_X}" = "TRUE" ]&&[ "${FLG_P}" != "TRUE" ]&&[ "${FLG_G}" != "TRUE" ];then
	xispichan ${energy}
	
    elif [ "${FLG_P}" = "TRUE" ]&&[ "${FLG_X}" != "TRUE" ]&&[ "${FLG_G}" != "TRUE" ];then
	pinpichan ${energy}

    elif [ "${FLG_G}" = "TRUE" ]&&[ "${FLG_X}" != "TRUE" ]&&[ "${FLG_P}" != "TRUE" ];then
	gsopichan ${energy}
    else
	usage
    fi
fi


#EOF#