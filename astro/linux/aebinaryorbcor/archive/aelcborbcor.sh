#!/bin/bash

################################################################################
## Redaction History
################################################################################
# Ver.  | Date       | Author   | ∆‚Õ∆
#-------------------------------------------------------------------------------
# 1.0.0 | 2016.07.07 | yyoshida | prototype
# 1.0.1 | 2016.07.25 | yyoshida | debug of calucaration
#


################################################################################
#Set Parameter
################################################################################
version="1.0.1"
author="Y.Yoshida"


################################################################################
#Command
################################################################################
fcreate="$HEADAS/bin/fcreate"
fdump="$HEADAS/bin/fdump"
fappend="$HEADAS/bin/fappend"
fkeyprint="$HEADAS/bin/fkeyprint"
fparkey="$HEADAS/bin/fparkey"
punlearn="$HEADAS/bin/punlearn"


################################################################################
#Function
################################################################################
usage(){
cat <<EOF 
Usage     : `basename $0` <LCFITS> <ASINI> <ORBZERO> <PORB> [OUTPUT] [CLOBBER]
Example   : `basename $0` LCFITS=pin_nbg_12p0_70p0keV.lc \\
            ASINI=0.01 ORBZERO=5.550272484843833E+04 \\
            PORB=123.45 OUTPUT=pin_nbg_12p0_70p0keV_borbcor.lc
<PARAMETER>
  LCFIT   : input light curve FITS file
  ASINI)  : asin(i) in unit of lt-s, a:orbital radius; i:inclination angle
  ORBZERO : orbital origin (superior conjunction) in unit of MJD(day)
  PORB    : orbital period in unit of day
  OUTPUT  : output light curve FITS file
  CLOBBER : If you set "CLOBBER=YES" output will be overwritten

EOF
exit 1
}


title(){
cat <<EOF

binary orbit correction for SUZAKU light curve
`basename $0` ver${version} Written by ${author}

EOF
}


mklcfits(){
    #---------------------------------------------------------------------------
    #input parameters
    #---------------------------------------------------------------------------
    in_lcfits=$1  #; echo "in_lcfits  ${in_lcfits}" ##DEBUG
    outlcfits=$2  #; echo "outlcfits  ${outlcfits}" ##DEBUG
    in_asini=$3   #; echo "in_asini   ${in_asini}" ##DEBUG
    in_orbzero=$4 #; echo "in_orbzero ${in_orbzero}" ##DEBUG
    in_porb=$5    #; echo "in_porb    ${in_lcfits}" ##DEBUG


    #---------------------------------------------------------------------------
    #input FITS parameters
    #---------------------------------------------------------------------------
    obstimezero=`${fkeyprint} ${in_lcfits}+1 TIMEZERO|sed -n 's/TIMEZERO=//p'|awk '{print $1}'`
    mjdrefi=`${fkeyprint} ${in_lcfits}+1 MJDREFI|sed -n 's/MJDREFI =//p'|awk '{print $1}'`
    mjdreff=`${fkeyprint} ${in_lcfits}+1 MJDREFF|sed -n 's/MJDREFF =//p'|awk '{print $1}'`
    mjdrefzero=`echo "${mjdrefi} ${mjdreff}"|awk '{printf "%17.15e\n",$1+$2}'`
    obstimezeromjd=`echo "${mjdrefi} ${mjdreff} ${obstimezero}"|awk '{printf "%17.15e\n",$1+$2+$3/86400}'`
    obsmjdobs=`${fkeyprint} ${in_lcfits}+1 MJD-OBS|sed -n 's/MJD-OBS =//p'|awk '{print $1}'`
    obststart=`${fkeyprint} ${in_lcfits}+1 TSTART|sed -n 's/TSTART  =//p'|awk '{print $1}'`
    obststop=`${fkeyprint} ${in_lcfits}+1 TSTOP|sed -n 's/TSTOP   =//p'|awk '{print $1}'`


    #---------------------------------------------------------------------------
    #part of extension 1 RATE 
    #---------------------------------------------------------------------------
    ${fdump} ${in_lcfits}+1 aeborblcor.e1lc_temp1.dat " " - "prhead=no" #extract time,rate,err,frac
    sed '1,/count/d' aeborblcor.e1lc_temp1.dat|awk 'BEGIN{obsz='${obstimezeromjd}';orbz='${in_orbzero}';p='${in_porb}'}{printf "%17.15e %17.15e %9.7e %9.7e %9.7e\n",$2,($2/86400+obsz-orbz+0.25*p),$3,$4,$5}' > aeborblcor.e1lc_temp2.dat
    awk 'BEGIN{PI=atan2(0,-1);p='${in_porb}';asi='${in_asini}'}{printf "%17.15e %9.7e %9.7e %9.7e\n",$1+(asi*cos(($2/p)*PI)),$3,$4,$5}' aeborblcor.e1lc_temp2.dat > aeborblcor.e1lc_out.dat
    rm aeborblcor.e1lc_temp1.dat aeborblcor.e1lc_temp2.dat 
    ${fdump} ${lcfits}+1 aeborblcor.e1lc_head.dat " " - "prdata=no" #extract header of lc vie fdump
    #column descriptor file for "fcreate"
    cat << EOF > aeborblcor.e1lc_cdf.dat
TIME D s
RATE E count/s
ERROR E count/s
FRACEXP E
EOF
    ${fcreate} aeborblcor.e1lc_cdf.dat aeborblcor.e1lc_out.dat "headfile=aeborblcor.e1lc_head.dat" aeborblcor.e1.lc "extname=RATE" 
    rm aeborblcor.e1lc_head.dat aeborblcor.e1lc_out.dat aeborblcor.e1lc_cdf.dat


    #---------------------------------------------------------------------------
    #part of extension 2 GTI 
    #---------------------------------------------------------------------------
    ${fdump} ${lcfits}+2 aeborblcor.e2lc_temp1.dat " " - "prhead=no" #extract tstart,tstop
    sed '1,/s /d' aeborblcor.e2lc_temp1.dat|awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_orbzero}';p='${in_porb}'}{printf "%17.15e %17.15e %17.15e %17.15e\n",$2,($2/86400+mjdz-orbz+0.25*p),$3,($3/86400+mjdz-orbz+0.25*p)}' > aeborblcor.e2lc_temp2.dat
    awk 'BEGIN{PI=atan2(0,-1);p='${in_porb}';asi='${in_asini}'}{printf "%17.15e %17.15e\n",$1+(asi*cos(($2/p)*PI)),$3+(asi*cos(($4/p)*PI))}' aeborblcor.e2lc_temp2.dat > aeborblcor.e2lc_out.dat
    rm aeborblcor.e2lc_temp1.dat aeborblcor.e2lc_temp2.dat
    ${fdump} ${lcfits}+2 aeborblcor.e2lc_head.dat " " - "prdata=no" #extract header of lc vie fdump
    #column descriptor file for "fcreate"
    cat << EOF > aeborblcor.e2lc_cdf.dat 
