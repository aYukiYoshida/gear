#!/bin/bash -f

################################################################################
## Redaction History
################################################################################
# Version | Date       | Author   | ∆‚Õ∆
#-------------------------------------------------------------------------------
# 1.0.0   | 2016.07.22 | yyoshida | prototype
# 1.1.0   | 2017.02.20 | yyoshida | introduce python module
# 1.1.1   | 2017.05.01 | yyoshida | modify calculation part
#


################################################################################
#Set Parameter
################################################################################
version="1.1.1"
author="Y.Yoshida"
local="/home/yyoshida/local/bin"

################################################################################
#Command
################################################################################
fcreate="$HEADAS/bin/fcreate"
fdump="$HEADAS/bin/fdump"
fappend="$HEADAS/bin/fappend"
fkeyprint="$HEADAS/bin/fkeyprint"
fparkey="$HEADAS/bin/fparkey"
punlearn="$HEADAS/bin/punlearn"
mkphittabawk="${local}/aelceborbcor/mkphittab.awk"
mkphittabpy="${local}/aelceborbcor/mkphittab.py"
transdayphipy="${local}/aelceborbcor/transtimphi.py"


################################################################################
#Function
################################################################################
usage(){
cat <<EOF 
USAGE:
  `basename $0` <LCFITS> <ASINI> <PORB> <ECC> <OMG> <PERAST> [PHITTAB] [OUTPUT] [CLOBBER]

PARAMETERS:
  <LCFITS>
    input light curve FITS file
  
  <ASINI>
    projected semimajor axis in unit of lt-s
  
  <PORB>
    orbital period in unit of day

  <ECC>
    eccentricity of orbital  

  <PERAST>
    Time of superior conjunction or periastron passage in unit of MJD(day)

  <OMG>
     Longitude at the PERAST in unit of degree

  [PHITTAB]
     phi-time transefer table file
  
  [OUTPUT]
    output light curve FITS file

  [CLOBBER]
    If you set "CLOBBER=YES" output will be overwritten

EXAMPLE:
  `basename $0` LCFITS=pin_nbg_12p0_70p0keV.lc ASINI=0.01 ECC=0.3 OMG=60 \\
  PERAST=5.55027E+04 PORB=123.45 OUTPUT=pin_nbg_12p0_70p0keV_eborbcor.lc 
 
EOF
exit 1
}


title(){
cat <<EOF
`basename $0` -- binary elliptical orbit correction for SUZAKU light curve
version ${version} Written by ${author}

EOF
}


