#!/bin/bash
#DROPS ALL TABLES IN THE DATABASE AND RECREATES FROM THE SCHEMA AND DATA FILES
#WARNING: Do NOT alter the parameter calling convention unless you update
#         all existing application specific import scripts that depend on it.

VERSIONINFO="20190515.1"
echo "Started $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt

PROJECTNAME=$1
SOURCE_DOCROOT_PATH=$2

# S3LISTER="~/zcmd/devutils/s3listing.sh"
# S3GETTER="~/zcmd/devutils/s3get-sudo.sh"

function showUsage
{
    echo "PURPOSE: Use aws sync to export drupal asset files to s3"
    echo "USAGE: $0 PROJECT_NAME SOURCE_DOCROOT_PATH [SUFFIX]"
    echo "   PROJECT_NAME = Project name in stack.env"
    echo "   SOURCE_PATH = Where we get the files"
    echo "   SUFFIX = Suffix constructing the name of the asset file folder on S3"
    echo
    echo "NOTE S3 FOLDER NAME LOGIC: PROJECT_NAME-assets-SUFFIX"
    echo
}

if [ $# -lt 2 ]; then
    echo "ERROR: Missing required SOURCE_DOCROOT_PATH!"
    showUsage
    exit 1
fi

if [ ! -d "${SOURCE_DOCROOT_PATH}" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "FATAL ERROR -- Invalid SOURCE_DOCROOT_PATH!"
    echo "            ${SOURCE_DOCROOT_PATH}"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 2
fi


function getHostPath()
{
    ASSETS_HOST_PATH="${SOURCE_DOCROOT_PATH}/sites/default/files"
}

getHostPath

# echo $ASSETS_HOST_PATH

TIMESTAMP=$(date +"%Y_%m_%d")

S3_DIRECTORY_NAME="$PROJECTNAME-assets-$ENVIRONMENT_NAME"

S3_URI="$SHARED_S3_ASSETS_BUCKET"

S3_ASSET_SYNC_FULLDIR="${S3_DIRECTORY_NAME}"

S3_TARGET="${S3_URI}/${S3_ASSET_SYNC_FULLDIR}"
SOURCE_PATH="$ASSETS_HOST_PATH"
TARGET_PATH="$S3_TARGET"

echo " "
echo "ASSETS EXPORT"
echo "... from $SOURCE_PATH"
echo "... into $TARGET_PATH"

echo

CMD_S3="aws s3 sync ${ASSETS_HOST_PATH} ${S3_TARGET} --delete"
echo
echo "SYNC CMD: $CMD_S3"

echo " "
echo "#####################################################################"
echo "This will REPLACE the asset files in $S3_TARGET"
read -p "Press any key to continue (or CTRL-C to abort now)... " -n1 -s
echo

#Sync the files to S3 bucket now
echo "Syncing our $ASSETS_HOST_PATH into ${S3_TARGET}"
($CMD_S3)
CMD_STATUS=$?
if [ $CMD_STATUS -ne 0 ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "ERROR: Failed to sync ${ASSETS_HOST_PATH} from ${S3_TARGET}!"
    echo "THE FAILED SYNC CMD: $CMD_S3"
    echo "THE EXIT CODE: $CMD_STATUS"
    echo "TIP: Check permissions of target folder."
    exit $CMD_STATUS
fi

echo "Exported to ${TARGET_PATH}"

echo "#####################################################################"
echo "Completed $0"