START 1D s
STOT 1D s
EOF
    ${fcreate} aeborblcor.e2lc_cdf.dat aeborblcor.e2lc_out.dat "headfile=aeborblcor.e2lc_head.dat" aeborblcor.e2.lc "extname=GTI" 
    rm aeborblcor.e2lc_head.dat aeborblcor.e2lc_out.dat aeborblcor.e2lc_cdf.dat


    #---------------------------------------------------------------------------
    #part of marging of extension 1 & 2 
    #---------------------------------------------------------------------------
    ${fappend} aeborblcor.e2.lc+1 aeborblcor.e1.lc "pkeywds=yes"
    mv -f aeborblcor.e1.lc ${outlcfits}
    rm aeborblcor.e2.lc


    #---------------------------------------------------------------------------
    #part of modifying header
    #---------------------------------------------------------------------------
    
    #MJD-OBS
    obsmjdobs_cor=`echo ${obsmjdobs}|awk 'BEGIN{orbz='${in_orbzero}';p='${in_porb}'}{printf "%17.15e %17.15e\n",$1,($1-orbz+0.25*p)}'|awk 'BEGIN{PI=atan2(0,-1);p='${in_porb}';asi='${in_asini}'}{printf "%17.15e\n",$1+(asi*cos(($2/p)*PI))/86400}'`
    #echo "obsmjdobs       ${obsmjdobs}" ##debug
    #echo "obsmjdobs_cor   ${obsmjdobs_cor}" ##debug
    for ext in 1 2 ;do
	${fparkey} "comm=MJD of data start time" "add=no" <<EOF >/dev/null 2>&1
${obsmjdobs_cor}
${outlcfits}+${ext}
MJD-OBS
EOF
   done

    #TSTART
    obststart_cor=`echo ${obststart}|awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_orbzero}';p='${in_porb}'}{printf "%17.15e %17.15e\n",$1,($1/86400+mjdz-orbz+0.25*p)}'|awk 'BEGIN{PI=atan2(0,-1);p='${in_porb}';asi='${in_asini}'}{printf "%17.15e\n",$1+(asi*cos(($2/p)*PI))}'`
    #echo "obststart       ${obststart}" ##debug
    #echo "obststart_cor   ${obststart_cor}" ##debug
    for ext in 1 2 ;do
	${fparkey} "comm=time start" "add=no" <<EOF >/dev/null 2>&1
${obststart_cor}
${outlcfits}+${ext}
TSTART
EOF
    done


    #TSTOP
    obststop_cor=`echo ${obststop}|awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_orbzero}';p='${in_porb}'}{printf "%17.15e %17.15e\n",$1,($1/86400+mjdz-orbz+0.25*p)}'|awk 'BEGIN{PI=atan2(0,-1);p='${in_porb}';asi='${in_asini}'}{printf "%17.15e\n",$1+(asi*cos(($2/p)*PI))}'`
    #echo "obststop        ${obststop}" ##debug
    #echo "obststop_cor    ${obststop_cor}" ##debug
    for ext in 1 2 ;do
	${fparkey} "comm=time stop" "add=no" <<EOF>/dev/null 2>&1 