mklcfits(){
    title ## show title

    #---------------------------------------------------------------------------
    #input parameters
    #---------------------------------------------------------------------------
    in_lcfits=$1  #; echo "in_lcfits  ${in_lcfits}" ##DEBUG
    outlcfits=$2  #; echo "outlcfits  ${outlcfits}" ##DEBUG
    in_asini=$3   #; echo "in_asini   ${in_asini}" ##DEBUG
    in_ecc=$4     #; echo "in_ecc     ${in_ecc}" ##DEBUG
    in_omg=$5     #; echo "in_omg     ${in_omg}" ##DEBUG
    in_perast=$6  #; echo "in_perast  ${in_perast}" ##DEBUG
    in_porb=$7    #; echo "in_porb    ${in_porb}" ##DEBUG
    in_phittab=$8 #; echo "in_phittba ${in_phittab}" ##DEBUG 


    #---------------------------------------------------------------------------
    #messagenger part1
    #---------------------------------------------------------------------------
    cat <<EOF
Input lightcurve FITS File  : ${in_lcfits}
Input phittable File        : ${in_phittab}

Set parameters for correction as follows:
asin(i)        : ${in_asini}
orbital period : ${in_porb}
periastron     : ${in_perast}
omega          : ${in_omg}
eccentricity   : ${in_ecc}

EOF


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

    #echo "obstimezero    ${obstimezero}" ##DEBUG
    #echo "mjdrefzero     ${mjdrefzero}" ##DEBUG
    #echo "obstimezeromjd ${obstimezeromjd}" ##DEBUG
    #echo "obsmjdobs      ${obsmjdobs}" ##DEBUG
    #echo "obststart      ${obststart}" ##DEBUG
    #echo "obststop       ${obststop}" ##DEBUG


    #---------------------------------------------------------------------------
    #make phittable
    #---------------------------------------------------------------------------
    echo "STAGE 1 : make phittable"
    if [ ! -e ${in_phittab} ];then
	#${mkphittabawk} -v P=${in_porb} -v e=${in_ecc} -v mjdz=${mjdrefzero} -v obsta=${obststart} -v obstp=${obststop} -v orbz=${in_perast} > ${in_phittab}
	${mkphittabpy} --orb=${in_porb} --ecc=${in_ecc} --mjdz=${mjdrefzero} --obsta=${obststart} --obstp=${obststop} --orbz=${in_perast} > ${in_phittab}
	echo "STAGE 1 finished"
    else
	echo "STAGE 1 skipped"
    fi
    echo " "


    #---------------------------------------------------------------------------
    #part of extension 1 RATE 
    #---------------------------------------------------------------------------
    echo "STAGE 2 : make 1st extension of FITS file"
    #extract time,rate,err,frac
    [ -e aelceborbcor.e1lc_temp1.dat ]&&rm aelceborbcor.e1lc_temp1.dat
    ${fdump} ${in_lcfits}+1 aelceborbcor.e1lc_temp1.dat " " - "prhead=no"


    #calc day from orbital zero point
    echo "  STAGE 2-1 : calc day from orbital zero point"
    sed '1,/count/d' aelceborbcor.e1lc_temp1.dat|awk 'BEGIN{obsz='${obstimezeromjd}';orbz='${in_perast}';p='${in_porb}'}{printf "%17.15e %17.15f %9.7e %9.7e %9.7e\n",$2,($2/86400+obsz-orbz),$3,$4,$5}' > aelceborbcor.e1lc_temp2.dat
    
    
    #translation time to radian via searching table    
    echo "  STAGE 2-2 : translation time to radian via searching table" 
    [ -e aelceborbcor.e1lc_temp3.dat ]&&rm aelceborbcor.e1lc_temp3.dat
    #touch aelceborbcor.e1lc_temp3.dat
    #while read line ;do
	#echo ${line} ##DEBUG
        #day=`echo ${line}|awk '{print $2}'` #;echo ${day} ##DEBUG
	#awk -v day=${day} '{if($2<=day){pfrt=$1;tfday=$2;row=FNR}}FNR==row+1{pbak=$1;tbday=$2}END{printf "%17.15e\n",pfrt+(pbak-pfrt)*(day-tfday)/(tbday-tfday)}' ${in_phittab} >> aelceborbcor.e1lc_temp3.dat
    #done < aelceborbcor.e1lc_temp2.dat
    ${transdayphipy} --tab=${in_phittab} --lcdat=aelceborbcor.e1lc_temp2.dat 
    #^transdayphioutlc.dat is created
    mv -f transdayphioutlc.dat aelceborbcor.e1lc_temp3.dat
    

    #binary-correction
    echo "  STAGE 2-3 : binary-correction" 
    paste aelceborbcor.e1lc_temp2.dat aelceborbcor.e1lc_temp3.dat|awk 'BEGIN{PI=atan2(0,-1);asi='${in_asini}';e='${in_ecc}';omgdeg='${in_omg}';omg=omgdeg/180*PI}{printf "%17.15e %9.7e %9.7e %9.7e\n",$1-(asi*(1-e^2)*sin($6+omg)/(1+e*cos($6+omg))),$3,$4,$5}' > aelceborbcor.e1lc_out.dat
    rm aelceborbcor.e1lc_temp1.dat aelceborbcor.e1lc_temp2.dat aelceborbcor.e1lc_temp3.dat


    echo "  STAGE 2-4 : make temporal FITS file" 
    #extract header of lc vie fdump  
    ${fdump} ${lcfits}+1 aelceborbcor.e1lc_head.dat " " - "prdata=no" 


    #column descriptor file for "fcreate"
    cat << EOF > aelceborbcor.e1lc_cdf.dat
TIME D s
RATE E count/s
ERROR E count/s
FRACEXP E
EOF

    
    #fcreate
    ${fcreate} aelceborbcor.e1lc_cdf.dat aelceborbcor.e1lc_out.dat "headfile=aelceborbcor.e1lc_head.dat" aelceborbcor.e1.lc "extname=RATE" "clobber=yes"
    rm aelceborbcor.e1lc_cdf.dat aelceborbcor.e1lc_out.dat aelceborbcor.e1lc_head.dat

    echo "STAGE 2 finished"
    echo " "

    #---------------------------------------------------------------------------
    #part of extension 2 GTI 
    #--------------------------------------------------------------------------
    echo "STAGE 3 : make 2nd extension of FITS file"
    #extract tstart,tstop
    [ -e aelceborbcor.e2lc_temp1.dat ]&&rm aelceborbcor.e2lc_temp1.dat
    ${fdump} ${lcfits}+2 aelceborbcor.e2lc_temp1.dat " " - "prhead=no" 
    
    
    #calc day from orbital zero point
    echo "  STAGE 3-1 : calc day from orbital zero point" ##debug
    sed '1,/s /d' aelceborbcor.e2lc_temp1.dat|awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_perast}'}{printf "%17.15e %17.15e %17.15e %17.15e\n",$2,($2/86400+mjdz-orbz),$3,($3/86400+mjdz-orbz)}' > aelceborbcor.e2lc_temp2.dat


    #translation time to radian via searching table
    echo "  STAGE 3-2 : translation time to radian via searching table" 
    [ -e aelceborbcor.e2lc_temp3.dat ]&&rm aelceborbcor.e2lc_temp3.dat

    #touch aelceborbcor.e2lc_temp3.dat
    #while read line 
    #do
	#echo ${line} ##DEBUG
        #st_day=`echo ${line}|awk '{print $2}'` 
	#sp_day=`echo ${line}|awk '{print $4}'` 
	#echo ${st_day} ${sp_day} ##DEBUG
	#st_day_phi=`awk -v day=${st_day} '{if($2<=day){pfrt=$1;tfday=$2;row=FNR}}FNR==row+1{pbak=$1;tbday=$2}END{printf "%17.15e\n",pfrt+(pbak-pfrt)*(day-tfday)/(tbday-tfday)}' ${in_phittab}`
	#sp_day_phi=`awk -v day=${sp_day} '{if($2<=day){pfrt=$1;tfday=$2;row=FNR}}FNR==row+1{pbak=$1;tbday=$2}END{printf "%17.15e\n",pfrt+(pbak-pfrt)*(day-tfday)/(tbday-tfday)}' ${in_phittab}`
	#echo ${st_day_phi} ${sp_day_phi} >> aelceborbcor.e2lc_temp3.dat
    #done < aelceborbcor.e2lc_temp2.dat

    ${transdayphipy} --tab=${in_phittab} --gtidat=aelceborbcor.e2lc_temp2.dat 
    #^transdayphioutgti.dat is created
    mv -f transdayphioutgti.dat aelceborbcor.e2lc_temp3.dat


    #binary-correction
    echo "  STAGE 3-3 : binary-correction"
    paste aelceborbcor.e2lc_temp2.dat aelceborbcor.e2lc_temp3.dat|awk 'BEGIN{PI=atan2(0,-1);asi='${in_asini}';e='${in_ecc}';omgdeg='${in_omg}';omg=omgdeg/180*PI}{printf "%17.15e %17.15e\n",$1-(asi*(1-e^2)*sin($5+omg)/(1+e*cos($5+omg))),$3-(asi*(1-e^2)*sin($6+omg)/(1+e*cos($6+omg)))}' > aelceborbcor.e2lc_out.dat
    rm aelceborbcor.e2lc_temp1.dat aelceborbcor.e2lc_temp2.dat aelceborbcor.e2lc_temp3.dat


    echo "  STAGE 3-4 : make temporal FITS file"
    #extract header of lc vie fdump
    ${fdump} ${lcfits}+2 aelceborbcor.e2lc_head.dat " " - "prdata=no" 
    
    #column descriptor file for "fcreate"
    cat << EOF > aelceborbcor.e2lc_cdf.dat 
