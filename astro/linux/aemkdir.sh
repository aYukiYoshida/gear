#!/bin/bash

################################################################################
##make directry for suzaku analysis
################################################################################

dir=$1

if [ "x" = "x${dir}" ];then
    echo "Please enter the directry name for `basename $0`"
    exit 1
else
    
#xis
    mkdir ${dir}/xis/event_rp
    mkdir -p ${dir}/xis/analysis/evt/
    mkdir -p ${dir}/xis/analysis/img/raw
    mkdir ${dir}/xis/analysis/img/src
    mkdir ${dir}/xis/analysis/img/energydiv
    mkdir ${dir}/xis/analysis/expmap/
    mkdir -p ${dir}/xis/analysis/reg/src
    mkdir -p ${dir}/xis/analysis/lc/src
    mkdir -p ${dir}/xis/analysis/gti/rescrn
    mkdir -p ${dir}/xis/analysis/spec/src
    mkdir -p ${dir}/xis/analysis/rsp/src
    
    mkdir -p ${dir}/xis/analysis/fit/src/model
    mkdir ${dir}/xis/analysis/fit/src/BestfitModel
    mkdir ${dir}/xis/analysis/fit/src/qdpfile
    mkdir ${dir}/xis/analysis/fit/src/log
    mkdir ${dir}/xis/analysis/fit/src/report
    mkdir ${dir}/xis/analysis/fit/src/parameter/
    
    
#hxd
    mkdir ${dir}/hxd/event_rp/
    mkdir -p ${dir}/hxd/analysis/evt/
    mkdir -p ${dir}/hxd/analysis/lc/raw
    mkdir ${dir}/hxd/analysis/gti/
    mkdir -p ${dir}/hxd/analysis/spec/raw
    mkdir ${dir}/hxd/analysis/rsp/
    
    
#broadband
    mkdir -p ${dir}/broadband/lc/src
    mkdir ${dir}/broadband/lc/energydiv
    mkdir -p ${dir}/broadband/spec/src
    mkdir ${dir}/broadband/rsp
    mkdir -p ${dir}/broadband/fit/src/model
    mkdir ${dir}/broadband/fit/src/BestfitModel
    mkdir ${dir}/broadband/fit/src/qdpfile
    mkdir ${dir}/broadband/fit/src/log
    mkdir -p ${dir}/broadband/fit/src/report/
    mkdir ${dir}/broadband/fit/src/keV2unfolded
    
fi

#EOF#
