#!/bin/bash -f

###########################################################################
## VARIABLES
###########################################################################
XRAYSYS=/usr/local/xray
scriptname=`basename $0`
aliasname=${scriptname%.sh}
DONE_USAGE_FLG=0


###########################################################################
## Function
###########################################################################
usage(){
	echo "USAGE: ${aliasname} <TYPE>"
	echo ""
	echo "<TYPE>"
	echo "  [ HEASOFT && HEADAS ]"
	echo "    heasoft       : heasoft v6.26"
	echo "    heasoft616    : heasoft v6.16"
	echo "    heasoft617    : heasoft v6.17"
	echo "    heasoft619    : heasoft v6.19"
	echo "    heasoft620    : heasoft v6.20"
	echo "    heasoft623    : heasoft v6.23"
	echo "    heasoft624    : heasoft v6.24"
	echo "    heasoft625    : heasoft v6.25"
	echo "    heasoft626    : heasoft v6.26"
	echo "    heasoft627    : heasoft v6.27"
	echo "    asca          : heasoft v6.26"
	echo "    suzaku        : heasoft v6.26"
	echo "    maxi          : heasoft v6.26"
	echo "    hitomi        : heasoft v6.26" 
	echo "    rxte          : heasoft v6.26"
	echo "    swift         : heasoft v6.26"
	echo "    nustar        : heasoft v6.26"
	echo "    nicer         : heasoft v6.26 (supported by v6.23 or later)"
	echo "    The tools for the following obserbatories are supported by version 6.20."
	echo "    Einstein, CGRO, HEAO-1, OSO-8, Vela, ROSAT, and INTEGRAL"
	echo ""
	echo "  [ CHANDRA ]"
	echo "    chandra       : CIAO v4.8"
	echo "    ciao          : CIAO v4.8"
	echo "    ciao48        : CIAO v4.8"
	echo ""
	echo "  [ SPEX ]"
	echo "    spex          : SPEX v3.05.00"
	echo "    spex301       : SPEX v3.01.00"
	echo "    spex305       : SPEX v3.05.00"
	DONE_USAGE_FLG=1
}


error(){
    echo 'ERROR: "'$1'" is not supported.'
    echo '       "'${aliasname}' -l" or "'${aliasname}' --list" shows available lists.'
	return 1
}


set_arch_for_heasoft(){
	# OS determination
	local version=$1
	case `uname` in
		Linux)
			local sys=linux
			local os=linux
			;;
		SunOS)
			local sys=sun
			local os=sol
			;;
		Darwin)
			case `uname -p` in
				powerpc)
					local sys=powerpc-apple-darwin
					local os=mac
					;;
				i386)
					local sys=86-apple-darwin
					local os=intel_mac
					;;
				*)
					local sys=86-apple-darwin
					local os=intel_mac
					;;
			esac
			;;
		*) 
			local sys=unsupported
			local os=unsupported
			;;
	esac
	arch=$(/bin/ls ${XRAYSYS}/heasoft/${version} | grep ${sys})
}

################################################################################
## OPTION
################################################################################

GETOPT=`getopt -q -o hul --long help,usage,list -- "$@"` ; [ $? != 0 ] && usage

#echo $@ ##DEBUG

eval set -- "$GETOPT"

#echo $@ ## DEBUG

while true ;do
    case $1 in
	-h|--help|-u|--usage|-l|--list)
	    usage ; break
	    ;;
	--) shift ; break 
		;;
	*) usage ; break
		;;
    esac
done


