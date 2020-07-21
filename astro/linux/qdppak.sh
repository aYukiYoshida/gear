#!/bin/zsh

cmd=`basename $0`

#qdppak
usage(){
echo "USAGE: ${cmd} [-r] [-o OUTPUT] FILE1 FILE2 ..." 1>&2
exit 1
} 


GETOPT=`getopt -q -o o:ur -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"

while true ;do
  case $1 in
      -o) output=$2 ;shift 2
	  ;;
      -u) usage 
	  ;;
      -r) FLG_R=TRUE
	  shift
	  ;;
      --) shift ; break
	  ;;
      *) usage
	  ;;
  esac
done


###-------------------------------------------------------------------------------
### MAIN
###-------------------------------------------------------------------------------
if [[ ${FLG_R} = TRUE ]];then
    qdp=$1
    if [ _${qdp} = _ ];then
	usage
    else
	tmp=${qdp%.qdp}_tmp.qdp
	cat ${qdp}|sed '1,/!/d' >! ${tmp}
	nonum=$(cat ${tmp}|sed -n '/^NO/p'|wc -l|awk '{print $1+1}')
	
	i=0
	for num in $(seq ${nonum});do
            i=$(awk -v i=${i} 'BEGIN{print i+1}');lab=div${i};
            outfl=${qdp%.qdp}_${lab}.qdp;[ -e ${outfl} ]&&rm -f ${outfl}
	    cat ${qdp}|sed -n '1,/!/p' >! ${outfl} 	    
            cat ${tmp}|sed '/^NO NO NO NO/,$d' >> ${outfl}
            cat ${tmp}|sed -n '/^NO NO NO NO/,$p'|sed '1d' > tmp.qdp
            mv -f tmp.qdp ${tmp}
	done
	rm -f ${tmp}
    fi
    
else
    if [ _${output} = _ ];then
	usage
    else
	echo "SKIP SING" >! ${output}
	echo "!" >> ${output}
    
	for i in $@ ;do
	    nonum=$(awk 'END{print NF}' ${i})
	    noset=($(for n in `seq ${nonum}`;echo "NO "))
	    cat ${i}|sed "/.pco/d;/SKIP/d" >> ${output}
	    echo ${noset} >> ${output}
	done
    fi
fi


#EOF#
