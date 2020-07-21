#!/bin/bash

################################################################################
## Redaction history
################################################################################
# Ver.  | Date       | Author   | 内容
#-------------------------------------------------------------------------------
# 1.0.0 | 2013.XX.XX | yyoshida | prototype
# 1.0.1 | 2014.08.15 | yyoshida | 4U1626_67用"f"他option追加
# 1.0.2 | 2014.08.16 | yyoshida | list option削除
# 1.0.3 | 2015.04.03 | yyoshida | directoryのpassを変数化
# 1.0.4 | 2015.05.12 | yyoshida | A0525_262用"z"他option追加
# 1.1.1 | 2015.06.07 | yyoshida | option routinへ変更&-m option追加
# 1.1.2 | 2015.06.24 | yyoshida | option 以外の入力時標準エラー出力
# 1.2.0 | 2016.01.06 | yyoshida | optionとobjectを分離
# 1.2.1 | 2016.05.04 | yyoshida | objectを追加
# 1.2.2 | 2016.05.18 | yyoshida | objectを追加
# 1.2.3 | 2016.05.18 | yyoshida | objectを追加
# 1.2.4 | 2016.10.30 | yyoshida | objectを追加
# 1.2.5 | 2017.07.06 | yyoshida | objectを追加
# 1.2.6 | 2017.09.25 | yyoshida | objectを追加
# 


################################################################################
## Setup
################################################################################
author="Y.Yoshida"
version="1.2.5"
term="/home/yyoshida/local/bin/kt"
rm="/bin/rm -f"
DATA="/home/yyoshida/Data"
Suzaku="${DATA}/Suzaku"
LINK="${DATA}/Link"
Tools="/home/yyoshida/local/bin"

GX14="${Suzaku}/GX_14"
A0535262="${Suzaku}/A0535_262"
CENX3="${Suzaku}/CenX-3/403046010"
CEPX4="${Suzaku}/CepX-4"
HERX1="${Suzaku}/HerX-1"
EXO2030375="${Suzaku}/EXO2030+375"
FU195431="${Suzaku}/4U1954+31/907005010"
FU1538522="${Suzaku}/4U1538-522/407068010"
FU220654="${Suzaku}/4U2206+54/402069010"
FU011465="${Suzaku}/4U0114+65/406017010"
FU162667="${Suzaku}/4U1626-67"
FU182237="${Suzaku}/4U1822-37"
FU170037="${Suzaku}/4U1700-37/401058010"
OA111861="${Suzaku}/1A1118-61"
GX3012="${Suzaku}/GX301-2"
GX3041="${Suzaku}/GX304-1"
IG16393="${Suzaku}/IGRJ16393-4643/404056010"
VELAX1="${Suzaku}/VelaX-1/403045010"
XPER="${Suzaku}/XPer/407088010"
FU1907097="${Suzaku}/4U1907+097"
FU190907="${Suzaku}/4U1909+07/405073010"
GROJ100857="${Suzaku}/GROJ1008-57"
OAO1657415="${Suzaku}/OAO1657-415/406011010"
LMCX4="${Suzaku}/LMCX-4"
SMCX1="${Suzaku}/SMCX-1"
FLSE="/home/yyoshida/Works/Analysis/pulsar/simflse"

################################################################################
## Function
################################################################################
##Archive
##   ac) ArchesCluster
##   pc) PerseusCluster
##   x3) CygnusX-3

usage(){
cat <<EOF 

USAGE:
  `basename $0` <OPTION> <OBJECT>

OBJECT:
   az) A0535+262
   bn) Tools
   cn) CentaurusX-3
   cp) CepX-4
   ex) EXO2030+375
   fe) 4U1954+31
   ff) 4U1538-522
   fs) 4U1822-37
   ft) 4U2206+54
   fu) 4U1626-67
   fz) 4U0114+65
   gx) GX1+4
   go) GX301-2
   gf) GX304-1
   he) HerculesX-1
   ig) IGRJ16393-4643
   jo) GROJ1008-57
   lf) LMCX-4
   oa) 1A1118-61
   os) OAO1657-415
   so) SMCX-1
   vl) VelaX-1
   xp) XPer
   zn) 4U1909+07
   zs) 4U1907+097
   flse) Finite Light Speed Effect

