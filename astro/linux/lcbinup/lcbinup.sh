#!/bin/bash -f -n

scriptname=$(basename $0)
[ -L ${scriptname} ] && scriptname=$(readlink ${scriptname})
sys=$(cd $(dirname ${scriptname}); pwd)
executor="${sys}/lctimebinup"

sed '1,/!/d' $1 > test2.qdp
${executor} > $2
rm -f test2.qdp

