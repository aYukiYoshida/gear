#!/bin/bash

################################################################################
## Function
################################################################################
usage(){
    echo "USAGE   : `basename $0` [OPTION] <EQUATION>"
    echo "EXAMPLE : `basename $0` 100/1000"
    exit 0
}

################################################################################
## OPTION
################################################################################
FLG_E=0
FLG_D=0

GETOPT=`getopt -q -o ued -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"
while true ;do
  case $1 in
      -u) usage ;;
      -e) FLG_E=1; shift ;;
      -d) FLG_D=1; shift ;;
      --) shift; break ;;
       *) usage ;;
  esac
done

################################################################################
## MAIN
################################################################################
equation=$@ 
# echo ${equation} #DEBUG

if [ -z ${equation} ];then
    usage
else
    if [ ${FLG_E} -eq 1 ]&&[ ${FLG_D} -eq 1 ];then
	    usage
    elif [ ${FLG_E} -eq 1 ];then
	    awk 'BEGIN{PI=atan2(0, -1);printf "%25.23e\n",'${equation}'}'
	
    elif [ ${FLG_D} -eq 1 ];then
        awk 'BEGIN{PI=atan2(0, -1);printf "%d\n",round('${equation}',0)}
            function round(num, digit_num){
                if (num >=0){
                    return int(num*10^digit_num+0.5)/(10^digit_num)
                }
                else{
                    return int(num*10^digit_num-0.5)/(10^digit_num)
                }
            }'

    else
	    awk 'BEGIN{PI=atan2(0, -1);printf "%25.23f\n",'${equation}'}'
    fi
fi


#EOF#