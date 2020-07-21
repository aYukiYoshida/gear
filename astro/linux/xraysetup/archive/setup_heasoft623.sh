#!/bin/bash -f

#######################
##
## HEAsoft V6.23
##
#######################

xray='/usr/local/xray'

#if [ "x$HEADAS" != x ]; then
#    if [ "x$USER" != x && "x$prompt" != x ]; then
#	echo "HEAsoft already configured for $HEADAS"
#    fi
#    exit 1
#fi

version=6.23
top=${xray}/heasoft/${version}

arch=`/bin/ls $top | grep ${sys}`

HEADAS=${xray}/heasoft/${version}/${arch}
export HEADAS 
LMODDIR=${xray}/heasoft/local/model
export LMODDIR

source $HEADAS/headas-init.sh && echo "HEAsoft was configured for $HEADAS"

## XANADU$B$N@_Dj$N8e$G$O(B EXT='lnx' $B$H$J$k$N$G(B linux $B$KCV$-49$($k(B
if [ $EXT = lnx ]; then
    EXT=linux
    export EXT
fi
