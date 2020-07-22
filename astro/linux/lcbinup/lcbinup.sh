#!/bin/bash -f -n

SCRIPTFILE=$0
[ -L ${SCRIPTFILE} ] && SCRIPTFILE=$(readlink ${SCRIPTFILE})
SCRIPTNAME=$(basename ${SCRIPTFILE%.*})
sys=$(dirname ${SCRIPTFILE})
executor=${sys}/lctimebinup

sed '1,/!/d' $1 > test2.qdp
${executor} > $2
rm -f test2.qdp

