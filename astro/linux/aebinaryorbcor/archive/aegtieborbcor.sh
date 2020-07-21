#!/bin/bash

################################################################################
## Redaction History
################################################################################
# Version | Date       | Author   | ∆‚Õ∆
#-------------------------------------------------------------------------------
# 1.0.0   | 2016.07.29 | yyoshida | prototype
# 1.1.0   | 2017.02.20 | yyoshida | introduce python module
# 1.1.1   | 2017.05.01 | yyoshida | modify calculation part
#


################################################################################
#Set Parameter
################################################################################
version="1.1.1"
author="Y.Yoshida"
local="/home/yyoshida/local/bin"
mjdrefzero=51544.00074287036841269582510


################################################################################
#Command
################################################################################
more="/usr/bin/jless"
fkeyprint="$HEADAS/bin/fkeyprint"
punlearn="$HEADAS/bin/punlearn"
mkphittabawk="${local}/aelceborbcor/mkphittab.awk"
mkphittabpy="${local}/aelceborbcor/mkphittab.py"
transdayphipy="${local}/aelceborbcor/transtimphi.py"
modphigtipy="${local}/aelceborbcor/modphigti.py"


################################################################################
#Function
################################################################################
title(){
cat <<EOF
`basename $0` -- binary elliptical orbit correction for SUZAKU GTI
version ${version} Written by ${author}

EOF
}

usage(){
    title
    cat <<EOF |${more}
USAGE: 
   `basename $0` [OPTION] <INPUT> <OUTPUT>  \\
    <ASINI> <ORBZERO> <PORB> <ECC> <OMG> <PHITTAB> [CLOBBER] 

EXAMPLE: 
   `basename $0` LCFITS=x0_src.lc OUTPUT=x0_03_05_borbcor.gti \\
   ASINI=10.0 ORBZERO=5.550272484843833E+04 PORB=123.45 ecc=0.021 omg=90 

PARAMETERS:
   <INPUT>
      Name of input GTI file. Unit of Time must be SUZAKU-TIME.

   <OUTPUT>
      Name of output GTI file.

   <ASINI>
     asin(i) in unit of lt-s, a:orbital radius; i:inclination angle

   <ORBZERO> 
     Time of superior conjunction or periastron passage in unit of MJD(day)

   <PORB> 
     orbital period in unit of day

   <ECC>
     eccentricity of orbital

   <OMG>
     Longitude at the ORBZERO in unit of degree

   <PHITTAB>
     phi-time transefer table file

   [CLOBBER]
     If you set "CLOBBER=YES" output will be overwritten

EOF
    exit 1
}


gticor(){
    #---------------------------------------------------------------------------
    #input parameters
    #---------------------------------------------------------------------------
    ingti=$1      #; echo "ingti      ${ingti}" ##DEBUG
    outgti=$2     #; echo "outgti     ${outgti}" ##DEBUG
    in_asini=$3   #; echo "in_asini   ${in_asini}" ##DEBUG
    in_ecc=$4     #; echo "in_ecc     ${in_ecc}" ##DEBUG
    in_omg=$5     #; echo "in_omg     ${in_omg}" ##DEBUG
    in_orbzero=$6 #; echo "in_orbzero ${in_orbzero}" ##DEBUG
    in_porb=$7    #; echo "in_porb    ${in_porb}" ##DEBUG
    in_phittab=$8 #; echo "in_phittba ${in_phittab}" ##DEBUG 
    

    #---------------------------------------------------------------------------
    #messagenger part1
    #---------------------------------------------------------------------------
    cat << EOF
input GTI File                : ${ingti}
phi-time transefer table File : ${in_phittab}

Setted paramters as follow:
asin(i)         :  ${in_asini}
orbital origin  :  ${in_orbzero}
orbital period  :  ${in_porb}
omega           :  ${in_omg}
eccentricity    :  ${in_ecc}

EOF


    #---------------------------------------------------------------------------
    #modify GTI table
    #---------------------------------------------------------------------------
    echo "STAGE 1 : Modify GTI Table of GTI File"

    ## calc day from orbital zero point
    echo "  STAGE 1-1 : calc day from orbital zero point" ##debug
    awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_orbzero}'}{printf "%17.15e %17.15e %17.15e %17.15e\n",$1,($1/86400+mjdz-orbz),$2,($2/86400+mjdz-orbz)}' ${ingti} > gtieborbcor_tmp1.gti


    ## translation time to radian via searching table
    echo "  STAGE 1-2 : translation time to radian via searching table"
    [ -e transdayphioutgti.dat ]&&rm -f transdayphioutgti.dat
    ${transdayphipy} --tab=${in_phittab} --gtidat=gtieborbcor_tmp1.gti 
    #-> transdayphioutgti.dat is created


    ## modify orbital phase
    echo "  STAGE 1-3 : modify orbital phase"
    [ -e modphioutgti.dat ]&&rm modphioutgti.dat
    ${modphigtipy} --tab=${in_phittab} --porb=${in_porb} --asini=${in_asini} --ecc=${in_ecc} --omg=${in_omg} --gti=transdayphioutgti.dat
    #-> modphioutgti.dat is created
  

    ## binary-correction
    echo "  STAGE 1-4 : binary-correction"
    paste ${ingti} modphioutgti.dat|awk 'BEGIN{PI=atan2(0,-1);asi='${in_asini}';e='${in_ecc}';omgdeg='${in_omg}';omg=omgdeg/180*PI}{printf "%17.15e %17.15e\n",$1+(asi*(1-e^2)*sin($3+omg)/(1+e*cos($3+omg))),$2+(asi*(1-e^2)*sin($4+omg)/(1+e*cos($4+omg)))}' > ${outgti}
    paste ${ingti} modphioutgti.dat|awk 'BEGIN{PI=atan2(0,-1);asi='${in_asini}';e='${in_ecc}';omgdeg='${in_omg}';omg=omgdeg/180*PI}{printf "%17.15e %17.15e\n",(asi*(1-e^2)*sin($3+omg)/(1+e*cos($3+omg))),(asi*(1-e^2)*sin($4+omg)/(1+e*cos($4+omg)))}' > ${outgti}2

    rm -f gtieborbcor_tmp1.gti
    rm -f transdayphioutgti.dat
    rm -f modphioutgti.dat
    echo "STAGE 1 finished"
    echo " "


    #---------------------------------------------------------------------------
    #messagenger part2
    #---------------------------------------------------------------------------
    cat <<EOF
