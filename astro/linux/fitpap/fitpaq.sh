#!/bin/bash
                                                                                       
########################################################################
## Value
########################################################################
src="/home/yyoshida/Memo/fitpaper"

########################################################################
## Command 
########################################################################
sed="/bin/sed"
platex="/usr/bin/platex"
mv="/bin/mv -f"
view="/usr/bin/xdvi"
edit="/usr/bin/emacs23 --geometry=90x40 --font=9x15"
dn="/usr/bin/dirname"
bn="/usr/bin/basename"
dvips="/usr/bin/dvips"
dvipdf="/usr/bin/dvipdfmx"


########################################################################
## Function
########################################################################
usage(){
    cat <<EOF 
USAGE   : `basename $0` <-i TEXFILE> DELPARNUM...
EXAMPLE : `basename $0` -i fitting.tex 2 3 4 5 
EOF
    exit 1
}

   
fullpath(){
    exedir=`pwd`
    cd $1
    fullpath_return=`pwd`
    cd ${exedir}
}


################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o hi: -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ##DEBUG

while true ;do
  case $1 in
      -h) usage 
          ;;
      -i) FLG_i=TRUE
	  tex=$2
	  texdir=`${dn} $2`
	  shift 2
	  ;;
      --) shift ; break 
          ;;
       *) usage 
          ;;
  esac
done
  
#echo $@ ##DEBUG
################################################################################
## MAIN
################################################################################
if [ "${FLG_i}" != "TRUE" ]||[ _${tex} = _ ];then
    usage
fi


for p in $@ ;do
    if [ ${p} -le 9 ];then
	${sed} "/#   ${p} /d" ${tex} > tmp.tex
	${mv} tmp.tex ${tex}
	#echo "${p} FALSE" ##DEBUG

    elif [ ${p} -gt 9 -a ${p} -le 99 ];then
	${sed} "/#  ${p} /d" ${tex} > tmp.tex
	${mv} tmp.tex ${tex}
	#echo "${p} TRUE" ##DEBUG

    else
	${sed} "/# ${p} /d" ${tex} > tmp.tex
	${mv} tmp.tex ${tex}
	#echo "${p} FALSE" ##DEBUG
    fi
done

cd ${texdir}
${platex} `basename ${tex}`
${dvips} `basename ${tex%.tex}.dvi`
${dvipdf} `basename ${tex%.tex}.dvi`



#EOF#
