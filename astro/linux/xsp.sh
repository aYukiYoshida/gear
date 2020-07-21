#!/bin/zsh

################################################################################
## Set Value
################################################################################
fullpath=`pwd`


################################################################################
## Set Command
################################################################################
xspec_org=`which xspec`	


################################################################################
## Set Function
################################################################################
clean(){
rm -f ${fullpath}/xw.xcm
rm -f ${fullpath}/nw.xcm
rm -f ${fullpath}/rescal.xcm 
rm -f ${fullpath}/ufloc.xcm 
rm -f ${fullpath}/lddeloc.xcm 
rm -f ${fullpath}/fit.xcm
rm -f ${fullpath}/rfit.xcm
rm -f ${fullpath}/lmod.xcm
}


usage(){
    cat <<EOF 
USAGE:
   `basename $0` [OPTION]

OPTION:
   -h)  Show Usage
   -g)  Make Script Files
   -r)  Remove Script Files

EOF
exit 1
}


mkscript(){
cat <<EOF >! xw.xcm
cpd /xw
plot
EOF

cat <<EOF >! nw.xcm
cpd /null
plot
EOF

#cat <<EOF >! rescal.xcm
#setplot command win 1
#setplot command R Y 1E-4 10
#setplot command win 2
#setplot command R Y NO NO
#plot
#EOF

cat <<EOF >! ufloc.xcm
setplot command WIN 1
setplot command LOC  5.00000007E-2 0 1 1
setplot command LAB  NX ON
plot
EOF

cat <<EOF >! lddeloc.xcm
setplot command WIN 1
setplot command LOC 0 0 1 1
setplot command Vie 0.100000001 0.400000006 0.899999976 0.899999976
setplot command LAB  NX OFF
setplot command LAB  F
setplot command WIN 2
setplot command LOC 0 0 1 1
setplot command Vie 0.100000001 0.100000001 0.899999976 0.400000006
setplot command WIN ALL
plot
EOF

cat <<EOF >! fit.xcm
renorm
plot ldata delchi
setplot command WIN 2
setplot command LAB Y (data-model)/error
setplot command WIN ALL
fit
show all
plot ldata delchi
EOF

cat <<EOF >! rfit.xcm
renorm
plot ldata residuals
setplot command WIN 2
setplot command LAB Y residuals
setplot command WIN ALL
fit
show all
plot ldata residuals
EOF


#cat <<EOF >! lmod.xcm
#lmod multipl $LMODDIR/multipl
#lmod absorption $LMODDIR/absorption
#EOF
}



################################################################################
## OPTION
################################################################################
GETOPT=`getopt -q -o ghr -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ##DEBUG

while true ;do
  case $1 in
      -h) usage
          ;;
      -g) mkscript
	  exit 1
	  ;;
      -r) clean
	  exit 1
          ;;
      --) shift ; break 
          ;;
       *) usage 
          ;;
  esac
done
   
mkscript
${xspec_org} && clean