Output GTI File : ${outgti}
`basename $0` has done.
EOF
}

cleanfoolspar(){
    ${punlearn} fkeyprint
}


execute(){
    ## binary-correction
    gticor ${input} ${output} ${asini} ${ecc} ${omg} ${orbzero} ${porb} ${phittab}
    cleanfoolspar
}



################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o uh -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"
while true ;do
    case $1 in
	-u|-h) 
	    usage
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
##Input
var1=$1 #;echo ${var1}
var2=$2 #;echo ${var2}
var3=$3 #;echo ${var3}
var4=$4 #;echo ${var4}
var5=$5 #;echo ${var5}
var6=$6 #;echo ${var6}
var7=$7 #;echo ${var7}
var8=$8 #;echo ${var8}
var9=$9 #;echo ${var9}

for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6} ${var7} ${var8} ${var9} ;do
    IFS='='
    set -- ${var}
    par=$1
    val=$2
    #echo "${par}" #DEBUG
    #echo "${val}" #DEBUG
    case ${par} in
        "INPUT"|"input") input=${val} ;;
        "OUTPUT"|"output") output=${val} ;;
	"PHITTAB"|"phittab") phittab=${val} ;;
        "ASINI"|"asini") asini=${val} ;;
        "ORBZERO"|"orbzero") orbzero=${val} ;;
	"PORB"|"porb") porb=${val} ;;
	"ECC"|"ecc") ecc=${val} ;;
	"OMG"|"omg") omg=${val} ;;
        "CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) usage;;
    esac
done #for var in ${var*};do

#echo "OUTPUT ${output}"  #DEBUG
#echo "ASINI ${asini}"   #DEBUG
#echo "ORBZERO ${orbzero}"   #DEBUG
#echo "PORB ${porb}"   #DEBUG
#echo "Overwrite ${FLG_OW}" #DEBUG


################################################################################
## Main
################################################################################
if [ $# -eq 0 ] ;then
    usage
else
    title
    if [ ! -e ${input} ]||[ _ = _${input} ];then
        echo "`basename $0` couldn't find <INPUT>."
	FLG_VAL="FALSE"
    fi

    if [ _${asini} = _ ];then
        echo "Please enter value of <ASINI> !!"
        FLG_VAL=FALSE
    fi    
    
    if [ _${orbzero} = _ ];then
        echo "Please enter value of <ORBZERO> !!"
        FLG_VAL=FALSE
    fi
    
    if [ _${porb} = _ ];then
        echo "Please enter value of <PORB> !!"
        FLG_VAL=FALSE
    fi

    if [ _${ecc} = _ ];then
        echo "Please enter <ECC> !!"
        FLG_VAL=FALSE
    fi

    if [ _${omg} = _ ];then
        echo "Please enter <omg> !!"
        FLG_VAL=FALSE
    fi

    if [ _${output} = _ ] ;then
	echo "Please enter filename of <OUTPUT>."
	FLG_VAL="FALSE"
    fi

    if [ "${FLG_VAL}" = "FALSE" ];then
        exit 1
	
    else
	if [ _ = _${phittab} ];then
            phittab=aelceborbcor.phittab.dat
	fi

	if [ ! -e ${output} ] ;then
	    execute

	## OUTPUT GTI already exist
	else
	    if [ "${FLG_OW}" = "YES" ]||[ "${FLG_OW}" = "yes" ] ;then
		rm ${output}
		execute
	   
	    else
		echo "${output} already exists !!" # 1>&2
		echo -n "Overwrite ?? (y/n) >> "
		read answer
		case ${answer} in
		    y|Y|yes|Yes|YES)
			rm ${output}
			execute
			;;
		    
		    n|N|no|No|NO)
			echo "`basename $0` has not been executed. "
			exit 1
			;;
		    
		    *)
			echo "`basename $0` has not been executed. "
			exit 1
			;;
		esac
	    fi
	fi
    fi
fi

#EOF#
