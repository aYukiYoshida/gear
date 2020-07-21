#!/bin/bash

################################################################################
## Update
################################################################################
# Ver.   | Date       | Author   | 内容
#-------------------------------------------------------------------------------
# 1.0.0  | 2016.05.15 | yyoshida | プロトタイプ
# 1.0.1  | 2016.05.22 | yyoshida | added object
# 1.0.2  | 2016.05.22 | yyoshida | added object
# 1.0.3  | 2016.07.30 | yyoshida | added object
# 1.0.4  | 2016.08.01 | yyoshida | added object
# 1.1.0  | 2016.08.12 | yyoshida | added edtion option
#


###########################################################################
## Command
###########################################################################
emacs='/Applications/MacPorts/Emacs24.app/Contents/MacOS/Emacs -bg black -fg white'


###########################################################################
## Value
###########################################################################
analysis_dir='/Users/yyoshida/Dropbox/Analysis'
tmp_dir='/Users/yyoshida/Dropbox/Analysis/Pulsar/report/tmp'
styfile=${tmp_dir}/pagestyle.tex
tmpfile=${tmp_dir}/.tmp.tex
author='Y.Yoshida'
version='1.1.0'


###########################################################################
## Function
###########################################################################
help(){
    cat <<EOF
USAGE
   `basename $0` [OPTION] <OBJECT> <IDNUM> 

OBJECT
   al  :  for All
   az  :  for A0535+262
   cn  :  for CenX-3
   cp  :  for CepX-4
   ex  :  for EXO2030+375
   fe  :  for 4U1954+31
   ff  :  for 4U1538-522
   fs  :  for 4U1822-37
   ft  :  for 4U2206+54
   fu  :  for 4U1626-67    
   fz  :  for 4U0114+65
   gx  :  for GX1+4
   go  :  for GX301-2
   gf  :  for GX304-1
   he  :  for HerX-1
   ig  :  for IGRJ16393-4643
   jo  :  for GROJ1008-57
   lf  :  for LMCX-4
   oa  :  for 1A1118-61
   os  :  for OAO1657-415
   so  :  for SMCX-1
   vl  :  for VelaX-1
   xp  :  for XPer
   zn  :  for 4U1909+07
   zs  :  for 4U1907+097
      
OPTION
   -h)  Show this help script
   -e)  issue for edition

Ver${version} written by ${author}
EOF
    exit 1
}


issue(){
    #ln -sf ${styfile} $1
    cat <<EOF > $2
\documentclass[10pt,a4paper]{ujarticle}
\input{${styfile}}

%-----------Change following parameters for the standard header:
\setinfo
%%object
{\\$3}
%%author
{Yuki Yoshida}
%%date
{\fulltoday}
%%document id
{APXP-$4-$5-v1.0}
EOF
    cat ${tmpfile} >> $2
}

edition(){
    in_obj=$1
    in_num=$2
    in_dir=$3
    in_src=$4
    [ -d ${in_dir}/edition ]||mkdir ${in_dir}/edition
    for v in `seq -f '%5.1f' 1.0 0.1 100.0` ;do
	outfile=${in_dir}/edition/${in_obj}-${in_num}-v${v}.pdf
	if [ ! -e ${outfile} ];then
	    ver=${v}
	    break 1
	fi
    done
    cp ${in_src} ${outfile}
    echo "issued ${in_obj}-${in_num}-v${ver}.pdf"    
}

###########################################################################
## OPTION
###########################################################################
#GETOPT=`getopt -q -o h  -- "$@"` ; [ $? != 0 ] && help
GETOPT=`getopt he "$@"` ; [ $? != 0 ] && help
eval set -- "$GETOPT"

while true ;do
    case $1 in
        -h) help
            ;;
	-e) FLG_e="TRUE"
	    shift ;;
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
num=$2

if [ "x${obj}" = "x" ]||[ "x${num}" = "x" ];then
    #echo "chk" ##DEBUG
    help 
else
    case ${obj} in
	al) objdir=Pulsar
	    name=AL ;;
        az) objdir=A0535+262
	    name=AZ ;;
        cn) objdir=CenX-3
	    name=CN ;;
        cp) objdir=CepX-4
	    name=CP ;;
	ex) objdir=EXO2030+375
	    name=EX ;;
        fe) objdir=4U1954+31
	    name=FE ;;
	ff) objdir=4U1538-522
	    name=FF ;;
	fs) objdir=4U1822-37
	    name=FS ;;
        ft) objdir=4U2206+54
	    name=FT ;;
        fu) objdir=4U1626-67
	    name=FU ;;
        fz) objdir=4U0114+65
	    name=FZ ;;
	gf) objdir=GX304-1
	    name=GF ;;
	go) objdir=GX301-2
	    name=GO ;;
        gx) objdir=GX1+4
	    name=GX ;;
	he) objdir=HerX-1
	    name=HE ;;
        ig) objdir=IGRJ16393-4643
	    name=IG ;;
	jo) objdir=GROJ1008-57
	    name=JO ;;
	lf) objdir=LMCX-4
	    name=LF ;;
	oa) objdir=1A1118-61
	    name=OA ;;
	os) objdir=OAO1657-415
	    name=OS ;;
	so) objdir=SMCX-1
	    name=SO ;;
	vl) objdir=VelaX-1
	    name=VL ;;
        xp) objdir=XPer
	    name=XP ;;
        zn) objdir=4U1909+07
	    name=ZN ;;
        zs) objdir=4U1907+097
	    name=ZS ;;
        *) help ;;
    esac

    out_dir=${analysis_dir}/${objdir}/report/APXP-${name}-${num}
    if [ "${FLG_e}" = "TRUE" ];then
	srcfile=${out_dir}/${obj}-${num}.pdf
	#echo "edition mode" ##DEBUG
	#echo "${srcfile}" ##DEBUG
	
	if [ ! -e ${srcfile} ];then
	    echo "`basename ${srcfile}` doesn't exist."
	else
	    edition ${obj} ${num} ${out_dir} ${srcfile}
	fi

    else
	outfile=${out_dir}/${obj}-${num}.tex

	if [ -e ${outfile} ];then
	    echo "Report ID:APXP-${name}-${num} already exist !!"
	    echo -n "Overwrite ?? (y/n) >> "
            read answer
            case ${answer} in
		y|Y|yes|Yes|YES)
		    issue ${out_dir} ${outfile} ${obj} ${name} ${num}
		    echo "`basename $0` edited Report ID:APXP-${name}-${num}."
                    ;;
		
		n|N|no|No|NO)
                    echo "`basename $0` has not been executed."
                    exit 1
                    ;;
		*)
                    echo "`basename $0` has not been executed."
                    exit 1
            esac
	    
	else
	    [ -d ${out_dir} ]||mkdir -p ${out_dir}/fig ${out_dir}/edition
	    issue ${out_dir} ${outfile} ${obj} ${name} ${num}
	    echo "`basename $0` edited Report ID:APXP-${name}-${num}."
	fi
    fi
fi


#EOF#
