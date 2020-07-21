
#!/bin/csh -f

#set xisnxbgen=/usr/local/astroe/xis/src/tools/xisnxbgen/2007-11-23/$EXT/xisnxbgen
#cp -f `dirname ${xisnxbgen}`/../xisnxbgen.par ~/pfiles/
#source /usr/local/astroe/com/calibration/caldb/2007-11-22/caldbinit.csh
unsetenv LHEASOFT
unsetenv HEADAS
#source /usr/local/xray/setup/setup_heasoft64.csh
#set xispi=/usr/local/astroe/xis/src/xisftools/20080410/linux/xispi
#source /usr/local/xray/setup/setup_heasoft641.csh
#source /usr/local/astroe/com/calibration/caldb/2008-06-21/caldbinit.csh


unsetenv CALDB
unsetenv CALDBCONFIG
unsetenv HEADAS

setenv CALDB /usr/local/xray/caldb
setenv CALDBCONFIG $CALDB/software/tools/caldb.config
setenv CALDBALIAS $CALDB/software/tools/alias_config.fits
#source /$CALDB/software/tools/caldbinit.sh
#source /usr/local/xray/setup/setup_headas6.11.csh
#set xispi=/usr/local/xray/headas/6.8/i686-pc-linux-gnu-libc2.7/bin/xispi
#set path = (`dirname $xispi` $path)

punlearn xisnxbgen
set xisnxbgen=`which xisnxbgen`

set time_min=0.0
set time_max=0.0

foreach nocal ( "cal")
echo "nocal=$nocal"
foreach d ( ../../evt/*_cl )
    set base=`ls -1 $d/ | head -1 | sed 's/xi.*//'`
    set name=`echo $d | sed 's/_cl//' | sed 's/..\/..\/evt\///'` 
    foreach s ( 0 1 3 )
	set files=`find ../../evt -name ${name}xi${s}cor28.evt.gz -print`
	echo "files=${files}"
	if ( "$files" == "" ) continue
	    foreach evt ( ${files} )
	    set leapfile=CALDB
	    set xissim_teldef=CALDB   	
	    set xissimarfgen6_contamifile=CALDB
	    echo $evt
	    set d=`dirname $evt`
	    set f=`basename $evt`
	    set b=`basename $evt .evt.gz`
	    set obs=../../evt/spec_xis${s}_nocal.pha
#	    set obs=../../pi/${name}xi${s}cor28_${nocal}.pi
	    echo "obs=$obs"
	    if ( ! -f $obs ) continue
		set region=../../evt/reg_xis${s}_forback_phy.reg
#		set region=../../reg/a222a223_1deg.reg
#		foreach e ( 1 2 3 4 5 )
#		set pi_min = ( 109 )
		set pi_min = ( 136 )
#		set pi_min = ( 547 )
#		set pi_min = ( 1369 )
#		set pi_min = ( 136 273 547 136 136 )

#		set pi_max = ( 547 )
#		set pi_max = ( 1369 )
		set pi_max = ( 2739 )
#		set pi_max = ( 547 1369 2739 2739 1369 )
#		set pi_max = ( 273 547 2739 2739 1369 )
		
#		set ene = ( "0.4_2" )
#		set ene = ( "2_5" )
#		set ene = ( "5_10.0" )
#		set ene = ( "0.4_10.0" )
		set ene = ( "0.5_10.0" )
#		set ene = ( "0.4_2" "2_5" "5_10.0" "0.4_10.0" "0.5_2.0" )
#		set ene = ( "0.5_1" "1_2" "2_10.0" "0.5_10.0" "0.5_5.0")
#		set pi_min=136
#		set pi_max=273
#		set ene=0.5_1
		set outfile=img_nxb_xis${s}_nocal.img.gz
#		set outfile=nxb_xis${s}_${ene[$e]}_nocal.img.gz
#		set outfile=${name}xi${s}_${nocal}_nxb_${ene[$e]}.img.gz
		set target=`echo $b | sed 's/xi[0-3].*//'`
		set attitude=../../../data/805035010/auxil/ae805035010.att.gz
#		set attitude=../../evt/${name}_aux/*.att.gz
		set rmffile=../../evt/resp_xis${s}_nocal.rmf
#		set rmffile=../../rmf/${name}xi${s}cor28.rmf.gz
		set orbit=../../../data/805035010/auxil/ae805035010.orb.gz
#		set orbit=../../evt/${name}_aux/*.orb.gz
#		set pi_min=136
#		set pi_max=1369
		echo "target=$target attitude=$attitude orbit=$orbit"
		if ( ${nocal} == nocal ) then
			set pixq_and=65536
			else
			set pixq_and=0
		endif
		rm -f ${outfile} ${outfile}
		${xisnxbgen} outfile=${outfile} phafile=${obs} region_mode=SKYREG regfile=${region} orbit=${orbit} attitude=${attitude} pixq_and=${pixq_and} time_min=${time_min} time_max=${time_max} pi_min=${pi_min} pi_max=${pi_max}
		if ( ! -f ${outfile} ) then
		    echo "ERROR: ${outfile} not found"
		    exit 1
		endif
end
end
end
end
end
