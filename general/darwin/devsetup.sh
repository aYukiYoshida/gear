#!/bin/bash -f

###########################################################################
## VARIABLES
###########################################################################
scriptname=`basename $0`
aliasname=${scriptname%.sh}
DONE_USAGE_FLG=0

###########################################################################
## Function
###########################################################################
usage(){
    echo "USAGE: ${aliasname} <PLATFORM>"
    echo ""
    echo "TASKS:"
    echo "  aws     : AWS environment"
    echo "  gcp     : GCP environment"
    echo "  heroku  : Heroku environment"
    # echo "  root    : ROOT environment"
    echo "  android : Android environment"
    echo "  epub    : EPUB environment"
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

    AWS_FLG=0
    GCP_FLG=0
    HEROKU_FLG=0
    ANDROID_FLG=0
    ROOT_FLG=0
    EPUB_FLG=0
    UNSUPPORTED_FLG=0

    if [ $# -eq 0 ]; then
        usage
    else
        case ${platform} in
            aws)     AWS_FLG=1 ;;
            gcp)     GCP_FLG=1 ;;
            google)  GCP_FLG=1 ;;
            heroku)  HEROKU_FLG=1 ;;
            android) ANDROID_FLG=1 ;;
            # root)    ROOT_FLG=1 ;;
            epub)    ANDROID_FLG=1; EPUB_FLG=1 ;;
            *) 		 error ${platform} ;;
        esac

        if [ $? -eq 0 ];then
            echo "SET ENVIRONMENT TO DEVELOP !!"
            if [ ! $(set|sed -n '/NO_DEV_PATH/p') ]; then
                NO_DEV_PATH=$PATH
            fi

            if [ ! $(set|sed -n '/NO_DEV_PYTHONPATH/p') ]; then
                NO_DEV_PYTHONPATH=$PYTHONPASH
            fi

            if [ ! $(set|sed -n '/NO_DEV_LD_LIBRARY_PATH/p') ]; then
                NO_DEV_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
            fi

            export PATH=$NO_DEV_PATH
            export PYTHONPATH=$NO_DEV_PYTHONPATH
            export LD_LIBRARY_PATH=$NO_DEV_LD_LIBRARY_PATH

            if [ ${ROOT_FLG} -eq 1 ];then
                export ROOTSYS=/usr/local/xray/root && echo "ROOTSYS sets to $ROOTSYS"
                export PATH=$ROOTSYS/bin:$PATH
                export PYTHONPATH=$ROOTSYS/lib:$PYTHONPATH
                export LD_LIBRARY_PATH=$ROOTSYS/lib:$LD_LIBRARY_PATH
            fi

            if [ ${GCP_FLG} -eq 1 ];then
                export GOOGLE_CLOUD_SDK_SYS="/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk" && echo "GOOGLE_CLOUD_SDK_SYS sets to $GOOGLE_CLOUD_SDK_SYS"
                export CLOUDSDK_PYTHON="/usr/local/opt/python@3.8/libexec/bin/python" && echo "CLOUDSDK_PYTHON sets to $CLOUDSDK_PYTHON"
                # The next line updates PATH for the Google Cloud SDK.
                [ -f $GOOGLE_CLOUD_SDK_SYS/path.zsh.inc ] && source $GOOGLE_CLOUD_SDK_SYS/path.zsh.inc
                # The next line enables shell command completion for gcloud.
                [ -f $GOOGLE_CLOUD_SDK_SYS/completion.zsh.inc ] && source$GOOGLE_CLOUD_SDK_SYS/completion.zsh.inc
            fi

            if [ ${AWS_FLG} -eq 1 ];then
                # The next line updates PATH for the AWS CLI
                export PATH=$HOME/Works/tool/amazon/aws-cli/bin:$PATH
            fi

            if [ ${HEROKU_FLG} -eq 1 ];then
                export PATH=/Applications/Postgres.app/Contents/Versions/latest/bin:$PATH
                # heroku autocomplete setup
                HEROKU_AC_ZSH_SETUP_PATH=$HOME/Library/Caches/heroku/autocomplete/zsh_setup && test -f $HEROKU_AC_ZSH_SETUP_PATH && source $HEROKU_AC_ZSH_SETUP_PATH;
            fi

            if [ ${ANDROID_FLG} -eq 1 ];then
                export ANDROID_HOME=$HOME/Library/Android/sdk && echo "ANDROID_HOME sets to $ANDROID_HOME"
                export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools:$PATH
            fi

            if [ ${EPUB_FLG} -eq 1 ];then
                export EPUBCHECKSYS=$HOME/Works/epub/tool/epubcheck
                export PATH=$EPUBCHECKSYS:$PATH
            fi

            [ "$PATH" = "$NO_DEV_PATH" ]||echo "PATH sets to $PATH"
            [ "$PYTHONPATH" = "$NO_DEV_PYTHONPATH" ]||echo "PYTHONPATH sets to $PYTHONPATH"
            [ "$LD_LIBRARY_PATH" = "$NO_DEV_LD_LIBRARY_PATH" ]||echo "LD_LIBRARY_PATH sets to $LD_LIBRARY_PATH"
        fi
    fi
fi
#EOF#