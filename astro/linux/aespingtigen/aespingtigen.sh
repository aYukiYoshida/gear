#!/bin/bash

# GTI file format
# START(in suzaku time) STOP(in suzaku time)

################################################################################
## Setup
################################################################################
AUTHOR="Y.Yoshida"
SCRIPTFILE=$0
[ -L ${SCRIPTFILE} ] && SCRIPTFILE=$(readlink ${SCRIPTFILE})
SCRIPTNAME=$(basename ${SCRIPTFILE%.*})
sys=$(dirname ${SCRIPTFILE})
keyprint=`which fkeyprint`
calc_std=${sys}/aespingtigen.awk
calc_ext=$${sys}/aextspingtigen.awk

# initialize
lcfits=
epoch=
period=
iph=
tph=
iph2=
tph2=
output=
FLG_OW=


################################################################################
## Function
################################################################################
title(){
    echo "${SCRIPTNAME} written by ${AUTHOR}"
    echo ""
}

usage(){
    echo "USAGE : ${SCRIPTNAME} [OPTION] <LCFITS> <EPOCH> <PERIOD> <IPHASE> <TPHASE> <OUTPUT>"
    exit 0
}

usagehelp(){
    cat << EOF
${SCRIPTNAME} written by ${AUTHOR}

USAGE:
   ${SCRIPTNAME} [OPTION] <LCFITS> <EPOCH> <PERIOD> <IPHASE> <TPHASE> <OUTPUT>


PARAMETERS:

   <LCFITS>
      Name of the input lightcurve FITS file to get some values.
      The OBS-MJD TSTART, and TSTOP keywords are obtained from this file.

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

   <OUTPUT>
      Name of output GTI file.


OPTION:

   -u) Show usage


EXAMPLE: 

   For standard rotation phase
      % `basename $0` LCFITS=xis0.pi EPOCH=54051.93313 PERIOD=17279.219 \\
        IPHASE=0.3 TPHASE=0.5 OUTPUT=xis0_03_05.gti

   For non-conguous phase
      % `basename $0` LCFITS=xis0.pi EPOCH=54051.93313 PERIOD=17279.219 \\
        IPHASE=0.3 TPHASE=0.5 IPHASE_EXT=0.7 TPHASE_EXT=0.9 \\
        OUTPUT=xis0_03_05__07_09.gti

EOF
    exit 0
}

getparam(){
    in_lcfits=$1
    echo "getparam ${in_lcfits}"
    
}

## MAKE GTI FILE
mkgtifile(){
    in_lcfits=$1
    in_output=$2
    in_iph=$3
    in_tph=$4
    in_epoch=$5
    in_period=$6

    tstart=`${keyprint} ${in_lcfits}+1 TSTART|sed -n 's/TSTART  = //p'|awk '{print $1}'`
    tstop=`${keyprint} ${in_lcfits}+1 TSTOP|sed -n 's/TSTOP   = //p'|awk '{print $1}'`
    mjdrefi=`${keyprint} ${in_lcfits}+1 MJDREFI|sed -n 's/MJDREFI = //p'|awk '{print $1}'`
    mjdreff=`${keyprint} ${in_lcfits}+1 MJDREFF|sed -n 's/MJDREFF = //p'|awk '{print $1}'`
    mjdref=`echo "${mjdrefi} ${mjdreff}"|awk '{printf "%17.15e\n",$1+$2}'`
    mjdstart=`echo "${mjdref} ${tstart}"|awk '{printf "%17.15e\n",$1+$2/60/60/24}'`
    mjdstop=`echo "${mjdref} ${tstop}"|awk '{printf "%17.15e\n",$1+$2/60/60/24}'`

    ${calc_std} -v iph=${in_iph} -v tph=${in_tph} -v mjdref=${mjdref} -v mjdstart=${mjdstart} -v mjdstop=${mjdstop} -v tstart=${tstart} -v tstop=${tstop} -v epoch=${in_epoch} -v period=${in_period} > ${output}

    
    echo "Input lightcurve FITS File    : ${in_lcfits}"
    echo ""
    echo "Setted paramters as follow:"
    echo "TSTART           :  ${tstart}"
    echo "TSTOP            :  ${tstop}"
    echo "MJD-START        :  ${mjdstart}"
    echo "EPOCH            :  ${in_epoch}"
    echo "PERIOD           :  ${in_period}"
    echo "INTERVAL PHASE   :  ${in_iph} - ${in_tph}"
    echo ""
    echo "Output GTI File  :  ${in_output}"
    echo "${SCRIPTNAME} finished."

}