START 1D s
STOT 1D s
EOF
    
    #fcreate
    ${fcreate} aelceborbcor.e2lc_cdf.dat aelceborbcor.e2lc_out.dat "headfile=aelceborbcor.e2lc_head.dat" aelceborbcor.e2.lc "extname=GTI" "clobber=yes"
    rm aelceborbcor.e2lc_head.dat aelceborbcor.e2lc_out.dat aelceborbcor.e2lc_cdf.dat

    echo "STAGE 3 finished"
    echo " "


    
    #---------------------------------------------------------------------------
    #part of marging of extension 1 & 2 
    #---------------------------------------------------------------------------
    echo "STAGE 4 : make FITS file"
    ${fappend} aelceborbcor.e2.lc+1 aelceborbcor.e1.lc "pkeywds=yes"
    mv -f aelceborbcor.e1.lc ${outlcfits}
    rm aelceborbcor.e2.lc
    echo "STAGE 4 finished"
    echo " "


    #---------------------------------------------------------------------------
    #part of modifying header
    #---------------------------------------------------------------------------
    echo "STAGE 5 : modify header ked of FITS file"
    #MJD-OBS
    obsmjdobs_tmp=`echo ${obsmjdobs}|awk 'BEGIN{orbz='${in_perast}'}{printf "%17.15e\n",($1-orbz)}'`
    #obsmjdobs_phi=`awk -v day=${obsmjdobs_tmp} '{if($2<=day){pfrt=$1;tfday=$2;row=FNR}}FNR==row+1{pbak=$1;tbday=$2}END{printf "%17.15e\n",pfrt+(pbak-pfrt)*(day-tfday)/(tbday-tfday)}' ${in_phittab}`
    obsmjdobs_phi=`${transdayphipy} --tab=${in_phittab} --day=${obsmjdobs_tmp}`
    obsmjdobs_cor=`echo ${obsmjdobs} ${obsmjdobs_phi}|awk 'BEGIN{PI=atan2(0,-1);asi='${in_asini}';e='${in_ecc}';omgdeg='${in_omg}';omg=omgdeg/180*PI}{printf "%17.15e\n",$1-(asi*(1-e^2)*sin($2+omg)/(1+e*cos($2+omg)))/86400}'`
    #echo "obsmjdobs      ${obsmjdobs}"     ##debug
    #echo "obsmjdobs_tmp  ${obsmjdobs_tmp}" ##debug
    #echo "obsmjdobs_phi  ${obsmjdobs_phi}" ##debug
    #echo "obsmjdobs_cor  ${obsmjdobs_cor}" ##debug
    for ext in 1 2 ;do
	${fparkey} "comm=MJD of data start time" "add=no" <<EOF >/dev/null 2>&1
