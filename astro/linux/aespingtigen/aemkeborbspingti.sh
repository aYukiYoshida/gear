#!/bin/bash

################################################################################
## Redaction History
################################################################################
# Version | Date       | Author   | ∆‚Õ∆
#-------------------------------------------------------------------------------
# 1.0.0   | 2016.07.27 | yyoshida | prototype
# 1.1.0   | 2017.02.20 | yyoshida | introduce python module
#


################################################################################
#Set Parameter
################################################################################
version="1.1.0"
author="Y.Yoshida"
local="/home/yyoshida/local/bin"


################################################################################
#Command
################################################################################
more="/usr/bin/jless"
fkeyprint="$HEADAS/bin/fkeyprint"
punlearn="$HEADAS/bin/punlearn"
mkphittabawk="${local}/aelceborbcor/mkphittab.awk"
mkphittabpy="${local}/aelceborbcor/mkphittab.py"
transdayphipy="${local}/aelceborbcor/transtimphi.py"
gtieborbcor="${local}/aegtieborbcor.sh"


################################################################################
#Function
################################################################################
title(){
cat <<EOF
`basename $0` -- make SUZAKU spin GTI binary elliptical orbit corrected
version ${version} Written by ${author}

EOF
}

usage(){
    title
    cat <<EOF |${more}
USAGE: 
   `basename $0` [OPTION] <LCFITS> <OUTPUT> <EPOCH> <PERIOD> <IPHASE> <TPHASE> \\
   [IPHASE_EXT] [TPHASE_EXT] <ASINI> <ORBZERO> <PORB> <ECC> <OMG> [CLOBBER] 

EXAMPLE: 
   `basename $0` LCFITS=x0_src.lc EPOCH=54051.93313 PERIOD=17279.219 \\
   IPHASE=0.3 TPHASE=0.5 ASINI=10.0 ORBZERO=5.550272484843833E+04 \\
   PORB=123.45 ecc=0.021 omg=90 OUTPUT=x0_03_05_borbcor.gti 

PARAMETERS:
   <LCFITS>
      Name of the input litcurve FITS file to get some values,
      which has been conducted binary-correction using aelceborbcor.sh.
      The OBS-MJD TSTART, and TSTOP keywords are obtained from this file.

   <OUTPUT>
      Name of output GTI file.

   <EPOCH>
      The arbitrary epoch time on MJD (day) for original point of rotation.

   <PERIOD>  
      Rotation period (sec).

   <IPHASE> 
      Initial phase value for clipping.

   <TPHASE> 
      Tail phase value for clipping.

   [IPHASE_EXT]
      Initial phase value for clipping non-conguous phase.

   [TPHASE_EXT]
      Tail phase value for clipping non-conguous phase.

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

   [PHITTAB]
     phi-time transefer table file

   <CLOBBER>
     If you set "CLOBBER=YES" output will be overwritten

EOF
    exit 1
}


gticor(){
    #---------------------------------------------------------------------------
    #input parameters
    #---------------------------------------------------------------------------
    outgti=$1     #; echo "outgti     ${outgti}" ##DEBUG
    in_lcfits=$2  #; echo "in_lcfits  ${in_lcfits}" ##DEBUG
    in_asini=$3   #; echo "in_asini   ${in_asini}" ##DEBUG
    in_ecc=$4     #; echo "in_ecc     ${in_ecc}" ##DEBUG
    in_omg=$5     #; echo "in_omg     ${in_omg}" ##DEBUG
    in_orbzero=$6 #; echo "in_orbzero ${in_orbzero}" ##DEBUG
    in_porb=$7    #; echo "in_porb    ${in_porb}" ##DEBUG
    in_phittab=$8 #; echo "in_phittba ${in_phittab}" ##DEBUG 
    
    
    #---------------------------------------------------------------------------
    #execute aegtieborbcor.sh
    #---------------------------------------------------------------------------
    ${gtieborbcor} LCFITS=${in_lcfits} INPUT=mkspingti_out.gti OUTPUT=${outgti} ASINI=${in_asini} ORBZERO=${in_orbzero} PORB=${in_porb} ECC=${in_ecc} OMG=${in_omg} phittab=${in_phittab}

    rm  mkspingti_out.gti
    echo " "
    echo "`basename $0` has done"
    
}

