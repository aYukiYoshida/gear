#!/usr/bin/zsh -f

##!/bin/sh

# This scrists is to create image files for aepileupcheckup.py 
# History
# 2010-11; version 0.0; written by S. Yamada
# 2011-01; version 0.1; restructured by T. Yuasa
# 2011-02; version 1.0; compiled and released by S. Yamada
# 2011-12; version 1.1; minor bugs are modified by S. Yamada


#check arguments
if [ _$2 = _ ]; then 
cat << EOF 1>&2
Usage   : `basename $0` (path to observation data folder) (output folder name) [attcor, ON(default) or OFF] [hotpixelcut, OFF(default) or ON]
Example : `basename $0` ver2/400003010 results/400003010/ONON ON ON
(output folder will be created if it does not exist)
EOF
exit 1
fi


#show title
cat << EOF
===============================
`basename $0`
creates grade-sorted XIS images
to check pileup
===============================
EOF

#set argument variables
datafolder=$1
outputdirname=$2



if [ _$3 = _ ]; then 
attcor=ON
else
attcor=$3
cat<<EOF
==================================================
 attitude correction is $3. (should be ON or OFF)
==================================================
EOF
fi

if [ _$4 = _ ]; then 
hotpixelcut=OFF
else
hotpixelcut=$4
cat<<EOF
==========================================
 hotpixelcut is $4. (should be ON or OFF)
==========================================
EOF
fi


obsid=`basename $datafolder`


#check data folder existence
if [ ! -d $datafolder ]; then
cat << EOF 1>&2
`basename $0` :  data folder "$datafolder" not found
EOF
exit 1
fi


#change to full path
function fullpath(){
fullpath_return=$(cd $(dirname $1);pwd)/`basename $1`
}
fullpath $datafolder
datafolder=${fullpath_return}


#check a file
filelist=`ls $datafolder/xis/event_uf/ae* 2> /dev/null | tail -1`
if [ _$filelist = _ ]; then
cat << EOF 1>&2
`basename $0` :  xis event file(s) is not found in "$datafolder"
EOF
exit 1
fi


#create output dir if not exist
if [ ! -d $outputdirname ]; then
	mkdir -p $outputdirname
	#check again
	if [ ! -d $outputdirname ]; then
		echo "`basename $0` : output folder could not be created" 1>&2
		exit 1
	fi
fi
#change to fullpath
fullpath $outputdirname
outputdirname=${fullpath_return}

######################
#function createXCO()
######################
function createXCO() {
#use global variables
# grade
# selection_criteria
rm -f ${xisnum}rp_ig8${enetag}${grade}.xco
rm -f ${xisnum}rp_ig8${enetag}${grade}.img

cat <<EOF > ${xisnum}rp_ig8${enetag}${grade}.xco
clear events
clear mkfsel
clear selection

set xybinsize 8 
select events "$selection_criteria"
yes
set mkfdir ./
select mkf @xis_mkf.sel
$enefilter
show filter 
extract image  

save image ${outputdirname}/${xisnum}rp_ig8${enetag}${grade}.img
no

EOF
}

######################
#function mkselection ()
######################
function mkselection (){
    if [ _$4 = _ ]; then 
        echo "Usage : $0 xisnum enechlow enechhigh enetag"
    fi

    xisnum=$1
    enechlow=$2
    enechhigh=$3
    enetag=$4

    enefilter="filter pha_cutoff $enechlow $enechhigh"

	# grade 1
	grade=gr1
	selection_criteria="(GRADE==1)&&(STATUS>=0&&STATUS<=524287)"
	createXCO
	
	# gradestd 
	grade=grstd
	selection_criteria="(GRADE==0||GRADE==2||GRADE==3||GRADE==4||GRADE==6)&&(STATUS>=0&&STATUS<=524287)"
	createXCO
	
	# gradestdmul 
	grade=grstdmul
	selection_criteria="(GRADE==2||GRADE==3||GRADE==4||GRADE==6)&&(STATUS>=0&&STATUS<=524287)"
	createXCO
}