${obsmjdobs_cor}
${outlcfits}+${ext}
MJD-OBS
EOF
   done


    #TSTART
    obststart_tmp=`echo ${obststart}|awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_perast}'}{printf "%17.15e\n",($1/86400+mjdz-orbz)}'`
    #obststart_phi=`awk -v day=${obststart_tmp} '{if($2<=day){pfrt=$1;tfday=$2;row=FNR}}FNR==row+1{pbak=$1;tbday=$2}END{printf "%17.15e\n",pfrt+(pbak-pfrt)*(day-tfday)/(tbday-tfday)}' ${in_phittab}`
    obststart_phi=`${transdayphipy} --tab=${in_phittab} --day=${obststart_tmp}`
    obststart_cor=`echo ${obststart} ${obststart_phi}|awk 'BEGIN{PI=atan2(0,-1);asi='${in_asini}';e='${in_ecc}';omgdeg='${in_omg}';omg=omgdeg/180*PI}{printf "%17.15e\n",$1-(asi*(1-e^2)*sin($2+omg)/(1+e*cos($2+omg)))}'`
    #echo "obststart       ${obststart}"     ##debug
    #echo "obststart_tmp   ${obststart_tmp}" ##debug
    #echo "obststart_phi   ${obststart_phi}" ##debug
    #echo "obststart_cor   ${obststart_cor}" ##debug
    for ext in 1 2 ;do
	${fparkey} "comm=time start" "add=no" <<EOF >/dev/null 2>&1
${obststart_cor}
${outlcfits}+${ext}
TSTART
EOF
    done


    #TSTOP
    obststop_tmp=`echo ${obststop}|awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_perast}'}{printf "%17.15e\n",($1/86400+mjdz-orbz)}'`
    #obststop_phi=`awk -v day=${obststop_tmp} '{if($2<=day){pfrt=$1;tfday=$2;row=FNR}}FNR==row+1{pbak=$1;tbday=$2}END{printf "%17.15e\n",pfrt+(pbak-pfrt)*(day-tfday)/(tbday-tfday)}' ${in_phittab}`
    obststop_phi=`${transdayphipy} --tab=${in_phittab} --day=${obststop_tmp}`
    obststop_cor=`echo ${obststop} ${obststop_phi}|awk 'BEGIN{PI=atan2(0,-1);asi='${in_asini}';e='${in_ecc}';omgdeg='${in_omg}';omg/180*PI}{printf "%17.15e\n",$1-(asi*(1-e^2)*sin($2+omg)/(1+e*cos($2+omg)))}'`

    #echo "obststop       ${obststop}"     ##debug
    #echo "obststop_tmp   ${obststop_tmp}" ##debug
    #echo "obststop_phi   ${obststop_phi}" ##debug
    #echo "obststop_cor   ${obststop_cor}" ##debug
    for ext in 1 2 ;do
	${fparkey} "comm=time stop" "add=no" <<EOF>/dev/null 2>&1 