cleanftoolspar(){
    ${punlearn} fkeyprint
}


execute(){
    ## MAKE GTI FILE
    if [ "${FLG_EXT}" != "TRUE" ];then 
	aemkspingti.sh "LCFITS=${lcfits}" "EPOCH=${epoch}" "PERIOD=${period}" "IPHASE=${iph}" "TPHASE=${tph}" "OUTPUT=mkspingti_out.gti"
	
    ## MAKE GTI FILE (Non-contiguous phase) 	
    else     
	aemkspingti.sh "LCFITS=${lcfits}" "EPOCH=${epoch}" "PERIOD=${period}" "IPHASE=${iph}" "TPHASE=${tph}" "IPHASE_EXT=${iph2}" "TPHASE_EXT=${tph2}" "OUTPUT=mkspingti_out.gti"
    fi

    ## binary-correction
    gticor ${output} ${lcfits} ${asini} ${ecc} ${omg} ${orbzero} ${porb} ${phittab}
    cleanftoolspar
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
var10=${10} #;echo ${var10}
var11=${11} #;echo ${var11}
var12=${12} #;echo ${var12}
var13=${13} #;echo ${var13}
var14=${14} #;echo ${var14}
var15=${15} #;echo ${var15}

for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6} ${var7} ${var8} ${var9} ${var10} ${var11} ${var12} ${var13} ${var14} ${var15};do
    IFS='='
    set -- ${var}
    par=$1
    val=$2
    #echo "${par}" #DEBUG
    #echo "${val}" #DEBUG
    case ${par} in
        "LCFITS"|"lcfits") lcfits=${val} ;;
        "EPOCH"|"epoch") epoch=${val} ;;
        "PERIOD"|"period") period=${val} ;;
        "IPHASE"|"iphase") iph=${val} ;;
        "TPHASE"|"tphase") tph=${val} ;;
	"IPHASE_EXT"|"iphase_ext") iph2=${val} ;;
	"TPHASE_EXT"|"tphase_ext") tph2=${val} ;;
        "ASINI"|"asini") asini=${val} ;;
        "ORBZERO"|"orbzero") orbzero=${val} ;;
	"PORB"|"porb") porb=${val} ;;
	"ECC"|"ecc") ecc=${val} ;;
	"OMG"|"omg") omg=${val} ;;
	"PHITTAB"|"phittab") phittab=${val} ;;
        "OUTPUT"|"output") output=${val} ;;
        "CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) usage;;
    esac
done #for var in ${var*};do

#echo "LCFITS ${lcfits}" #DEBUG
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
    if [ ! -e ${lcfits} ]||[ _ = _${lcfits} ];then
        echo "`basename $0` couldn't find <LCFITS>."
	FLG_VAL="FALSE"
    fi
    
    if [ _${epoch} = _ ] ;then
	echo "Please enter value of <EPOCH>."
	FLG_VAL="FALSE"
    fi
    
    if [ _${period} = _ ] ;then
	echo "Please enter value of <PERIOD>."
	FLG_VAL="FALSE"
    fi
    
    if [ _${iph} = _ ] ;then
	echo "Please enter value of <IPHASE>."
	FLG_VAL="FALSE"
    fi

    if [ _${tph} = _ ] ;then
	echo "Please enter value of <TPHASE>."
	FLG_VAL="FALSE"
    fi
    
    if [ _${iph2} = _ ]&&[ _${tph2} != _ ];then
	echo "Please enter value of <IPHASE_EXT>."
	FLG_VAL="FALSE"
    fi

    if [ _${tph2} = _ ]&&[ _${iph2} != _ ];then
	echo "Please enter value of <TPHASE_EXT>."
	FLG_VAL="FALSE"
    fi
    
    if [ _${iph2} != _ ]&&[ _${tph2} != _ ];then
	FLG_EXT=TRUE
	#echo "Extra mode ON !!"
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

	## GTI already exist
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
