#!/bin/bash

VERSIONINFO="20171229.1"

echo "Starting $0 v$VERSIONINFO ..."

source $HOME/zcmd/devutils/default-docker-env.txt

HAS_ERRORS="TBD"
HAS_WARNINGS="TBD"

function ensureCorrectDirOwner()
{
    DIR=$1
    CORRECT_OWNER=$2

    CMD_CHECKOWNER="ls -la $DIR | grep $CORRECT_OWNER | awk '{print \$3}'"
    THEOWNERGREP=$(eval "$CMD_CHECKOWNER")
    #echo "$THEOWNER = ($CMD_CHECKOWNER)"
    if [ -z "$THEOWNERGREP" ]; then
        echo "Changing ownership of $DIR to $CORRECT_OWNER"
        sudo chown -R $CORRECT_OWNER:$CORRECT_OWNER $DIR
    fi
}

function showDirOwner()
{
    local DIRPATH=$1
    local DIRNAME=$(basename "$DIRPATH")

    #echo "DIRPATH=$DIRPATH"
    #echo "DIRNAME=$DIRNAME"

    if [ -z "$DIRPATH" ]; then
        echo "INTERNAL ERROR --- NO DIRPATH PROVIDED!"
        return 2
    fi

    CMD_CHECKOWNER="ls -la ${DIRPATH}/.. | grep '${DIRNAME}' | awk '{print \$3}'"
    CMD_CHECKGROUP="ls -la ${DIRPATH}/.. | grep '${DIRNAME}' | awk '{print \$4}'"

    #echo "CMD_CHECKOWNER=$CMD_CHECKOWNER"

    THEOWNERGREP=$(eval "$CMD_CHECKOWNER")
    THEGROUPGREP=$(eval "$CMD_CHECKGROUP")

    echo "... owner: $THEOWNERGREP"
    echo "... group: $THEGROUPGREP"
}

function ensureCorrectDirPermissions()
{
    local DIRPATH=$1
    local DIRNAME=$(basename "$DIRPATH")

    local SEE_EXPECTED_PERM="drwxrwxr-x"
    local SET_EXPECTED_PERM="775"

    #echo "DIRPATH=$DIRPATH"
    #echo "DIRNAME=$DIRNAME"

    if [ -z "$DIRPATH" ]; then
        echo "INTERNAL ERROR --- NOT DIRPATH PROVIDED!"
        return 2
    fi

    CMD_GET_PERMISSIONS="ls -la ${DIRPATH}/.. | grep '${DIRNAME}' | awk '{print \$1}'"
    CMD_CHECK_PERMISSIONS="${CMD_GET_PERMISSIONS} | grep '$SEE_EXPECTED_PERM'"

    #echo "###CMD_GET_PERMISSIONS=$CMD_GET_PERMISSIONS"
    #echo "###CMD_CHECK_PERMISSIONS=$CMD_CHECK_PERMISSIONS"

    THE_PERM_GET=$(eval "$CMD_GET_PERMISSIONS")
    THE_PERM_CHECK_GREP=$(eval "$CMD_CHECK_PERMISSIONS")

    #echo ">>>CHECK PERM CMD=$CMD_CHECK_PERMISSIONS"

    echo "... current permissions: $THE_PERM_GET"
    if [ -z "$THE_PERM_CHECK_GREP" ]; then
        #Has different permissions -- change them
        echo "...... Expected $SEE_EXPECTED_PERM"
        CMD="sudo chmod $SET_EXPECTED_PERM $DIRPATH"
        echo "$CMD"
        eval "$CMD"
        if [ $? -ne 0 ]; then
            echo "...... FAILED to update permissions!"
            HAS_ERRORS="YES"
        else
            echo "...... Updated permissions"
        fi
    fi

}

