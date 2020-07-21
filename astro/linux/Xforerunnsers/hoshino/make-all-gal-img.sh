#!/bin/tcsh -f
foreach d ( ../../evt/*_cl )
    set base=`ls -1 $d/ | head -1 | sed 's/xi.*//'`
    set name=`echo $d | sed 's/_cl//' | sed 's/..\/..\/evt\///'` 
       echo "name=$name, base=${base}"
foreach i ( 0 1 3 )
#foreach i ( 0 1 2 3 )
    #foreach e ( 1 )
    foreach e ( 1 2 3 4 5 )
    #set ph_lo = ( 109 )
    set ph_lo = ( 109  547 1369 109 136 )
    #set ph_lo = ( 136 273 547 136 136 )
    #set ph_hi = ( 2739 )
    set ph_hi = ( 547 1369 2739 2739 1370 )
    #set ph_hi = ( 273 547 2739 2739 1369 )
    #set ene = ( "0.4_10" )
    set ene = ( "0.4_2" "2_5" "5_10" "0.4_10.0" "0.5_2.0" )
    #set ene = ( "0.5_1" "1_2" "2_10" "0.5_10.0" "0.5_5.0")
set evtfile = sim_xis${i}_gal.evt
#set evtfile = sim-x${i}-gal-${name}.evt.gz
#set imgfile = sim_xis${i}_gal_nocal.img
set imgfile = sim_xis${i}_gal_${ene[$e]}_nocal.img
#set imgfile = sim-x${i}-gal-${name}-${ene[$e]}-cal.img
rm -f ${imgfile}

xselect <<EOF
xis${i}
read events $evtfile
./
yes

filter pha_cutoff ${ph_lo[$e]} ${ph_hi[$e]}
filter column "status=0:65535"

set xybin 1
set image SKY

extract image
save image ${imgfile}
exit
no
EOF

end
end
end

#filter column "status=0:65535"
#filter region ../reg/a2104ps.reg


