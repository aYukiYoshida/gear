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

## XANADUの設定の後では EXT='lnx' となるので linux に置き換える
if [ $EXT = lnx ]; then
    EXT=linux
    export EXT
fi