######################
#function genimg()
######################
function genimg() {
    if [ _$5 = _ ]; then 
        echo "Usage : $0 obsid xisnum enetag enechlow enechhigh enetag"
    fi

    obsid=$1
    xisnum=$2
    enechlow=$3
    enechhigh=$4
    enetag=$5
    echo "==> Obsid=$obsid xisnum=$xisnum energy_low=${enechlow}ch energy_high=${enechhigh}ch"

#do xselect
#xselect <<EOF 2>&1 | tee -a ${xisnum}_xselect.log

    tmpalluffile=${xisnum}_tmpalluf.evt


    xselect <<EOF > ${xisnum}_xselect.log

no

read events $tmpalluffile ./

@${xisnum}rp_ig8${enetag}gr1.xco
@${xisnum}rp_ig8${enetag}grstd.xco
@${xisnum}rp_ig8${enetag}grstdmul.xco
exit
n
EOF



}


######################
#move there
######################

working_folder=$outputdirname/tmpdir/
#if the name of working_folder is long enough, then xselect can stop working.
#working_folder=$outputdirname/tmp_xis_extract_gradesortedimage
mkdir -p $working_folder
if [ ! -d $working_folder ]; then
echo "`basename $0` : could not create working folder = $working_folder"
exit 1
fi

pushd $working_folder &> /dev/null

#1. copy and unzip mkf (if needed)

rm -f ae${obsid}.mkf
mkf_original=`ls $datafolder/auxil/ae${obsid}.mkf* 2> /dev/null | tail -1`
if [ _$mkf_original = _ ]; then
cat << EOF 1>&2
`basename $0` : mkf file is not found...
EOF
exit 1
fi

case "$mkf_original" in
*.gz)
        cp -f $mkf_original .
        gzmkf=`basename $mkf_original`
	gzip -d $gzmkf
	;;
*)
	cp -f $mkf_original .
	;;
esac

# make mkf selection 
mkf_selection=xis_mkf.sel 
rm -f ${mkf_selection}
cat << EOF > ${mkf_selection}
AOCU_HK_CNT3_NML_P==1 && ANG_DIST<1.5 && S0_DTRATE<3 && S1_DTRATE<3 && S2_DTRATE<3 && S3_DTRATE<3 && SAA_HXD==0 && T_SAA_HXD>436 && ELV>5 && DYE_ELV>20
EOF


# 2. copy tel uf file (must be done before checking pileup)

for xisnum in xi0 xi1 xi2 xi3
  do
		#check file
  tmp=`ls ${datafolder}/xis/event_uf/ae*${xisnum}_?_?x??????_uf.evt* 2> /dev/null | tail -1`
  if [ _$tmp = _ ]; then
      continue
  fi

  rm -f ae${obsid}${xisnum}_0_tel_uf.gti
  ls ${datafolder}/xis/hk/ae${obsid}${xisnum}_0_tel_uf.gti* 
  teluffile=`ls ${datafolder}/xis/hk/ae${obsid}${xisnum}_0_tel_uf.gti* 2> /dev/null | tail -1`

  if [ _${teluffile} = _ ]; then
      cat << EOF 1>&2
${datafolder}
`basename $0` : tel uf file is not found... ${teluffile}
EOF
      exit 1
  fi

  teluffilename=`basename ${teluffile} .gz`

  case "${teluffile}" in
      *.gz)
	  echo "unziping teluffile...."
	  cp -f ${teluffile} .
	  telufgzfilename=`basename ${teluffile}`
	  rm -f  $teluffilename
	  gunzip $telufgzfilename
	  ;;
      *)
	  echo "just copying teluffile...."
	  cp -f ${teluffile} .
	  ;;
  esac

  if [ ! -e $teluffilename ]; then
      cat << EOF 1>&2
`basename $0` :  $teluffilename not found
EOF
      exit 1
  fi


#2. copy att file

  attfile=`ls ${datafolder}/auxil/ae${obsid}.att* 2> /dev/null | tail -1`
  if [ _${attfile} = _ ]; then
      cat << EOF 1>&2
`basename $0` : attfile is not found...
EOF
      exit 1
  fi
  
  oldattfits=`basename ${attfile} .gz`


  case "${attfile}" in
      *.gz)
	  echo "unziping attfile...."
	  cp -f ${attfile} .
	  attgzfilename=`basename ${attfile}`
	  rm -f  $oldattfits
	  gunzip $attgzfilename
	  ;;
      *)
	  echo "just copying attfile...."
	  cp -f ${attfile} .
	  ;;
  esac

  if [ ! -e $oldattfits ]; then
      cat << EOF 1>&2
`basename $0` :  $oldattfits not found
EOF
      exit 1
  fi


###############################################
# create event and image for attitude corretion
###############################################


#create a list of event files
  evtfilelist=xis${xisnum}_eventfile.list 
  rm -f ${evtfilelist}