function checkLocalStageArea()
{

    WHOAMI=$(whoami)

    echo "Checking $LOCAL_DUMPS_ROOTDIR"
    if [ ! -d "$LOCAL_DUMPS_ROOTDIR" ]; then
        echo "Creating $LOCAL_DUMPS_ROOTDIR"
        sudo mkdir -p "$LOCAL_DUMPS_ROOTDIR"
    fi
    if [ ! -d "$LOCAL_DUMPS_ROOTDIR" ]; then
        echo "Failed creating $LOCAL_DUMPS_ROOTDIR"
        HAS_ERRORS="YES"
        #NO POINT CONTINUING IF THE ROOT IS MISSING!!!!
        exit 2
    fi
    showDirOwner "$LOCAL_DUMPS_ROOTDIR"
    ensureCorrectDirPermissions "$LOCAL_DUMPS_ROOTDIR"

    echo "Checking $LOCAL_DBDUMPS_FILEDIR"
    if [ ! -d "$LOCAL_DBDUMPS_FILEDIR" ]; then
        echo "Creating $LOCAL_DBDUMPS_FILEDIR"
        sudo mkdir -p "$LOCAL_DBDUMPS_FILEDIR"
    fi
    if [ ! -d "$LOCAL_DBDUMPS_FILEDIR" ]; then
        echo "Failed creating $LOCAL_DBDUMPS_FILEDIR"
        HAS_ERRORS="YES"
    fi
    showDirOwner $LOCAL_DBDUMPS_FILEDIR $WHOAMI
    ensureCorrectDirPermissions $LOCAL_DBDUMPS_FILEDIR $WHOAMI

    echo "Checking $LOCAL_VOLUMEDUMPS_FILEDIR"
    if [ ! -d "$LOCAL_VOLUMEDUMPS_FILEDIR" ]; then
        echo "Creating $LOCAL_VOLUMEDUMPS_FILEDIR"
        sudo mkdir -p "$LOCAL_VOLUMEDUMPS_FILEDIR"
    fi
    if [ ! -d "$LOCAL_VOLUMEDUMPS_FILEDIR" ]; then
        echo "Failed creating $LOCAL_VOLUMEDUMPS_FILEDIR"
        HAS_ERRORS="YES"
    fi
    showDirOwner $LOCAL_VOLUMEDUMPS_FILEDIR $WHOAMI
    ensureCorrectDirPermissions $LOCAL_VOLUMEDUMPS_FILEDIR $WHOAMI

    echo "Checking $LOCAL_ASSETDUMPS_FILEDIR"
    if [ ! -d "$LOCAL_ASSETDUMPS_FILEDIR" ]; then
        echo "Creating $LOCAL_ASSETDUMPS_FILEDIR"
        sudo mkdir -p "$LOCAL_ASSETDUMPS_FILEDIR"
    fi
    if [ ! -d "$LOCAL_ASSETDUMPS_FILEDIR" ]; then
        echo "Failed creating $LOCAL_ASSETDUMPS_FILEDIR"
        HAS_ERRORS="YES"
    fi
    showDirOwner $LOCAL_ASSETDUMPS_FILEDIR $WHOAMI
    ensureCorrectDirPermissions $LOCAL_ASSETDUMPS_FILEDIR $WHOAMI

    echo "Checking $LOCAL_CONFIGDUMPS_FILEDIR"
    if [ ! -d "$LOCAL_CONFIGDUMPS_FILEDIR" ]; then
        echo "Creating $LOCAL_CONFIGDUMPS_FILEDIR"
        sudo mkdir -p "$LOCAL_CONFIGDUMPS_FILEDIR"
    fi
    if [ ! -d "$LOCAL_CONFIGDUMPS_FILEDIR" ]; then
        echo "Failed creating $LOCAL_CONFIGDUMPS_FILEDIR"
        HAS_ERRORS="YES"
    fi
    showDirOwner $LOCAL_CONFIGDUMPS_FILEDIR $WHOAMI
    ensureCorrectDirPermissions $LOCAL_CONFIGDUMPS_FILEDIR $WHOAMI
}

checkLocalStageArea

if [ "YES" = "$HAS_ERRORS" ]; then
    #Failed if we are here
    echo "################################################################################"
    echo "Found one ore more local stage/dump area configuration errors"
    echo "################################################################################"
    exit 2
fi

#Success if we are here
echo "################################################################################"
echo "No local stage/dump area configuration errors detected"
echo "################################################################################"
exit 0

    


