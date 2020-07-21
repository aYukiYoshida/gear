#!/bin/bash -f

##############################################
##
## HEAsoft V6.20 with MXFTOOLS
##
##############################################

xray='/usr/local/xray'

#if [ "x$HEADAS" != x ]; then
#    if [ "x$USER" != x && "x$prompt" != x ]; then
#	echo "HEAsoft already configured for $HEADAS"
#    fi
#    exit 1
#fi

version=6.20
top=${xray}/heasoft/${version}

arch=`/bin/ls ${top}|grep ${sys}`


export HEADAS=${xray}/heasoft/${version}/${arch}
export LMODDIR=${xray}/heasoft/local/model

source $HEADAS/headas-init.sh && echo "HEAsoft was configured for $HEADAS"

## Set-up MAXI FTOOLS
export MXFTOOLS=${xray}/mxftools
export PATH="$MXFTOOLS/bin:$PATH"
export LD_LIBRARY_PATH=$MXFTOOLS/lib:$LD_LIBRARY_PATH
export PFILES=$HOME/pfiles:$MXFTOOLS/syspfiles:$HEADAS/syspfiles
export PERL5LIB=$MXFTOOLS/lib/perl5:$PERL5LIB

echo "MAXI FTOOLS was configured for $MXFTOOLS"


## XANADU$B$N@_Dj$N8e$G$O(B EXT='lnx' $B$H$J$k$N$G(B linux $B$KCV$-49$($k(B
if [ $EXT = lnx ]; then
    EXT=linux
    export EXT
fi