#  ls ${datafolder}/xis/event_uf/ae*${xisnum}*uf.evt* > ${evtfilelist}
  ls ${datafolder}/xis/event_uf/ae*${xisnum}_?_?x??????_uf.evt* > ${evtfilelist}

  tmpalluffile=${xisnum}_tmpalluf.evt
  tmpallclfile=${xisnum}_tmpallcl.evt
  bin1img=${xisnum}_bin1.img

  rm -f $tmpalluffile
  rm -f $bin1img
  rm -f ${xisnum}_xselect_tmpalluf.log
  rm -f ${xisnum}_xselect_tmpallcl.log


  xselect <<EOF > ${xisnum}_xselect_tmpalluf.log

no

read events "@${evtfilelist}" /
filter time file $teluffilename

extract event 

save event $tmpalluffile


exit
n
EOF


  case "${hotpixelcut}" in
      ON)
	  echo "start sysclean...."

	  mv -f ${tmpalluffile} beforesisclean_${tmpalluffile}
	  rm -f cleansis_${xisnum}.log
	  cleansis chipcol=SEGMENT > cleansis_${xisnum}.log <<EOF
beforesisclean_${tmpalluffile}
${tmpalluffile}
5
-5.24
3
0
4095

EOF

	  

	  ;;
      OFF)
	  echo "nothing done for " ${tmpalluffile}
	  ;;
      *)
	  echo "nothing done for " ${tmpalluffile}
	  echo ${hotpixelcut} " should be set ON or OFF "
	  exit 1 
	  ;;
  esac




  selection_criteria_std="(GRADE==0||GRADE==2||GRADE==3||GRADE==4||GRADE==6)&&(STATUS>=0&&STATUS<=524287)"

  xselect <<EOF > ${xisnum}_xselect_tmpallcl.log

no

read events $tmpalluffile ./


select events "${selection_criteria_std}"
yes
set mkfdir ./
select mkf @xis_mkf.sel

show filter

extract event 

save event $tmpallclfile

set xybinsize 1

extract image 

save image ${bin1img}


exit
n
EOF


  case "${attcor}" in
      ON)
	  echo "start aeattitudetuned.py...."
	  attcor_tmpfinalevtfile=attcor_${tmpfinalevtfile}
	  rm -f $attcor_tmpfinalevtfile
	  rm -f new_${xisnum}_plot.pdf

	  aeattitudetuned.py $tmpallclfile $bin1img $oldattfits new_${xisnum}_${oldattfits} -f new_${xisnum}_plot.pdf

	  mv -f ${tmpalluffile} old_${tmpalluffile}
	  rm -f ${xisnum}_tmp_xiscoord.log 
	  xiscoord infile=old_${tmpalluffile} outfile=${tmpalluffile} attitude=new_${xisnum}_${oldattfits} pointing=KEY > ${xisnum}_tmp_xiscoord.log 2>&1


	  ;;
      OFF)
	  echo "nothing done for " ${tmpalluffile}
	  ;;
      *)
	  echo "nothing done for " ${tmpalluffile}
	  echo ${attcor} " should be set ON or OFF "
	  exit 1 
	  ;;
  esac


done


######################
#loop for energy bands
######################
cat << EOF
Data folder = $datafolder
Output folder = $outputdirname

Running xselect to produce grade sorted images...
EOF

#for ene in 0.5_10.0 

for ene in 0.5_10.0 3.0_10.0 7.0_10.0
do

  enelow=`echo $ene | awk -F_ '{print $1}'`
  enehigh=`echo $ene | awk -F_ '{print $2}'`
  tmpenetag=${enelow}_${enehigh}
  enetag=ec`echo $tmpenetag | sed -e 's/\./p/g'`keV  
  enechlow=`echo $enelow | awk '{printf("%d",(($1)*1000./3.65)+1)}'`
  enechhigh=`echo $enehigh | awk '{printf("%d",(($1)*1000./3.65)+1)}'`
    
	for xisnum in xi0 xi1 xi2 xi3
#	for xisnum in xi0
	do
		#check file
	  tmp=`ls ${datafolder}/xis/event_uf/ae*${xisnum}_?_?x??????_uf.evt* 2> /dev/null | tail -1`
	  if [ _$tmp = _ ]; then
	      continue
	  fi
				
	  mkselection $xisnum $enechlow $enechhigh $enetag
	  genimg $obsid $xisnum $enechlow $enechhigh $enetag
		
	done
done 


######################
#move out
######################
popd &> /dev/null

cat << EOF
COMPLETED!
EOF
