#!/bin/bash -f

################################################################################
## Redaction History
################################################################################
# Version | Date       | Author   | Contents
#-------------------------------------------------------------------------------
#     1.0 | 2017.07.02 | yyoshida | prototype
#


################################################################################
#Set Parameter
################################################################################
version="1.0"
author="Y.Yoshida"


################################################################################
#Command
################################################################################
fcreate="$HEADAS/bin/fcreate"
fdump="$HEADAS/bin/fdump"
fappend="$HEADAS/bin/fappend"
fkeyprint="$HEADAS/bin/fkeyprint"
fparkey="$HEADAS/bin/fparkey"
flcol="$HEADAS/bin/flcol"
fcopy="$HEADAS/bin/fcopy"
faddcol="$HEADAS/bin/faddcol"
fdelcol="$HEADAS/bin/fdelcol"
fdelhdu="$HEADAS/bin/fdelhdu"
punlearn="$HEADAS/bin/punlearn"
scriptname=$(basename $0)
[ -L ${scriptname} ] && scriptname=$(readlink ${scriptname})
sys=$(cd $(dirname ${scriptname}); pwd)
eborbcorpy="${sys}/eborbcor.py"


################################################################################
#Function
################################################################################
usage(){
cat <<EOF 
USAGE:
  `basename $0` <INPUT> <ASINI> <PORB> <ECC> <OMG> <PERAST|SPCONJ> [TABLE] [OUTPUT] [CLOBBER]

PARAMETERS:
  <INPUT>
    input event FITS file
  
  <ASINI>
    projected semimajor axis in unit of lt-s
  
  <PORB>
    orbital period in unit of day

  <ECC>
    eccentricity of orbital  

  <SPCONJ>
    Time of superior conjunction in unit of MJD(day)

  <PERAST>
    Periastron passage in unit of MJD(day)

  <OMG>
     Longitude at the PERAST in unit of degree

  [TABLE]
     phase-angel-elapsedtime transefer table file
  
  [OUTPUT]
    output event FITS file

  [CLOBBER]
    If you set "CLOBBER=YES" output will be overwritten

EXAMPLE:
  `basename $0` INPUT=pin_nbg.evt ASINI=0.01 ECC=0.3 OMG=60 \\
  PERAST=5.55027E+04 PORB=123.45 OUTPUT=pin_nbg_borbcor.evt
 
EOF
exit 1
}


title(){
cat <<EOF
`basename $0` -- binary elliptical orbit correction for SUZAKU event file
version ${version} Written by ${author}

EOF
}


