#!/bin/bash

################################################################################
## Redaction History
################################################################################
# Ver.  | Date       | Author   | ∆‚Õ∆
#-------------------------------------------------------------------------------
# 1.0.0 | 2016.07.07 | yyoshida | prototype
#


################################################################################
#Set Parameter
################################################################################
version="1.0.0"
author="Y.Yoshida"


################################################################################
#Command
################################################################################
more="/usr/bin/jless"
fkeyprint="$HEADAS/bin/fkeyprint"
punlearn="$HEADAS/bin/punlearn"


################################################################################
#Function
################################################################################
title(){
cat <<EOF
`basename $0` -- binary orbit correction for SUZAKU spin GTI
ver${version} Written by ${author}

EOF
}

usage(){
    cat <<EOF |${more}
`basename $0` -- binary orbit correction for SUZAKU spin GTI
ver${version} Written by ${author}

USAGE: 
   `basename $0` [OPTION] <LCFITS> <EPOCH> <PERIOD> <IPHASE> <TPHASE> \\
   [IPHASE_EXT] [TPHASE_EXT] <ASINI> <ORBZERO> <PORB> <OUTPUT> [CLOBBER] 

EXAMPLE: 
   `basename $0` LCFITS=x0_src.lc EPOCH=54051.93313 PERIOD=17279.219 \\
   IPHASE=0.3 TPHASE=0.5 ASINI=10.0 ORBZERO=5.550272484843833E+04 \\
   PORB=123.45 OUTPUT=x0_03_05_borbcor.gti 

PARAMETERS:
   <LCFITS>
      Name of the input litcurve FITS file to get some values,
      which has been conducted binary-correction using aelcborbcor.sh.
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
     orbital origin (superior conjunction) in unit of MJD(day)

   <PORB> 
     orbital period in unit of day

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
    in_orbzero=$4 #; echo "in_orbzero ${in_orbzero}" ##DEBUG
    in_porb=$5    #; echo "in_porb    ${in_porb}" ##DEBUG
    
    
    #---------------------------------------------------------------------------
    #input FITS parameters
    #---------------------------------------------------------------------------
    obstimezero=`${fkeyprint} ${in_lcfits}+1 TIMEZERO|sed -n 's/TIMEZERO=//p'|awk '{print $1}'`
    mjdrefi=`${fkeyprint} ${in_lcfits}+1 MJDREFI|sed -n 's/MJDREFI =//p'|awk '{print $1}'`
    mjdreff=`${fkeyprint} ${in_lcfits}+1 MJDREFF|sed -n 's/MJDREFF =//p'|awk '{print $1}'`
    mjdrefzero=`echo "${mjdrefi} ${mjdreff}"|awk '{printf "%17.15e\n",$1+$2}'`
    mjd0=`${fkeyprint} ${in_lcfits}+1 MJD-OBS|sed -n 's/MJD-OBS = //p'|awk '{print $1}'`
    tstart=`${fkeyprint} ${in_lcfits}+1 TSTART|sed -n 's/TSTART  = //p'|awk '{print $1}'`
    tstop=`${fkeyprint} ${in_lcfits}+1 TSTOP|sed -n 's/TSTOP   = //p'|awk '{print $1}'`
    
    #---------------------------------------------------------------------------
    #modify GTI table
    #---------------------------------------------------------------------------
    awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_orbzero}';p='${in_porb}'}{printf "%17.15e %17.15e %17.15e %17.15e %17.15f\n",$1,($1/86400+mjdz-orbz+0.5*p),$2,($2/86400+mjdz-orbz+0.5*p),$3}' tmp1.gti > tmp2.gti
    awk 'BEGIN{PI=atan2(0,-1);p='${in_porb}';asi='${in_asini}'}{printf "%17.15e %17.15e %17.15f\n",$1-(asi*cos(($2/p)*PI)),$3-(asi*cos(($4/p)*PI)),$5}' tmp2.gti > ${outgti}
    rm tmp1.gti tmp2.gti
    
    
    #---------------------------------------------------------------------------
    #messagenger
    #---------------------------------------------------------------------------
    cat <<EOF
Input lightcurve FITS File  : ${in_lcfits}