${obststop_cor}
${outlcfits}+${ext}
TSTOP
EOF
    done

    #TIMEZERO
    obstimezero_cor=`echo ${obstimezero}|awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_orbzero}';p='${in_porb}'}{printf "%17.15e %17.15e\n",$1,($1/86400+mjdz-orbz+0.25*p)}'|awk 'BEGIN{PI=atan2(0,-1);p='${in_porb}';asi='${in_asini}'}{printf "%17.15e\n",$1+(asi*cos(($2/p)*PI))}'`
    #echo "obstimezero     ${obstimezero}" ##debug
    #echo "obstimezero_cor ${obstimezero_cor}" ##debug
    for ext in 1 2 ;do
	${fparkey} "comm=Time Zero" "add=no" <<EOF >/dev/null 2>&1
${obstimezero_cor}
${outlcfits}+${ext}
TIMEZERO
EOF
    done

    #TELAPSE
    obstelapse=`echo ${obststart} ${obststop}|awk '{printf "%17.15e\n",$2-$1}'`
    obstelapse_cor=`echo ${obststart_cor} ${obststop_cor}|awk '{printf "%17.15e\n",$2-$1}'`
    #echo "obstelapse  ${obstelapse}" ##debug
    #echo "obstelapse_cor  ${obstelapse_cor}" ##debug
    for ext in 1 2 ;do
	${fparkey} "comm=elapsed time" "add=no" <<EOF >/dev/null 2>&1
${obstelapse_cor}
${outlcfits}+${ext}
TELAPSE
EOF
    done


    #---------------------------------------------------------------------------
    #messagenger
    #---------------------------------------------------------------------------
    cat <<EOF
Input lightcurve FITS File  : ${lcfits}
Output lightcurve FITS File : ${outlcfits}

Set parameters for correction as follows:
asin(i)        : ${asini}
orbital origin : ${orbzero}
orbital period : ${porb}

Modified paramters in Header of FITS File as follows:
MJD-OBS  : ${obsmjdobs} -> ${obsmjdobs_cor}
TSTART   : ${obststart} -> ${obststart_cor}
TSTOP    : ${obststop} -> ${obststop_cor}
TIMEZERO : ${obstimezero} -> ${obstimezero_cor}
TELAPSE  : ${obstelapse} -> ${obstelapse_cor}

`basename $0` has done.

EOF
}


cleanfoolspar(){
    ${punlearn} fdump
    ${punlearn} fcreate
    ${punlearn} fappend
    ${punlearn} fkeyprint
    ${punlearn} fparkey
}


################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o uh -- "$@"` ; [ $? != 0 ] && usage
eval set -- "$GETOPT"
while true ;do
  case $1 in
      -u|-h) 
	  title
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

for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6};do
    IFS='='
    set -- ${var}
    par=$1
    val=$2
    #echo "${par}" #DEBUG
    #echo "${val}" #DEBUG
    case ${par} in
        "LCFITS"|"lcfits") lcfits=${val} ;;
        "OUTPUT"|"output") output=${val} ;;
        "ASINI"|"asini") asini=${val} ;;
        "ORBZERO"|"orbzero") orbzero=${val} ;;
	"PORB"|"porb") porb=${val} ;;
        "CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) usage;;
    esac
done #for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6};do

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
    title
    usage
else
    if [ ! -e ${lcfits} ]||[ _ = _${lcfits} ];then
        echo "`basename $0` couldn't find \"${lcfits}\"."
        File_FLG=FALSE
    fi

    if [ _ = _${asini} ];then
        echo "Please enter <ASINI> !!"
        File_FLG=FALSE
    fi    
    
    if [ _ = _${orbzero} ];then
        echo "Please enter <ORBZERO> !!"
        File_FLG=FALSE
    fi

    if [ _ = _${porb} ];then
        echo "Please enter <ORBZERO> !!"
        File_FLG=FALSE
    fi

    if [ "${File_FLG}" = "FALSE" ];then
        exit 1
    fi

    if [ _ = _${output} ];then
        output=${lcfits%.lc}_borbcor.lc
    fi

    if [ ! -f ${output} ] ;then
	mklcfits ${lcfits} ${output} ${asini} ${orbzero} ${porb}
	cleanfoolspar
    else
	if [ "${FLG_OW}" = "YES" ]||[ "${FLG_OW}" = "yes" ] ;then
            rm ${output}
	    mklcfits ${lcfits} ${output} ${asini} ${orbzero} ${porb}
	    cleanfoolspar
	else
	    echo ""
	    echo "${outfile} already exists !!" # 1>&2
	    echo -n "Overwrite ?? (y/n) >> "
	    read answer
	    case ${answer} in
		y|Y|yes|Yes|YES)
		    rm ${output}
		    mklcfits ${lcfits} ${output} ${asini} ${orbzero} ${porb}
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


#EOF#