${obststop_cor}
${outlcfits}+${ext}
TSTOP
EOF
    done


    #TIMEZERO
    obstimezero_tmp=`echo ${obstimezero}|awk 'BEGIN{mjdz='${mjdrefzero}';orbz='${in_perast}'}{printf "%17.15e\n",($1/86400+mjdz-orbz)}'`
    #obstimezero_phi=`awk -v day=${obstimezero_tmp} '{if($2<=day){pfrt=$1;tfday=$2;row=FNR}}FNR==row+1{pbak=$1;tbday=$2}END{printf "%17.15e\n",pfrt+(pbak-pfrt)*(day-tfday)/(tbday-tfday)}' ${in_phittab}`
    obstimezero_phi=`${transdayphipy} --tab=${in_phittab} --day=${obstimezero_tmp}`
    obstimezero_cor=`echo ${obstimezero} ${obstimezero_phi}|awk 'BEGIN{PI=atan2(0,-1);asi='${in_asini}';e='${in_ecc}';omg='${in_omg}'/180*PI}{printf "%17.15e\n",$1-(asi*(1-e^2)*sin($2+omg)/(1+e*cos($2+omg)))}'`

    #echo "obstimezero     ${obstimezero}"     ##debug
    #echo "obstimezero_tmp ${obstimezero_tmp}" ##debug
    #echo "obstimezero_phi ${obstimezero_phi}" ##debug
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
    #messagenger part2
    #---------------------------------------------------------------------------
    cat <<EOF
  Modified paramters in Header of FITS File as follows:
  MJD-OBS  : ${obsmjdobs} -> ${obsmjdobs_cor}
  TSTART   : ${obststart} -> ${obststart_cor}
  TSTOP    : ${obststop} -> ${obststop_cor}
  TIMEZERO : ${obstimezero} -> ${obstimezero_cor}
  TELAPSE  : ${obstelapse} -> ${obstelapse_cor}
STAGE 5 finished

Output lightcurve FITS File : ${outlcfits}
`basename $0` has done without any errors.
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
var7=$7 #;echo ${var7}
var8=$8 #;echo ${var8}
var9=$9 #;echo ${var8}


for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6} ${var7} ${var8} ${var9};do
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
        "PERAST"|"perast") perast=${val} ;;
	"PORB"|"porb") porb=${val} ;;
	"ECC"|"ecc") ecc=${val} ;;
	"OMG"|"omg") omg=${val} ;;
	"PHITTAB"|"phittab") phittab=${val} ;;
        "CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) usage;;
    esac
done #for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6} ${var7} ${var8} ${var9};do

#echo "LCFITS  ${lcfits}"   #DEBUG
#echo "OUTPUT  ${output}"   #DEBUG
#echo "PORB    ${porb}"     #DEBUG
#echo "ASINI   ${asini}"    #DEBUG
#echo "PERAST  ${perast}"   #DEBUG
#echo "ECC     ${ecc}"      #DEBUG
#echo "OMG     ${omg}"      #DEBUG
#echo "PHITTAB ${phittab}"  #DEBUG
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
    
    if [ _ = _${perast} ];then
        echo "Please enter <PERAST> !!"
        File_FLG=FALSE
    fi

    if [ _ = _${porb} ];then
        echo "Please enter <PORB> !!"
        File_FLG=FALSE
    fi

    if [ _ = _${ecc} ];then
        echo "Please enter <ECC> !!"
        File_FLG=FALSE
    fi

    if [ _ = _${omg} ];then
        echo "Please enter <omg> !!"
        File_FLG=FALSE
    fi

    if [ "${File_FLG}" = "FALSE" ];then
        exit 1
    fi

    if [ _ = _${output} ];then
        output=${lcfits%.lc}_eborbcor.lc
    fi

    if [ _ = _${phittab} ];then
        phittab=aelceborbcor.phittab.dat
    fi

    if [ ! -e ${output} ] ;then
	mklcfits ${lcfits} ${output} ${asini} ${ecc} ${omg} ${perast} ${porb} ${phittab}
	cleanfoolspar
    else
	if [ "${FLG_OW}" = "YES" ]||[ "${FLG_OW}" = "yes" ] ;then
            rm ${output}
	    mklcfits ${lcfits} ${output} ${asini} ${ecc} ${omg} ${perast} ${porb} ${phittab}
	    cleanfoolspar
	else
	    echo ""
	    echo "${output} already exists !!" # 1>&2
	    echo -n "Overwrite ?? (y/n) >> "
	    read answer
	    case ${answer} in
		y|Y|yes|Yes|YES)
		    rm ${output}
		    mklcfits ${lcfits} ${output} ${asini} ${ecc} ${omg} ${perast} ${porb} ${phittab}
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
