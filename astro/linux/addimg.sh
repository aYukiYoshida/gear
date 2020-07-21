#!/bin/bash

################################################################################
## Update
################################################################################
# Ver.  | Date       | Author   | 内容
#-------------------------------------------------------------------------------
# 1.0.0 | 2013.XX.XX | yyoshida | prototype
# 2.0.0 | 2014.08.15 | yyoshida | 構文の大幅な変更
# 2.0.1 | 2015.05.14 | yyoshida | image fileの配列番号の定義方法変更
# 2.0.2 | 2015.05.14 | yyoshida | image fileが2枚以下のときは使用不可
# 2.1.0 | 2015.05.23 | yyoshida | image fileが2枚でも使用可能に変更&nオプション削除


################################################################################
## Set Command & Value
################################################################################
version="2.1.0"
author="Y.Yoshida"
cat="/bin/cat"
farith=`which farith`
dentak="/usr/bin/bc -l"
echo="/bin/echo"


################################################################################
## Function
###############################################################################

title(){
    ${cat} <<EOT
#############################
## Add Image FITS File
#############################
Version : ${version}
Written by ${author}

EOT
}

usage(){
    title #show title
    ${cat} <<EOF 
Usage   : `basename $0` IMG_FILE1 IMG_FILE2...  [-o OUTPUT]
Example : `basename $0` x0.img x1.img x2.img x3.img -o xis_all.img 

EOF
    exit 1
}

addimg(){

    title #show title
    imgfile=($@)  ## img fileを配列に格納
    #echo $#  ## DEBUG
    seq=`echo $#-1|${dentak}`
    #echo ${seq}   ## DEBUG

    echo "Add following $# image files."
    for i in `seq 0 ${seq}` ;do
	echo ${imgfile[${i}]}
	cp ${imgfile[${i}]} f${i}.img
    done
    
    ${farith} f0.img f1.img temp.img ADD 
    mv temp.img AddFile.img
    rm -f f0.img f1.img
    
    if [ ${seq} -ge 2 ] ;then
	for i in `seq 2 ${seq}` ;do
	    ${farith} f${i}.img AddFile.img temp.img ADD
	    rm -f f${i}.img
	    mv temp.img AddFile.img
	done
    fi
    
    mv AddFile.img ${output}
    cat <<EOF

Output file : ${output}
EOF
}



################################################################################
## Option
###############################################################################
#echo $@  ##DEBUG
#GETOPT=`getopt -q -o o:n:u -- "$@"` ; [ $? != 0 ] && usage 
GETOPT=`getopt -q -o o:u -- "$@"` ; [ $? != 0 ] && usage 
eval set -- "$GETOPT"

##echo ${GETOPT} ##DEBUG

while true ;do
  case $1 in
      -o) FLG_O="TRUE"
	  output=$2 ; shift 2
	  ;;
      -u) #echo "Uopt"
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
fi


################################################################################
## Main
###############################################################################


if [ ! -e ${output} ];then
    addimg $@

else
    echo "${output} already exists !!" # 1>&2
    echo -n "Overwrite ?? (y/n) >> "
    read answer
    case ${answer} in
        y|Y|yes|Yes|YES)
	    rm -f ${output}
	    addimg $@
	    ;;

	n|N|no|No|NO)
            echo "`basename $0` has not been executed. "
            ;;
	
        *)
            echo "`basename $0` has not been executed. "
    esac
fi	




#EOF#