################################################################################
## MAIN
################################################################################
if [ ${DONE_USAGE_FLG} -eq 0 ];then
	input=$1
	if [ $# -eq 0 ]; then
		usage

	else
		#software version determination
		HEASOFT_FLG=0
		CIAO_FLG=0
		SPEX_FLG=0

		case ${input} in
			common) : ;;
			heasoft)    heasoft_version=6.26; HEASOFT_FLG=1 ;;
			heasoft616) heasoft_version=6.16; HEASOFT_FLG=1 ;;
			heasoft617) heasoft_version=6.17; HEASOFT_FLG=1 ;;
			heasoft618) heasoft_version=6.18; HEASOFT_FLG=1 ;;
			heasoft619) heasoft_version=6.19; HEASOFT_FLG=1 ;;
			heasoft620) heasoft_version=6.20; HEASOFT_FLG=1 ;;
			heasoft623) heasoft_version=6.23; HEASOFT_FLG=1 ;;
			heasoft624) heasoft_version=6.24; HEASOFT_FLG=1 ;;
			heasoft625) heasoft_version=6.25; HEASOFT_FLG=1 ;;
			heasoft626) heasoft_version=6.26; HEASOFT_FLG=1 ;;
			heasoft627) heasoft_version=6.27; HEASOFT_FLG=1 ;;
			asca|suzaku|hitomi|nustar|swift|maxi|nicer) heasoft_version=6.26; HEASOFT_FLG=1 ;;
			chandra|ciao|ciao48) ciao_version=4.8; CIAO_FLG=1 ;;
			spex|spex305) spex_version=3.05.00; SPEX_FLG=1;;
			spex301) spex_version=3.01.00; SPEX_FLG=1 ;;	
			*) error ${input} ;;
		esac
		
		if [ $? -eq 0 ];then

			# SET ENVIRONMENT TO ANALYSIS
			echo "SET ENVIRONMENT TO ANALYSIS FOR X-RAY ASTRONOMY!!"
			# set no-xray-analysis-path
			if [ ! $(set|sed -n '/NO_XRAY_PATH/p') ];then
				NO_XRAY_PATH=$PATH
			fi

            if [ ! $(set|sed -n '/NO_XRAY_PYTHONPATH/p') ]; then
                NO_XRAY_PYTHONPATH=$PYTHONPASH
            fi

            if [ ! $(set|sed -n '/NO_XRAY_LD_LIBRARY_PATH/p') ]; then
                NO_XRAY_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
            fi

			export PATH=${XRAYSYS}/bin:$NO_XRAY_PATH
            export PYTHONPATH=$NO_XRAY_PYTHONPATH
            export LD_LIBRARY_PATH=$NO_XRAY_LD_LIBRARY_PATH

			if [ ! $(set|sed -n '/IS_HEASOFT_SETUP/p') ];then
				IS_HEASOFT_SETUP=0
			fi

			if [ ! $(set|sed -n '/IS_CIAO_SETUP/p') ];then
				IS_CIAO_SETUP=0
			fi

			if [ ! $(set|sed -n '/IS_SPEX_SETUP/p') ];then
				IS_SPEX_SETUP=0
			fi

            if [ ${HEASOFT_FLG} -eq 1 ]||[ ${IS_HEASOFT_SETUP} -eq 1 ];then
				if [ ${HEASOFT_FLG} -eq 0 ]&&[ ${IS_HEASOFT_SETUP} -eq 1 ];then
					heasoft_version=$(set|sed -n '/PREVIOUS_SETUP_HEASOFT_VERSION/p'|cut -d= -f2)
				fi
				set_arch_for_heasoft ${heasoft_version}
				
				## setup analysis main tool 
				export HEADAS=${XRAYSYS}/heasoft/${heasoft_version}/${arch}
				export LMODDIR=${XRAYSYS}/heasoft/local-model
				source $HEADAS/headas-init.sh && echo "HEAsoft was configured for $HEADAS"

				## alias
				alias fdumq='`which fdump` outfile=STDOUT columns=- rows=- more=yes prdata=no'
				alias fdumd='`which fdump` outfile=STDOUT columns=- rows=- more=yes prhead=no'

				## Set-up MAXI FTOOLS
				if [[ ${input} = maxi ]] ;then
					export MXFTOOLS=${XRAYSYS}/mxftools
					export PATH="$MXFTOOLS/bin:$PATH"
					export LD_LIBRARY_PATH=$MXFTOOLS/lib:$LD_LIBRARY_PATH
					export PFILES=$HOME/pfiles:$MXFTOOLS/syspfiles:$HEADAS/syspfiles
					export PERL5LIB=$MXFTOOLS/lib/perl5:$PERL5LIB
					echo "MAXI FTOOLS was configured for $MXFTOOLS"
				fi
				
				## CALDB
				# source $CALDB/software/tools/caldbinit.sh
				export CALDB=${XRAYSYS}/caldb
				export CALDBCONFIG=$CALDB/software/tools/caldb.config
				export CALDBALIAS=$CALDB/software/tools/alias_config.fits
				echo "CALDB set to $CALDB"
				echo "CALDBCONFIG set to $CALDBCONFIG"
				echo "CALDBALIAS set to $CALDBALIAS"

				## XANADUの設定の後では EXT='lnx' となるので linux に置き換える
				if [[ $EXT = lnx ]]; then
					EXT=linux
					export EXT
				fi

				## set flags
				PREVIOUS_SETUP_HEASOFT_VERSION=${heasoft_version}
				IS_HEASOFT_SETUP=1
			fi

            if [ ${CIAO_FLG} -eq 1 ]||[ ${IS_CIAO_SETUP} -eq 1 ];then
				if [ ${CIAO_FLG} -eq 0 ]&&[ ${IS_CIAO_SETUP} -eq 1 ];then
					ciao_version=$(set|sed -n '/PREVIOUS_SETUP_CIAO_VERSION/p'|cut -d= -f2)
				fi

				## setup analysis main tool 
				export CIAOSYS=${XRAYSYS}/ciao/ciao-${ciao_version}
				source ${CIAOSYS}/bin/ciao.bash -o && echo "CIAO was configured for $CIAOSYS"

				## CALDB	    
				check_ciao_caldb

				## set flags
				PREVIOUS_SETUP_CIAO_VERSION=${ciao_version}
				IS_CIAO_SETUP=1
            fi

            if [ ${SPEX_FLG} -eq 1 ]||[ ${IS_SPEX_SETUP} -eq 1 ];then
				if [ ${SPEX_FLG} -eq 0 ]&&[ ${IS_SPEX_SETUP} -eq 1 ];then
					spex_version=$(set|sed -n '/PREVIOUS_SETUP_SPEX_VERSION/p'|cut -d= -f2)
				fi
				export SPEX90=${XRAYSYS}/spex/SPEX-${spex_version}-Linux
				source $SPEX90/tools/spexdist.sh && echo "SPEX was configured for $SPEX90"

				## set flags
				PREVIOUS_SETUP_SPEX_VERSION=${spex_version}
				IS_SPEX_SETUP=1
			fi						
			
			# COMMON

			## PGPLOT
			export PGPLOT_TYPE=/xw

			## ROOT
			export ROOTSYS=/usr/local/xray/cern/root/sys
			export PATH=${ROOTSYS}/bin:$PATH
			export PYTHONPATH=$ROOTSYS/lib/root:$PYTHONPATH
			export LD_LIBRARY_PATH=${ROOTSYS}/lib/root:${LD_LIBRARY_PATH}
			source ${ROOTSYS}/bin/thisroot.sh
			alias root="${ROOTSYS}/bin/root -l"
			echo "ROOT was configured for $ROOTSYS"
			
			## SAOIMAGE			
			export SAOIMAGESYS=/usr/local/xray/saoimage
			export PATH=${SAOIMAGESYS}/bin:$PATH
			echo "SAOIMAGE was configured for $SAOIMAGESYS"
			ds9(){
				${SAOIMAGESYS}/bin/ds9.sys $@ -zoom to fit -cmap Heat -log
			}

			## FUNTOOLS
			export FUNTOOLSSYS=/usr/local/xray/funtools/sys
			export PATH=${FUNTOOLSSYS}/bin:$PATH
			echo "FUNTOOLS was configured for $FUNTOOLSSYS"
		fi
	fi
fi
#EOF#
