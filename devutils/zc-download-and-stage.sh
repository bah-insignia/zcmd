#!/bin/bash
VERSIONINFO="20171222.1"

echo "Starting $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt
if [ -z "$LOADED_LIB_FIND_FILES" ]; then
    source $HOME/zcmd/devutils/function-library/find-files.bash
fi

function showUsage()
{
    echo "USAGE: $0 SOURCE_FILENAME TARGET_FOLDERNAME"
    echo "   SOURCE_FILENAME = Do NOT include absolute path; script will try local and then S3"
    echo "   TARGET_FOLDERNAME   = Where to expand the GZ/ZIP content into locally"
}

if [ -z "$1" ]; then
    echo "Missing SOURCE_FILENAME"
    showUsage
    exit 2
fi

if [ -z "$2" ]; then
    echo "Missing TARGET_FOLDERNAME"
    showUsage
    exit 2
fi

SOURCE_FILENAME="$1"
TARGET_FOLDERNAME="$2"

echo "... SOURCE_FILENAME=$SOURCE_FILENAME"
echo "... TARGET_FOLDERNAME=$TARGET_FOLDERNAME"

LOCAL_SOURCE_PATH="${LOCAL_VOLUMEDUMPS_FILEDIR}/${SOURCE_FILENAME}"
S3_SOURCE_PATH="${S3_VOLUMEDUMPS_FILEDIR}/${SOURCE_FILENAME}"

LOCAL_STAGE_UNCOMPRESSED_PATH="${LOCAL_VOLUMEDUMPS_FILEDIR}/uncompressed/${SOURCE_FILENAME}"

#Make sure we have our staging folders in place
DA_CHECK="$HOME/zcmd/devutils/zc-check-local-dumparea.sh"
eval $DA_CHECK

READY="NO"
HAVE_LOCAL_COMPRESSED="TBD"
HAVE_LOCAL_UNCOMPRESSED="TBD"
function checkUncompressedLocalExists()
{
    if [ -d "$LOCAL_STAGE_UNCOMPRESSED_PATH" ]; then
        READY="YES"
        HAVE_LOCAL_UNCOMPRESSED="YES"
    fi
}

function checkCompressedLocalExists()
{
    if [ ! -f "$LOCAL_SOURCE_PATH" ]; then
        HAVE_LOCAL_COMPRESSED="NO"
    else
        #Uncompress the local compressed file
        ($HOME/zcmd/devutils/zc-uncompress.sh $LOCAL_SOURCE_PATH $LOCAL_STAGE_UNCOMPRESSED_PATH)
        if [ $? -ne 0 ]; then
            echo "Failed uncompressing $LOCAL_SOURCE_PATH into $LOCAL_STAGE_UNCOMPRESSED_PATH"
            exit 2
        fi
        HAVE_LOCAL_COMPRESSED="YES"
    fi

    checkUncompressedLocalExists
}

function checkS3()
{
    #Download compressed file into local stage area
    ($HOME/zcmd/devutils/s3get-sudo.sh $S3_SOURCE_PATH $LOCAL_SOURCE_PATH)
    if [ $? -ne 0 ]; then
        echo "Failed getting $S3_SOURCE_PATH into $LOCAL_SOURCE_PATH"
        exit 2
    fi

    checkCompressedLocalExists
}

checkUncompressedLocalExists
if [ ! "YES" = "$HAVE_LOCAL_UNCOMPRESSED" ]; then
    checkCompressedLocalExists
    if [ ! "YES" = "$HAVE_LOCAL_COMPRESSED" ]; then
        checkS3
        checkCompressedLocalExists
        checkUncompressedLocalExists
    fi
fi

if [ "YES" = "$READY" ]; then
    echo "Ready at $TARGET_FOLDERNAME"
else
    echo "Failed!"
    exit 2
fi