OPTION:
   -h)  Show Usage
   -l)  Long Window mode
   -m)  Multi Window mode
   -u)  Show Usage

Ver${version} Written by ${author}
EOF
exit 1
}


gmen(){
    directory=$1
    option=$2
    
    cd ${directory}
    ${term} ${option}
}



################################################################################
## OPTION
################################################################################
if [ $# -eq 0 ];then
    usage
else
    #echo "$@" ##DEBUG
    GETOPT=`getopt -q -o hulms -- "$@"` ; [ $? != 0 ] && usage
    eval set -- "$GETOPT"
    
    while true ;do
	case $1 in
	    -h|-u) usage 
		;;
	    -l) FLG_L="TRUE"
		shift
		;;
	    -m) FLG_M="TRUE"
		shift
		;;
	    -s) FLG_S="TRUE"
		shift
		;;
	    --) shift ; break 
		;;
	    *) usage 
		;;
	esac
    done
#echo ${dir} #DEBUG
fi


################################################################################
## Object
################################################################################
#echo "end option \"$@\"" #DEBUG
#echo "end option \"$#\"" #DEBUG

if [ $# -eq 0 ]||[ $# -ge 2 ];then
    #echo "no object or too many" ##DEBUG
    usage
else
    #echo "$@"  ##DEBUG
    obj="$@"
    case ${obj} in
	ac) dir="${ArchesCLUSTER}" ;;
	az) dir="${A0535262}" ;;
	bn) FLG_B="TRUE"
	    dir="${Tools}" ;;
	cn) dir="${CENX3}" ;;
	ex) dir="${EXO2030375}" ;;
	cp) dir="${CEPX4}" ;;
	fe) dir="${FU195431}" ;;
	ff) dir="${FU1538522}" ;;
	fs) dir="${FU182237}" ;;
	ft) dir="${FU220654}" ;;
	fu) dir="${FU162667}" ;;
	fz) dir="${FU011465}" ;;
	jo) dir="${GROJ100857}" ;;
	gx) dir="${GX14}" ;;
	go) dir="${GX3012}" ;;
	gf) dir="${GX3041}" ;;
	he) dir="${HERX1}" ;;
	ig) dir="${IG16393}" ;;
	oa) dir="${OA111861}" ;;
	lf) dir="${LMCX4}" ;;
	so) dir="${SMCX1}" ;;
	os) dir="${OAO1657415}" ;;
	pc) dir="${PERSEUSCLUSTER}" ;;
	vl) dir="${VELAX1}" ;;
	xp) dir="${XPER}" ;;
	x3) dir="${CygnusX3}" ;;
	zn) dir="${FU190907}" ;;
	zs) dir="${FU1907097}" ;;
	flse) dir="${FLSE}" ;;
	*)  #echo "no match" ## DEBUG
	    usage ;;
    esac
    
    if [ "${FLG_M}" != "TRUE" ] ;then
	if [ "${FLG_B}" = "TRUE" ] ;then
	    gmen ${dir} -b
	else
	    if [ "${FLG_L}" = "TRUE" ] ;then
		gmen ${dir} -l
	    elif [ "${FLG_S}" = "TRUE" ] ;then
		gmen ${dir} -s
	    else
		gmen ${dir} -m
	    fi
	fi
	
    else
	if [ "${FLG_L}" = "TRUE" ] ;then
	    gmen ${dir} -l
	    gmen ${dir} -l
	elif [ "${FLG_S}" = "TRUE" ] ;then
	    gmen ${dir} -s
	    gmen ${dir} -s
	else
	    gmen ${dir} -m
	    gmen ${dir} -m
	fi
    fi
fi


#EOF#
