#!/bin/tcsh -f

## xispi script


setenv PFILES .

unsetenv HEADAS
# comment out this to test with HEADAS tasks
# setenv HEADAS /adsoft/headas/develop/i686-pc-linux-gnu-libc2.3.2
setenv CALDB /usr/local/xray/caldb
setenv CALDBCONFIG $CALDB/software/tools/caldb.config
setenv CALDBALIAS $CALDB/software/tools/alias_config.fits
#source /usr/local/xray/setup/setup_headas6.11.csh
#source /usr/local/xray/setup/setup_headas68.csh
#source /usr/local/xray/setup/setup_heasoft641.csh
#source /usr/local/astroe/com/calibration/caldb/2008-06-21/caldbinit.csh
#source /usr/local/astroe/com/calibration/caldb/2006-07-19/caldbinit.csh
#source ../caldb/caldbinit.csh
#source /usr/local/astroe/com/calibration/caldb/2006-10-24/caldbinit.csh
#set xissim = /usr/local/astroe/com/src/astearf+SimASTE/2006-11-26/$EXT/xissim
#set xissim=`which xissim`
punlearn xissim
set xissim=`which xissim`
if ( $# == 1 ) then
	set single=t
	goto $1
	exit
endif

foreach nocal ( "cal" )
echo "nocal=$nocal"
foreach d ( ../../evt/*_cl )
    set base=`ls -1 $d/ | head -1 | sed 's/xi.*//'`
    set name=`echo $d | sed 's/_cl//' | sed 's/..\/..\/evt\///'` 
    foreach i ( 0 1 3 )
    #foreach i ( 0 1 2 3 )
    set obs=../../evt/img_xis${i}_nocal.fits
    #set obs=../obs/${name}xi${i}cor28_${nocal}_0.5_5.0_sky.img.gz
#    set obs=../../pi/${base}xi${i}cor28_${nocal}.pi
    set ea1 = ( 24.443784053014 )
    #set ea1=`fkeyprint ${obs} MEAN_EA1 | grep 'MEAN_EA1' | awk 'NR=3{print $2}' | tail -n 1`
    set ea2=( 102.914101952946 )
    #set ea2=`fkeyprint ${obs} MEAN_EA2 | grep 'MEAN_EA2' | awk 'NR=3{print $2}' | tail -n 1`
    set ea3=( 225.000493684051 )
    #set ea3=`fkeyprint ${obs} MEAN_EA3 | grep 'MEAN_EA3' | awk 'NR=3{print $2}' | tail -n 1`
    set alpha = ( 24.4375 )
    set delta = ( -12.9125 )
    set DATE=( 2010-12-25T03:51:59 )
    #set DATE=`fkeyprint ${obs} DATE-OBS | grep 'DATE-OBS' | awk 'NR=2{print $2}' | tail -n 1`
       echo "name=${name}, base=${base}, ea1=${ea1}, ea2=${ea2}, ea3=${ea3}, DATE-OBS=${DATE}"

xissim-x${i}-cxb:
cat <<EOF
/=============================================================================\
|== xissim-x${i}-gal-${name} ============================================================|
\=============================================================================/

EOF

set command="$xissim \
enable_photongen=yes \
photon_flux=0.0014171 \
flux_emin=0.4 \
flux_emax=10.0 \
spec_mode=0 \
qdp_spec_file=sim_xis${i}_gal_YokojikuEnergy.qdp \
image_mode=2 \
ra=${alpha} \
dec=${delta} \
sky_r_min=0 \
sky_r_max=20 \
time_mode=1 \
limit_mode=1 \
exposure=4000000 \
instrume=XIS${i} \
teldef=CALDB \
leapfile=CALDB \
ea1=${ea1} \
ea2=${ea2} \
ea3=${ea3} \
gtifile=none \
attitude=none \
date_obs=${DATE} \
pointing=USER \
ref_alpha=${alpha} \
ref_delta=${delta} \
ref_roll=0.0 \
mirrorfile=CALDB \
reflectfile=CALDB \
backproffile=CALDB \
shieldfile=CALDB \
xis_rmffile=../../evt/xi${i}cor28_${nocal}.rmf.gz \
xis_contamifile=none \
xis_efficiency=yes \
xis_chip_select=yes \
outfile=sim-xis${i}-gal.evt \
clobber=yes \
"
echo % $command | sed -e 's/  / /g' -e 's/ *$//'; echo
eval $command

end #i
end #num
end
exit

if ( $?single == 1 ) exit





