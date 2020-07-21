#!/bin/bash

################################################################################
## Update
################################################################################
# Ver.  | Date       | Author   | 内容
#-------------------------------------------------------------------------------
# 1.0.0 | 2015.10.06 | yyoshida | プロトタイプ
# 1.0.1 | 2016.01.26 | yyoshida | add object
# 1.0.2 | 2016.03.28 | yyoshida | add object
# 1.0.3 | 2016.05.** | yyoshida | add object
# 1.0.4 | 2016.05.15 | yyoshida | add object
# 1.0.5 | 2016.05.18 | yyoshida | add object
# 1.0.6 | 2016.05.18 | yyoshida | add object
# 1.0.7 | 2016.07.30 | yyoshida | add object
# 1.0.8 | 2016.08.01 | yyoshida | add object
# 1.0.9 | 2016.10.16 | yyoshida | add object
# 1.1.0 | 2017.01.19 | yyoshida | add object
# 1.1.1 | 2017.09.25 | yyoshida | add object
# 1.1.2 | 2019.01.22 | yyoshida | date変数の定義を変更
# 1.1.3 | 2020.03.21 | yyoshida | add object
#


###########################################################################
## Command
###########################################################################
emacs='/usr/bin/emacs23'


###########################################################################
## Value
###########################################################################
analysis_dir='/home/yyoshida/Dropbox/astro'
date=$(env LC_TIME=en_US.UTF-8 date +"%Y/%m/%d(%a)")
filedate=$(date +"%Y%m%d")
author='Y.Yoshida'
version='1.1.2'


###########################################################################
## Function
###########################################################################
help(){
    cat <<EOF
USAGE
   `basename $0` <OBJECT>

OBJECT
   xp    :  for AllPulsar
   az    :  for A0535+262
   cn    :  for CenX-3
   cp    :  for CepX-4
   cb    :  for Crab
   cg    :  for CygX-3
   ex    :  for EXO2030+375
   fe    :  for 4U1954+31
   ff    :  for 4U1538-522
   flse  :  for FiniteLightSpeedEffect
   fs    :  for 4U1822-37
   ft    :  for 4U2206+54
   fu    :  for 4U1626-67    
   fz    :  for 4U0114+65
   gx    :  for GX1+4
   go    :  for GX301-2
   gf    :  for GX304-1
   he    :  for HerX-1
   ig    :  for IGRJ16393-4643
   jo    :  for GROJ1008-57
   lf    :  for LMCX-4
   oa    :  for 1A1118-61
   os    :  for OAO1657-415
   so    :  for SMCX-1
   vl    :  for VelaX-1
   zn    :  for 4U1909+07
   zs    :  for 4U1907+097

OPTION
   -h)  Show this help script

Ver${version} written by ${author}
EOF
    exit 1
}



###########################################################################
## OPTION
###########################################################################
GETOPT=`getopt -q -o h  -- "$@"` ; [ $? != 0 ] && help
eval set -- "$GETOPT"

while true ;do
    case $1 in
        -h) help
            ;;
        --) shift ; break 
            ;;
        *) usage 
            ;;
    esac
done



###########################################################################
## Checking source part & set objdir
###########################################################################
obj=$1

if [ "x${obj}" = "x" ];then
    #echo "chk" ##DEBUG
    help 
else
    case ${obj} in
        xp|al|pl) objdir=Pulsar ;;
        az) objdir=A0535+262 ;;
        cn) objdir=CenX-3 ;;
        cp) objdir=CepX-4 ;;
        cb) objdir=Crab ;;
        cg) objdir=CygX-3 ;;
        ex) objdir=EXO2030+375 ;;
        fe) objdir=4U1954+31 ;;
        ff) objdir=4U1538-522 ;;
        flse) objdir=FiniteLightSpeedEffect ;;
        fs) objdir=4U1822-37 ;;
        ft) objdir=4U2206+54 ;;
        fu) objdir=4U1626-67 ;;
        fz) objdir=4U0114+65 ;;
        jo) objdir=GROJ1008-57 ;;
        gx) objdir=GX1+4 ;;
        go) objdir=GX301-2 ;;
        gf) objdir=GX304-1 ;;
        he) objdir=HerX-1 ;;
        ig) objdir=IGRJ16393-4643 ;;
        lf) objdir=LMCX-4 ;;
        oa) objdir=1A1118-61;;
        os) objdir=OAO1657-415;;
        so) objdir=SMCX-1 ;;
        vl) objdir=VelaX-1;;
        #xp) objdir=XPer ;;
        zn) objdir=4U1909+07 ;;
        zs) objdir=4U1907+097 ;;
        *) help ;;
    esac
    out=${analysis_dir}/${objdir}/log/${filedate}.txt
    tmp=${analysis_dir}/${objdir}/log/.mktemplate.txt

    if [ -e ${out} ];then
	    ${emacs} ${out}&
    else
        echo "${date}" > ${out}
        cat ${tmp} >> ${out}
        echo "`basename $0` edited logfile of ${objdir} named ${filedate}."
    fi
fi



#EOF#
