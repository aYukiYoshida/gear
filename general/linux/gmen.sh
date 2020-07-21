#!/bin/sh

################################################################################
## COMMAND
################################################################################
#term=/usr/bin/kterm
term=/usr/bin/xterm


################################################################################
## VALUE
################################################################################
case $(basename ${term}) in
    kterm)
	font="-fn 7x14 -fk k20 -fr r20" 
	etc="-km euc -sl 4096 -sb"
	;;
    xterm)
	font="-fn 7x14"
	etc="-sb"
	;;
esac


################################################################################
## FUNCTION
################################################################################

## Usage
usage(){
    cat <<EOF 
USAGE  :  `basename $0` [OPTION]
EOF
exit 1
}


################################################################################
## OPTION
################################################################################

GETOPT=`getopt -q -o hlbsm -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ##DEBUG

while true ;do
  case $1 in
      -h|-u) usage
          ;;
      -l) FLG_L="TRUE"
          shift
          ;;
      -s) FLG_S="TRUE"
	  shift
	  ;;
      -m) FLG_M="TRUE"
          shift
          ;;
      -b) FLG_B="TRUE"
          shift
          ;;
      --) shift ; break 
          ;;
       *) usage 
          ;;
  esac
done

################################################################################
## MAIN
################################################################################

## WINDOW SIZE
if [ "${FLG_L}" = "TRUE" ];then

    size="-geometry 140x80"

elif [ "${FLG_M}" = "TRUE" ];then

    size="-geometry 140x40"

elif [ "${FLG_S}" = "TRUE" ];then

    size="-geometry 140x30"
    
else
    size="-geometry 140x30"
fi

## COLOR
if [ "${FLG_B}" = "TRUE" ];then

    color="-rvc"
fi


${term} -C ${color} ${size} ${font} ${etc} & #2>/dev/null&
