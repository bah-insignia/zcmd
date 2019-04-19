#!/bin/bash
#Pass in volume names, one name per argument.

VERSIONINFO="20180109.1"

echo "Starting $0 v$VERSIONINFO ..."

source $HOME/zcmd/devutils/default-docker-env.txt
source $HOME/zcmd/devutils/function-library/permissions.bash

if [ $# -eq 0 ]; then
  echo "WARNING:$0 expects at least one volume name!  Nothing to check!"
  exit 1
fi

THE_VOLUME_UTIL="$HOME/zcmd/devutils/zc-docker-volume.sh"

MISSING_VOLUMES=""
FOUND_PATHS=""

HAS_ERRORS="TBD"
HAS_WARNINGS="TBD"

function checkVolume()
{
    local VOLUMENAME=$1
    CMD="$THE_VOLUME_UTIL $VOLUMENAME CHECK_EXISTS QUIET"
    eval $CMD
    CMD_STATUS=$?
    if [ ! $CMD_STATUS -eq 0 ]; then
        MISSING_VOLUMES="$VOLUMENAME $MISSING_VOLUMES"
        echo "MISSING volume $VOLUMENAME"
    else
        CMD="$THE_VOLUME_UTIL $VOLUMENAME SHOWINFO"
        eval $CMD
        #echo "VOLUME NAME: $VOLUMENAME"
        #VOLUME_PATH=`docker volume inspect $VOLUMENAME | grep "Mountpoint" | awk '/"(.*)"/ { gsub(/"/,"",$2); print $2 }' | sed "s/,//g"`
        #FOUND_PATHS="$FOUND_PATHS $VOLUME_PATH"
        #echo "... mount point=$VOLUME_PATH"
        #checkFiles $VOLUME_PATH
    fi

}

function createMissingVolumes()
{
    #Reset the error flag
    #local HAS_ERRORS="TBD"

    read -n1 -p "QUESTION: Use softlinks (where recommended) from docker volume [Y,n,q=quit]" doit 
    echo
    case $doit in  
      y|Y) CREATE_ACTION_TYPE="SOFTLINK" ;; 
      n|N) CREATE_ACTION_TYPE="DIRECT" ;; 
      q|Q) CREATE_ACTION_TYPE="ABORT" ;; 
      *) CREATE_ACTION_TYPE="SOFTLINK" ;; 
    esac

    echo "..."
    if [ "ABORT" = $CREATE_ACTION_TYPE ]; then
        echo "Quiting the script now without creating volumes!"
        exit 1;
    fi

    echo "..."
    if [ "ABORT" = $CREATE_ACTION_TYPE ]; then
        echo "Quiting the script now without creating volumes!"
        exit 1;
    fi

    for VOLUMENAME in $MISSING_VOLUMES
    do
        VCMD="docker volume create $VOLUMENAME"
        #echo "$VCMD"
        eval $VCMD
        if [ $? -ne 0 ]; then
            HAS_ERRORS="YES"
        fi
        CMD_GREP_NOSOFTLINK="echo '$VOLUME_INSTALL_DEFAULT_NOSOFTLINK' | grep '$VOLUMENAME'"
        #echo $CMD_GREP_NOSOFTLINK
        FIND_NAME_TEXT=$(eval "$CMD_GREP_NOSOFTLINK")
        if [ "SOFTLINK" = $CREATE_ACTION_TYPE ]; then
            if [ ! -z "$FIND_NAME_TEXT" ]; then
                echo "Leaving volume '$VOLUMENAME' not-softlinked'"
            else
                VCMD="$THE_VOLUME_UTIL $VOLUMENAME CHANGE_INTO_SOFTLINK"
                eval $VCMD
                if [ $? -ne 0 ]; then
                    HAS_ERRORS="YES"
                fi
            fi
        fi
    done
}

echo "Checking docker volumes ..."

for vname in "$@"
do
    checkVolume $vname
done

#checkVolume "unrealname"

if [ ! -d "$DOCKER_PATH_SOFTLINK_VOLUMES" ]; then
    mkdir -p "$DOCKER_PATH_SOFTLINK_VOLUMES"
    echo "Created $DOCKER_PATH_SOFTLINK_VOLUMES"
fi
lib_ensureDirPermissions775 $DOCKER_PATH_SOFTLINK_VOLUMES

if [ ! -z "$MISSING_VOLUMES" ]; then
    echo "---------------------------- ATTENTION ------------------------------------"
    HAS_ERRORS="YES"
    #echo "MISSING $MISSING_VOLUMES"
    read -n1 -p "QUESTION: Create empty docker volumes now? [Y,n]" doit 
    echo
    case $doit in  
      y|Y) createMissingVolumes ;; 
      n|N) echo " ... SKIPPING CREATE" ;; 
      *) createMissingVolumes ;; 
    esac
    echo
fi

if [ "YES" = "$HAS_ERRORS" ]; then
    #Failed if we are here
    echo "################################################################################"
    echo "Found one ore more DOCKER VOLUME configuration errors"
    echo "################################################################################"
    exit 2
fi

echo "################################################################################"
echo "No docker volume configuration errors detected"
echo "################################################################################"

exit 0



