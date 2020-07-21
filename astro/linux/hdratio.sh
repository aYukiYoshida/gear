#!/bin/bash

#hardness ratio 
#スペクトル同士またはライトカーブ同士の比をとる


################################################################################
## Redaction History
################################################################################
# Ver.  | Date       | Author   | 内容
#-------------------------------------------------------------------------------
# 1.1.1 | 2012.09.22 | yyoshida | 規格化する横軸の値を入れなくても良いようにした。
# 1.1.2 | 2013.08.23 | yyoshida | Usageのfunction化
# 2.0.1 | 2015.05.18 | yyoshida | parameterのinput方法変更
# 2.0.2 | 2015.05.19 | yyoshida | Option不選択時のエラー表示
# 2.0.3 | 2015.06.24 | yyoshida | "NO"入のQDPファイルに対応
#


################################################################################
## Set Command & Value
################################################################################
version="2.0.3"
author="Y.Yoshida"
cat=/bin/cat



################################################################################
## Function
################################################################################
title(){
${cat} <<EOF
Version ${version}
Written by ${author}
EOF
}


usage(){
${cat} <<EOF 
USAGE:
   `basename $0` <OPTION> <NRTF> <DMNF> <OUTPUT> [HORIZONTAL] [CLOBBER]
EXAMPLE: 
   `basename $0` -e NRTF=over.qdp DMNF=under.qdp OUTPUT=out.qdp HORIZONTAL=2.01845002

OPTION:
   -u) usage
   -e) calculation of energy ratio
   -t) calculation of timing ratio
   -p) calculation of phase ratio

PARAMATER:
   NRTF       : Numerator File
   DMNF       : Denominator File
   OUTPUT     : Output File
   HORIZONTAL : Horizontal Number
   CLOBBER    : If you set "YES" output will be overwritten
EOF
exit 1
}


execute(){
    sed '1,/!/d' ${numerator}|awk '{print $1,$2,$3,$4}'|sed '/NO/d' > numerator.dat
    sed '1,/!/d' ${denominator}|awk '{print $3,$4}'|sed '/NO/d' > denominator.dat
    paste numerator.dat denominator.dat|awk '$3>0 && $5>0{print $1,$2,$3/$5,($3/$5)*sqrt(($4*$4)/($3*$3)+($6*$6)/($5*$5))}' > temp2
#誤差の計算
#(A±dA)÷(B±dB)=(C±dC)の場合 C=A/B, dC=(A/B)sqrt[{(dA/A)^2 + (dB/B)^2}]
    
    if [ _${normhorizon} = _ ];then
	norm=1.0
    else
	norm=`sed -n "/${normhorizon}/p" temp2|awk '{print $3}'`
    fi

    awk -v N="${norm}" '{print $1,$2,$3/N,$4/N}' temp2 > temp3
    cat <<EOF > ${output}
!file1 : `basename ${numerator}`
!file2 : `basename ${denominator}`
!The plot of this file is file1 / file2
READ SERR 1 2 
!
EOF
    
    cat temp3 >> ${output}
    
    cat <<EOF >> ${output}
lw 5
cs 1.3
la t hardness ratio
la x ${labelx}
la y RATIO 
la f `basename ${numerator}`/`basename ${denominator}`
${logx}
EOF
    
    rm -f numerator.dat denominator.dat temp2 temp3 
    cat <<EOF

Finish !!
`basename $0` has generated ${output}
EOF
	
}



error(){
    echo "`basename $0` has not been executed. "
    exit 1
}




################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o uetp -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"
while true ;do
  case $1 in
      -u) usage 
          ;;
      -e) labelx="Energy (keV)" 
	  logx="log x on" 
	  FLG_E="TRUE"
	  shift
	  ;;
      -t) labelx="Time (sec)" 
	  logx=" " 
	  FLG_T="TRUE"
	  shift 
	  ;;
      -p) labelx="Phase" 
	  logx=" " 
	  FLG_P="TRUE"
	  shift
	  ;;
      --) shift ; break 
          ;;
       *) usage 
          ;;
  esac
done
		
#echo "$@" #DEBUG
#echo "FLG_E=${FLG_E}" #DEBUG
#echo "FLG_T=${FLG_T}" #DEBUG
#echo "FLG_P=${FLG_P}" #DEBUG


################################################################################
## Main
################################################################################
title ## Title


if [ "${FLG_E}" != "TRUE" ] && [ "${FLG_T}" != "TRUE" ] && [ "${FLG_P}" != "TRUE" ] ;then
    usage

elif [ "${FLG_E}" = "TRUE" -a "${FLG_T}" = "TRUE" ] || [ "${FLG_E}" = "TRUE" -a "${FLG_P}" = "TRUE" ] || [ "${FLG_T}" = "TRUE" -a "${FLG_P}" = "TRUE" ];then
    usage
fi

if [ $# -eq 3 ] || [ $# -eq 4 ] || [ $# -eq 5 ];then
    var1=$1 #;echo ${var1}
    var2=$2 #;echo ${var2}
    var3=$3 #;echo ${var3}
    var4=$4 #;echo ${var4}
    var5=$5 #;echo ${var4}
else 
    usage
fi

for var in ${var1} ${var2} ${var3} ${var4} ${var5} ;do
    IFS='='
    set -- ${var}
    par=$1
    val=$2
   # echo "${par}" #DEBUG
   # echo "${val}" #DEBUG
    case ${par} in
        "NRTF"|"nrtf") numerator=${val} ;; #分子
        "DMNF"|"dmnf") denominator=${val} ;;  #分母
        "OUTPUT"|"output") output=${val} ;; 
        "HORIZONTAL"|"horizontal") normhorizon=${val} ;;
	"CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) usage;;
    esac
done #for var in ${var1} ${var2} ${var3} ${var4} ${var5} ;do



## Check file 

if [ ! -f ${numerator} ]||[ _${numerator} = _  ];then
    echo "`basename $0` couldn't find ${numerator} !!"
    echo "Please enter right file for <NRTF>"
    FLG_file=FALSE
fi

if [ ! -f ${denominator} ]||[ _${denominator} = _ ];then
    echo "`basename $0` couldn't find ${denominator} !!"
    echo "Please enter right file for <DMNF>"
    FLG_file=FALSE
fi

if [ _${output} = _ ];then
    echo "Please enter right file for <OUTPUT>" 
    FLG_file=FALSE
fi

   
if [ "${FLG_file}" = "FALSE" ] ;then
    error
fi
 
## Check output file & execute
if [ "${FLG_OW}" = "YES" ]||[ "${FLG_OW}" = "yes" ]||[ "${FLG_OW}" = "Yse" ];then
    rm -f ${output}
fi


if [ -f ${output} ] ;then
    echo ""
    echo "${output} already exists !!" # 1>&2
    echo -n "Overwrite ?? (y/n) >> "
    read answer
    case ${answer} in
        y|Y|yes|Yes|YES)
            execute
            ;;

        n|N|no|No|NO)
            error
            ;;

        *)
	    error
    esac

else 
    execute
fi





