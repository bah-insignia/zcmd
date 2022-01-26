#!/bin/bash

VERSIONINFO="20171229.1"

echo "Starting $0 v$VERSIONINFO ..."

source $HOME/zcmd/devutils/default-docker-env.txt
if [ -z "$LOADED_LIB_FIND_FILES" ]; then
    source $HOME/zcmd/devutils/function-library/find-files.bash
fi

HAS_ERRORS="TBD"
HAS_WARNINGS="TBD"

WHOAMI=$(whoami)

function showUsage()
{
    echo "USAGE: $0 [OPTIONS]"
    echo "OPTIONS"
    echo "   --help - Shows this information"

}

if [ "$1" = "--help" ]; then
    showUsage
    exit 1
fi

function findRequiredApp
{
    local APP_FILENAME=$1
    local APP_LABEL=$2
    local IMPACT=$3

    lib_findRequiredApp $APP_FILENAME $APP_LABEL $IMPACT
    if [ $? -ne 0 ]; then
        HAS_ERRORS="YES"
    fi
}

function findRecommendedApp
{
    local APP_FILENAME=$1
    local APP_LABEL=$2
    local IMPACT=$3

    lib_findRecommendedApp $APP_FILENAME $APP_LABEL $IMPACT
    if [ $? -ne 0 ]; then
        HAS_WARNINGS="YES"
    fi
}

#Check the apps now
#Look for required apps on the path
findRequiredApp "docker" "docker application" "required for host to interact with docker resources"
findRequiredApp "docker compose" "docker compose client" "required for host to launch runtime stacks"
findRequiredApp "mysql" "mysql client" "required for the host to load the database"

#Look for recommended apps on the path
findRecommendedApp "pv" "pv application" "pv enables display of load progress"
findRecommendedApp "tar" "tar application" "tar enables decompression of tar.gz files"
findRecommendedApp "gzip" "gzip application" "gzip enables decompression of gz files"
findRecommendedApp "unzip" "unzip application" "unzip enables decompression of zip files"

if [ "YES" = "$HAS_WARNINGS" ]; then
    #Failed if we are here
    echo "################################################################################"
    echo "Found one or more application WARNINGS"
    echo "################################################################################"
    read -p "Are you sure you want to proceed? y/N " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "TREATING THESE WARNINGS AS ERRORS!"
        exit 2
    fi
    echo "Proceeding..."
fi

#Success if we are here
echo "################################################################################"
echo "No application errors detected"
echo "################################################################################"

if [ "YES" = "$HAS_WARNINGS" ]; then
    echo "FINAL NOTE: Exit code set to warning value"
    exit 1
fi

#No warnings, no errors.
exit 0

    


