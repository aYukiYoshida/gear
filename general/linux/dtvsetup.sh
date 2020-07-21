#!/bin/bash -f

###########################################################################
## VARIABLES
###########################################################################
scriptname=`basename $0`
aliasname=${scriptname%.sh}
DEPOT_TOOLS_DIR=$HOME/Works/tools/chromium/depot_tools
DONE_USAGE_FLG=0

###########################################################################
## Function
###########################################################################
usage(){
    echo "USAGE: ${aliasname} <PLATFORM>"
    echo ""
    echo "PLATFORMS"
    echo "    chromium    : standard environment"
    echo "    chrome      : standard environment"
    echo "    linux       : standard environment"
    echo "    android     : android 7.0 environment"
    echo "    android7    : android 7.0 environment"
    echo "    android-std : android-stadio environment"
    echo "    toshiba     : toshiba environment"
	DONE_USAGE_FLG=1
}

error(){
    echo 'ERROR: "'$1'" is not supported.'
    echo '       "'${aliasname}' -l" or "'${aliasname}' --list" shows available lists.'
	return 1
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
    platform=$1

    CHROMIUM_FLG=0
    ANDROID_FLG=0
    ANDROID7_FLG=0
    ANDROID_STUDIO_FLG=0
    TOSHIBA_FLG=0
    UNSUPPORTED_FLG=0

    if [ $# -eq 0 ]; then
        usage
    else
        case ${platform} in
            chromium)    CHROMIUM_FLG=1 ;;
            chrome)      CHROMIUM_FLG=1 ;;
            linux)       CHROMIUM_FLG=1 ;;
            android)     CHROMIUM_FLG=1; ANDROID_FLG=1; ANDROID7_FLG=1 ;;
            android7)    CHROMIUM_FLG=1; ANDROID_FLG=1; ANDROID7_FLG=1 ;;
            android-std) CHROMIUM_FLG=1; ANDROID_FLG=1; ANDROID_STUDIO_FLG=1;;
            toshiba)     CHROMIUM_FLG=1; TOSHIBA_FLG=1 ;;
            *) 		     error ${platform} ;;
        esac

        if [ $? -eq 0 ];then
            echo "SET ENVIRONMENT TO DEVELOP NFBE !!"
            if [ ! $(set|sed -n '/NO_DEV_PATH/p') ];then
                NO_DEV_PATH=$PATH
            fi
            export PATH=$NO_DEV_PATH

            if [ ${CHROMIUM_FLG} -eq 1 ];then
                export PATH=${DEPOT_TOOLS_DIR}:$PATH
                export PATH=/usr/lib/icecc/bin:$PATH
            fi

            if [ ${ANDROID7_FLG} -eq 1 ];then
                export ANDROID_HOME=$HOME/Works/tools/android/sdk/api24/android-sdk-linux && echo "ANDROID_HOME sets to $ANDROID_HOME"
                export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$PATH
            fi

            if [ ${ANDROID_STUDIO_FLG} -eq 1 ];then
                export ANDROID_HOME=$HOME/Works/tools/android/sdk/studio && echo "ANDROID_HOME sets to $ANDROID_HOME"
                export PATH=$HOME/Works/tools/android/android-studio/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$PATH
            fi

            if [ ${ANDROID_FLG} -eq 1 ];then
                export ANDROID_NDK_HOME=$HOME/Works/tools/android/ndk/android-ndk-r12b && echo "ANDROID_NDK_HOME sets to $ANDROID_NDK_HOME"
                export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 && echo "JAVA_HOME sets to $JAVA_HOME"
                export PATH=$ANDROID_NDK_HOME:$JAVA_HOME/bin:$PATH
            fi

            if [ ${TOSHIBA_FLG} -eq 1 ];then
                export PATH=/usr/arm-2014.05/bin.wrap:/usr/arm-2014.05/bin:$PATH
            fi

            echo "PATH sets to $PATH"
        fi
    fi
fi
#EOF#