#!/bin/sh

############################################
#            QDP to Postscript             #
############################################
# qdpfileをpsfileへ変換. 

################################################################################
## Update
################################################################################
# Ver.  | Date       | Author   | 内容
#-------------------------------------------------------------------------------
# 1.1.1 | 2012.12.14 | yyoshida | output file 指定のoption追加 
#


################################################################################
## Set Command & Value
################################################################################
qdp=$HEADAS/bin/qdp
cat=/bin/cat


pstype="cps"
rotopt="-R +"
labelt=" "


################################################################################
## Function
################################################################################

## Usage

usage(){
cat <<EOF 
============================================================
                   QDP to Postscript
============================================================

Usage : `basename $0` [OPTION] <QDPFILENAME> [-o OUTPUT]

  [OPTION]
   -u)  Show Usage
   -a)  Convert all QDP FILE to Postscript FILE
   -e)  Convert QDP FILE to EPS FILE
   -r)  Convert QDP FILE to Postscript FILE for Report
   -v)  Convert QDP FILE to Vertical Postscript FILE
   -o)  Assign Output FILE

EOF
exit 1
}

#usage :mkps ${qdpfile} ${labelf}
mkps(){
PGPLOT_TYPE=/null
${qdp} $1 << EOF 1>/dev/null 
TIME OFF
LAB F $1
${labelf}
hard ${1%.qdp}.ps/${pstype}
q
EOF
PGPLOT_TYPE=/xw
}

#usage :mkeps ${qdpfile} ${labelf}
mkeps(){
PGPLOT_TYPE=/null
${qdp} $1 << EOF 1>/dev/null
TIME OFF
LAB F $1
${labelf}
hard ${1%.qdp}.ps/${pstype}
q
EOF
ps2eps --ignoreBB ${rotopt} -f -l ${1%.qdp}.ps 1>/dev/null&& rm -f ${1%.qdp}.ps 
PGPLOT_TYPE=/xw
}


################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o uaervo: -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ##DEBUG

while true ;do
  case $1 in
      -u) usage 
	  ;;
      -a) FLG_A="TRUE" 
	  shift 
	  ;;
      -e) FLG_E="TRUE"
	  shift
	  ;;
      -r) labelf="LAB F"
	  shift 
	  ;;
      -v) pstype="vcps"
	  rotopt=""
	  shift
	  ;;
      -o) FLG_O="TRUE"
	  output=$2
	  shift 2
	  ;;
      --) shift ; break 
	  ;;
       *) usage 
	  ;;
  esac
done

##echo $@ ##DEBUG

################################################################################
## Main
################################################################################
if [ "${FLG_O}" = "TRUE" ] && [ _${output} = _ ];then
    usage
fi

if [ "${FLG_A}" = "TRUE" ];then
    if [ "${FLG_O}" = "TRUE" ];then
	usage
    elif [ "${FLG_E}" = "TRUE" ];then
	for qdpfile in *.qdp ;do
	    mkeps ${qdpfile}
	done
    else
	for qdpfile in *.qdp ;do
	    mkps ${qdpfile}
	done
    fi
else
    qdpfile=$1
    if [ _${qdpfile} = _ ] ;then
	echo "Please enter QDP FILE !!" 1>&2
	exit 1
    elif [ ! -e ${qdpfile} ] ;then
	echo "${qdpfile} is not found !!" 1>&2
	exit 1
    else
	if [ "${FLG_E}" = "TRUE" ];then
	    mkeps ${qdpfile}
	    if [ "${FLG_O}" = "TRUE" ];then
		mv -f ${qdpfile%.qdp}.eps ${output}
	    fi
	else 
	    mkps ${qdpfile}
	    if [ "${FLG_O}" = "TRUE" ];then
		mv -f ${qdpfile%.qdp}.ps ${output}
	    fi
	fi
    fi
fi


#EOF#