Setted paramters as follow:
MJD-OBS         :  ${mjd0}
TSTART          :  ${tstart}
TSTOP           :  ${tstop}
EPOCH           :  ${epoch}
PERIOD          :  ${period}
INTERVAL PHASE  :  ${iph} - ${tph}
asin(i)         :  ${asini}
orbital origin  :  ${orbzero}
orbital period  :  ${porb}

Output GTI File : ${outgti}
`basename $0` has done.
EOF
}

cleanfoolspar(){
    ${punlearn} fkeyprint
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

for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6} ${var7} ${var8} ${var9} ${var10} ${var11} ${var12};do
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
        File_FLG=FALSE
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
	echo "Extra mode ON !!"
    fi
    
    if [ _${asini} = _ ];then
        echo "Please enter value of <ASINI> !!"
        File_FLG=FALSE
    fi    
    
    if [ _${orbzero} = _ ];then
        echo "Please enter value of <ORBZERO> !!"
        File_FLG=FALSE
    fi
    
    if [ _${porb} = _ ];then
        echo "Please enter value of <PORB> !!"
        File_FLG=FALSE
    fi

    if [ _${output} = _ ] ;then
	echo "Please enter filename of <OUTPUT>."
	FLG_VAL="FALSE"
    fi

    if [ "${FLG_VAL}" = "FALSE" ];then
        exit 1
    else
	if [ ! -e ${output} ] ;then
	    if [ "${FLG_EXT}" != "TRUE" ];then ## MAKE GTI FILE
		aemkspingti.sh "PHAFILE=${lcfits}" "EPOCH=${epoch}" "PERIOD=${period}" "IPHASE=${iph}" "TPHASE=${tph}" "OUTPUT=tmp1.gti" >/dev/null 2>&1 
	    else     ## MAKE GTI FILE (Non-contiguous phase) 	
		aemkspingti.sh "PHAFILE=${lcfits}" "EPOCH=${epoch}" "PERIOD=${period}" "IPHASE=${iph}" "TPHASE=${tph}" "IPHASE_EXT=${iph2}" "TPHASE_EXT=${tph2}" "OUTPUT=tmp1.gti" >/dev/null 2>&1 
	    fi
	    gticor ${output} ${lcfits} ${asini} ${orbzero} ${porb}
	    cleanfoolspar
	else
	    if [ "${FLG_OW}" = "YES" ]||[ "${FLG_OW}" = "yes" ] ;then
		rm ${output}	
		if [ "${FLG_EXT}" != "TRUE" ];then ## MAKE GTI FILE
		    aemkspingti.sh "PHAFILE=${lcfits}" "EPOCH=${epoch}" "PERIOD=${period}" "IPHASE=${iph}" "TPHASE=${tph}" "OUTPUT=tmp1.gti" >/dev/null 2>&1 
		else     ## MAKE GTI FILE (Non-contiguous phase) 	
		    aemkspingti.sh "PHAFILE=${lcfits}" "EPOCH=${epoch}" "PERIOD=${period}" "IPHASE=${iph}" "TPHASE=${tph}" "IPHASE_EXT=${iph2}" "TPHASE_EXT=${tph2}" "OUTPUT=tmp1.gti" >/dev/null 2>&1 
		fi
		gticor ${output} ${lcfits} ${asini} ${orbzero} ${porb}
		cleanfoolspar
	    else
	    echo "${output} already exists !!" # 1>&2
	    echo -n "Overwrite ?? (y/n) >> "
	    read answer
	    case ${answer} in
		y|Y|yes|Yes|YES)
		    rm ${output}
		    if [ "${FLG_EXT}" != "TRUE" ];then ## MAKE GTI FILE
			aemkspingti.sh "PHAFILE=${lcfits}" "EPOCH=${epoch}" "PERIOD=${period}" "IPHASE=${iph}" "TPHASE=${tph}" "OUTPUT=tmp1.gti" >/dev/null 2>&1
		    else     ## MAKE GTI FILE (Non-contiguous phase) 	
			aemkspingti.sh "PHAFILE=${lcfits}" "EPOCH=${epoch}" "PERIOD=${period}" "IPHASE=${iph}" "TPHASE=${tph}" "IPHASE_EXT=${iph2}" "TPHASE_EXT=${tph2}" "OUTPUT=tmp1.gti" >/dev/null 2>&1 
		    fi
		    gticor ${output} ${lcfits} ${asini} ${orbzero} ${porb}
		    cleanfoolspar
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