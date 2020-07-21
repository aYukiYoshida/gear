#!/bin/sh

####################################
#  make file list for mca to qdp
#                 &
#  execute "mca2qdp(fortran program)"
#
#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
#  usage
#
#  px4mca2qdp.sh dir_name 
####################################

mca2qdp=/data09/yyoshida/interferometer/coherent/data/PX4/Tools/mca2qdp
mca=`ls $1/*.mca`

rm -f $1_flist
for i in ${mca} ;do
echo \"${i}\" \"${i%.mca}.qdp\" >> $1_flist
done
${mca2qdp} < $1_flist