## MAKE GTI FILE (Non-contiguous phase) 	
mkgtiextfile(){
    in_lcfits=$1
    in_output=$2
    in_iph=$3
    in_tph=$4
    in_iph2=$5
    in_tph2=$6
    in_epoch=$7
    in_period=$8

    tstart=`${keyprint} ${in_lcfits}+1 TSTART|sed -n 's/TSTART  = //p'|awk '{print $1}'`
    tstop=`${keyprint} ${in_lcfits}+1 TSTOP|sed -n 's/TSTOP   = //p'|awk '{print $1}'`
    mjdrefi=`${keyprint} ${in_lcfits}+1 MJDREFI|sed -n 's/MJDREFI = //p'|awk '{print $1}'`
    mjdreff=`${keyprint} ${in_lcfits}+1 MJDREFF|sed -n 's/MJDREFF = //p'|awk '{print $1}'`
    mjdref=`echo "${mjdrefi} ${mjdreff}"|awk '{printf "%17.15e\n",$1+$2}'`
    mjdstart=`echo "${mjdref} ${tstart}"|awk '{printf "%17.15e\n",$1+$2/60/60/24}'`
    mjdstop=`echo "${mjdref} ${tstop}"|awk '{printf "%17.15e\n",$1+$2/60/60/24}'`

    ${calc_ext} -v iph_a=${in_iph} -v tph_a=${in_tph} -v iph_b=${in_iph2} -v tph_b=${in_tph2}  -v mjdref=${mjdref} -v mjdstart=${mjdstart} -v mjdstop=${mjdstop} -v tstart=${tstart} -v tstop=${tstop} -v epoch=${in_epoch} -v period=${in_period} > ${output}

Input lightcurve FITS File    : ${in_lcfits}

    echo "Setted paramters as follow:"
    echo "TSTART            :  ${tstart}"
    echo "TSTOP             :  ${tstop}"
    echo "EPOCH             :  ${in_epoch}"
    echo "PERIOD            :  ${in_period}"
    echo "INTERVAL PHASE    :  ${in_iph} - ${in_tph}"
    echo "EXTRA INTERVAL    :  ${in_iph2} - ${in_tph2}"
    echo ""
    echo "Output GTI File   :  ${in_output}"
    echo "${SCRIPTNAME} finished."

}


################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o uh -- "$@"` ; [ $? != 0 ] && usagehelp
eval set -- "$GETOPT"
while true ;do
  case $1 in
      -u|-h) usagehelp
          ;;
      --) shift ; break 
          ;;
       *) title;usage 
          ;;
  esac
done


title
################################################################################
## MAIN
################################################################################
if [ $# -lt 6 ];then
    usage
else
    var1=$1 #;echo ${var1}
    var2=$2 #;echo ${var2}
    var3=$3 #;echo ${var3}
    var4=$4 #;echo ${var4}
    var5=$5 #;echo ${var5}
    var6=$6 #;echo ${var6}
    var7=$7 #;echo ${var7}
    var8=$8 #;echo ${var8}
fi

for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6} ${var7} ${var8} ${var9};do
    IFS='='
    set -- ${var}
    par=$1
    val=$2
   # echo "${par}" #DEBUG
   # echo "${val}" #DEBUG
    case ${par} in
        "LCFITS"|"lcfits") lcfits=${val} ;;
        "EPOCH"|"epoch") epoch=${val} ;;
        "PERIOD"|"period") period=${val} ;;
        "IPHASE"|"iphase") iph=${val} ;;
        "TPHASE"|"tphase") tph=${val} ;;
        "IPHASE_EXT"|"iphase_ext") iph2=${val} ;;
        "TPHASE_EXT"|"tphase_ext") tph2=${val} ;;
        "OUTPUT"|"output") output=${val} ;;
        "CLOBBER"|"clobber") FLG_OW=${val} ;;
        *) title;usage;;
    esac
done #for var in ${var1} ${var2} ${var3} ${var4} ${var5} ${var6} ${var7} ${var8};do

if [ _${lcfits} = _ ]||[ ! -e ${lcfits} ] ;then
    echo "`basename $0` couldn't open <LCFITS>."
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
    echo "Extra mode ON !!"
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
            mkgtifile ${lcfits} ${output} ${iph} ${tph} ${epoch} ${period}
        else     ## MAKE GTI FILE (Non-contiguous phase) 	
            mkgtiextfile ${lcfits} ${output} ${iph} ${tph} ${iph2} ${tph2} ${epoch} ${period}
        fi
    else
        if [ "${FLG_OW}" = "YES" ]||[ "${FLG_OW}" = "yes" ] ;then
            if [ "${FLG_EXT}" != "TRUE" ];then ## MAKE GTI FILE
                mkgtifile ${lcfits} ${output} ${iph} ${tph} ${epoch} ${period}
            else ## MAKE GTI FILE (Non-contiguous phase) 	
                rm ${output}
                mkgtiextfile ${lcfits} ${output} ${iph} ${tph} ${iph2} ${tph2} ${epoch} ${period}
            fi
        else
            echo "${output} already exists !!" # 1>&2
            echo -n "Overwrite ?? (y/n) >> "
            read answer
            case ${answer} in
                y|Y|yes|Yes|YES)
                    if [ "${FLG_EXT}" != "TRUE" ];then ## MAKE GTI FILE
                        rm ${output}
                        mkgtifile ${lcfits} ${output} ${iph} ${tph} ${epoch} ${period}
                    else     ## MAKE GTI FILE (Non-contiguous phase) 	
                        rm ${output}
                        mkgtiextfile ${lcfits} ${output} ${iph} ${tph} ${iph2} ${tph2} ${epoch} ${period}
                    fi
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
