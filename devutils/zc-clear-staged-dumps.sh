#!/bin/bash

VERSIONINFO="20171229.1"

echo "Starting $0 ..."

source $HOME/zcmd/devutils/default-docker-env.txt


function showPurpose()
{
    echo
    echo "STAGING AREA PURPOSE"
    echo "The staging area is used as a cache for installing images and other container"
    echo "content.  Feel free to clear this cache if you want to pull new copies from"
    echo "the remote sources."
    echo
}

function clearLocalStagingAreas()
{
    echo
    echo "### CLEARING START ##################################################################"
    echo "Clearing $LOCAL_DBDUMPS_FILEDIR"
    if [ ! -d "$LOCAL_DBDUMPS_FILEDIR" ]; then
        echo "-- Missing $LOCAL_DBDUMPS_FILEDIR"
    else
        (cd "$LOCAL_DBDUMPS_FILEDIR" && rm -Rf -- *) 
    fi

    echo "Clearing $LOCAL_VOLUMEDUMPS_FILEDIR"
    if [ ! -d "$LOCAL_VOLUMEDUMPS_FILEDIR" ]; then
        echo "-- Missing $LOCAL_VOLUMEDUMPS_FILEDIR"
    else
        (cd "$LOCAL_VOLUMEDUMPS_FILEDIR" && rm -Rf -- *) 
    fi

    echo "Clearing $LOCAL_CONFIGDUMPS_FILEDIR"
    if [ ! -d "$LOCAL_CONFIGDUMPS_FILEDIR" ]; then
        echo "-- Missing $LOCAL_CONFIGDUMPS_FILEDIR"
    else
        (cd "$LOCAL_CONFIGDUMPS_FILEDIR" && rm -Rf -- *) 
    fi

    echo "Clearing $LOCAL_ASSETDUMPS_FILEDIR"
    if [ ! -d "$LOCAL_ASSETDUMPS_FILEDIR" ]; then
        echo "-- Missing $LOCAL_ASSETDUMPS_FILEDIR"
    else
        (cd "$LOCAL_ASSETDUMPS_FILEDIR" && rm -Rf -- *) 
    fi
    echo "### CLEARING DONE ##################################################################"
    echo

}

showPurpose
clearLocalStagingAreas

echo "Done!"

exit 0