corevtfits(){
    title ## show title

    #---------------------------------------------------------------------------
    # set parameters
    #---------------------------------------------------------------------------
    finput=$1   #; echo "finput   ${finput}" ##DEBUG
    foutput=$2  #; echo "foutput  ${foutput}" ##DEBUG
    fasini=$3   #; echo "fasini   ${fasini}" ##DEBUG
    fecc=$4     #; echo "fecc     ${fecc}" ##DEBUG
    fomg=$5     #; echo "fomg     ${fomg}" ##DEBUG
    fporb=$6    #; echo "fporb    ${fporb}" ##DEBUG
    ftable=$7   #; echo "ftable   ${ftable}" ##DEBUG 
    forbzero=$8 #; echo "forbzero ${forbzero}" ##DEBUG
    fozflg=$9   #; echo "fozflg   ${fozflg}" ##DEBUG 

    #---------------------------------------------------------------------------
    # messagenger part1
    #---------------------------------------------------------------------------

    echo "INPUT EVENTS FITS FILE  : ${finput}"
    echo "Set parameters for correction as follows;"
    echo "asin(i) (lt-s)          : ${fasini}"
    echo "orbital period (day)    : ${fporb}"
    echo "omega (deg)             : ${fomg}"
    echo "eccentricity            : ${fecc}"
    
    case ${fozflg} in
	"p") fperast=${forbzero} ;echo "periastron (MJD)        : ${fperast}";;
	"s") fspconj=${forbzero} ;echo "super-conjunction (MJD) : ${fspconj}";;
    esac
    echo " "

    
    ##--------------------------------------------------------------------------
    ## STAGE 1 :make orbital table
    ##--------------------------------------------------------------------------
    echo "STAGE 1 : make orbital table"
    if [ ! -e ${ftable} ];then
	${eborbcorpy} --mode=calc --PORB=${fporb} --ECC=${fecc} --TAB=${ftable} --imgout >/dev/null 2>&1
	echo "STAGE 1 finished. ${ftable} was generated."
    else
	echo "STAGE 1 skipped. ${ftable} already exists."
    fi
    echo " "


    ##--------------------------------------------------------------------------
    ## STAGE 2 : make binary-corrected FITS file
    ##--------------------------------------------------------------------------
    echo "STAGE 2 : make binary-corrected FITS file"

    ## set temporaly filenames 
    ext1evt=borbcorpy_ext1.evt # output of eborbcor.py
    ext2evt=borbcorpy_ext2.evt # output of eborbcor.py

    echo "  STAGE 2-1 : make temporal FITS file"
    case ${fozflg} in
	"s") #echo "SUPER-CONJUNCTION" #DEBUG
	    ${eborbcorpy} --mode=corr --tab=${ftable} --evtfits=${finput} --PORB=${fporb} --ECC=${fecc} --ASIN=${fasini} --OMG=${fomg} --SPCONJ=${fspconj} --imgout >/dev/null 2>&1
	    ;;
	"p") #echo "PERIASTRON" #DEBUG
	    ${eborbcorpy} --mode=corr --tab=${ftable} --evtfits=${finput} --PORB=${fporb} --ECC=${fecc} --ASIN=${fasini} --OMG=${fomg} --PERAST=${fperast} --imgout >/dev/null 2>&1
	    ;;
    esac


    echo "  STAGE 2-2 : make FITS file"
    ${fcopy} ${finput} ${foutput}

    for ext in 2 1;do
	${fdelhdu} ${foutput}+${ext} NO YES
    done
    
    ${fappend} ${ext1evt}+1 ${foutput} "pkeywds=yes"
    ${fappend} ${ext2evt}+1 ${foutput} "pkeywds=yes"
    rm ${ext1evt} ${ext2evt}

    
    echo "  STAGE 2-3 : modify header key of FITS file"
    tsta_obs=`${fkeyprint} ${finput}+0 TSTART|sed -n 's/TSTART  =//p'|awk '{print $1}'`
    tstp_obs=`${fkeyprint} ${finput}+0 TSTOP|sed -n 's/TSTOP   =//p'|awk '{print $1}'`
    tsta_cor=`${fkeyprint} ${foutput}+1 TSTART|sed -n 's/TSTART  =//p'|awk '{print $1}'`
    tstp_cor=`${fkeyprint} ${foutput}+1 TSTOP|sed -n 's/TSTOP   =//p'|awk '{print $1}'`
    tsta_del=`${fkeyprint} ${foutput}+1 TSTABOCA|sed -n 's/TSTABOCA=//p'|awk '{print $1}'`
    tstp_del=`${fkeyprint} ${foutput}+1 TSTPBOCA|sed -n 's/TSTPBOCA=//p'|awk '{print $1}'`

    #echo "tstart_obs   ${tsta_obs}" ##debug
    #echo "tstart_cor   ${tsta_cor}" ##debug


    ## modify parameters of TSTRAT and TSTOP in Header of FITS
    ${fparkey} ${tsta_cor} ${foutput}+0 TSTART "comm=time start" "add=no" >/dev/null 2>&1
    ${fparkey} ${tstp_cor} ${foutput}+0 TSTOP  "comm=time stop"  "add=no" >/dev/null 2>&1


    #---------------------------------------------------------------------------
    #messagenger part2
    #---------------------------------------------------------------------------
    cat <<EOF
  Modified paramters in Header of FITS File as follows:
  TSTART  : ${tsta_obs} -> ${tsta_cor} (amount of correction: ${tsta_del})
  TSTOP   : ${tstp_obs} -> ${tstp_cor} (amount of correction: ${tstp_del})
STAGE 2 finished

Output EVENTS FITS File : ${foutput}
`basename $0` has done without any errors.
EOF
}


cleanfoolspar(){
    for cmd in fdump fcreate fappend fkeyprint fparkey flcol fcopy faddcol fdelcol fdelhdu ;do
	${punlearn} ${cmd}
    done
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
        "INPUT"|"input") input=${val} ;;
        "OUTPUT"|"output") output=${val} ;;
        "ASINI"|"asini") asini=${val} ;;
        "PERAST"|"perast") perast=${val};FLG_OZ='p';spconj="" ;;
	"SPCONJ"|"spconj") spconj=${val};FLG_OZ='s';perast="" ;;
	"PORB"|"porb") porb=${val} ;;
	"ECC"|"ecc") ecc=${val} ;;
	"OMG"|"omg") omg=${val} ;;
	"TABLE"|"table") table=${val} ;;
        "CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) usage;;
    esac
done #for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6} ${var7} ${var8} ${var9};do

#echo "INPUT   ${input}"   #DEBUG
#echo "OUTPUT  ${output}"   #DEBUG
#echo "PORB    ${porb}"     #DEBUG
#echo "ASINI   ${asini}"    #DEBUG
#echo "PERAST  ${perast}"   #DEBUG
#echo "SPCONJ  ${perast}"   #DEBUG
#echo "ECC     ${ecc}"      #DEBUG
#echo "OMG     ${omg}"      #DEBUG
#echo "TABLE   ${phittab}"  #DEBUG
#echo "Overwrite ${FLG_OW}" #DEBUG


################################################################################
## Main
################################################################################
if [ $# -eq 0 ] ;then
    title
    usage
else
    if [ ! -e ${input} ]||[ _ = _${input} ];then
        echo "`basename $0` couldn't find \"${lcfits}\"."
        INPUT_FLG=FALSE
    fi

    if [ _ = _${asini} ];then
        echo "Please enter <ASINI> !!"
        INPUT_FLG=FALSE
    fi    
    
    if [[ _ = _${perast} ]]&&[[ _ = _${spconj} ]];then
        echo "Please enter <PERAST> or <SPCONJ> !!"
        INPUT_FLG=FALSE
    fi

    if [ _ = _${porb} ];then
        echo "Please enter <PORB> !!"
        INPUT_FLG=FALSE
    fi

    if [ _ = _${ecc} ];then
        echo "Please enter <ECC> !!"
        INPUT_FLG=FALSE
    fi

    if [ _ = _${omg} ];then
        echo "Please enter <OMG> !!"
        INPUT_FLG=FALSE
    fi

    if [ "${INPUT_FLG}" = "FALSE" ];then
        exit 1
    fi

    if [ _ = _${output} ];then
        output=${input%.evt*}_aebinaryorbcor.evt
    fi

    if [ _ = _${table} ];then
        table=aebinaryorbcor_table.csv
    fi

    if [[ ! -e ${output} ]] ;then
	corevtfits ${input} ${output} \
	    ${asini} ${ecc} ${omg} ${porb} ${table} ${perast} ${spconj} ${FLG_OZ} 
    else
	if [ "${FLG_OW}" = "YES" ]||[ "${FLG_OW}" = "yes" ] ;then
            rm ${output} 
	    corevtfits ${input} ${output} \
		${asini} ${ecc} ${omg} ${porb} ${table} ${perast} ${spconj} ${FLG_OZ} 
	else
	    echo ""
	    echo "${output} already exists !!" # 1>&2
	    echo -n "Overwrite ?? (y/n) >> "
	    read answer
	    case ${answer} in
		y|Y|yes|Yes|YES)
		    rm ${output} 
		    corevtfits ${input} ${output} \
			${asini} ${ecc} ${omg} ${porb} ${table} ${perast} ${spconj} ${FLG_OZ} 
		    ;;
		
		n|N|no|No|NO)
		    echo "`basename $0` has not been executed."
		    exit 1
		    ;;
		
		*)
		    echo "`basename $0` has not been executed."
		    exit 1
                    ;;
            esac
	fi
    fi
    cleanfoolspar
fi


#EOF#
