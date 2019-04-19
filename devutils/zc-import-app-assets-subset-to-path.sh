#!/bin/bash
#DROPS ALL TABLES IN THE DATABASE AND RECREATES FROM THE SCHEMA AND DATA FILES
#WARNING: Do NOT alter the parameter calling convention unless you update
#         all existing application specific import scripts that depend on it.

VERSIONINFO="20190122.1"
echo "Started $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt

PROJECTNAME=$1
TARGET_DOCROOT_PATH=$2
RAWSUFFIX=$3

S3LISTER="~/zcmd/devutils/s3listing.sh"
S3GETTER="~/zcmd/devutils/s3get-sudo.sh"

function showUsage
{
    echo "PURPOSE: Use aws sync to install drupal asset files into local target"
    echo "USAGE: $0 PROJECT_NAME TARGET_DOCROOT_PATH [SUFFIX]"
    echo "   PROJECT_NAME = Project name in stack.env"
    echo "   TARGET_PATH = Where we will place the files"
    echo "   SUFFIX = Suffix constructing the name of the asset file folder on S3"
    echo
    echo "NOTE S3 FOLDER NAME LOGIC: PROJECT_NAME-assets-SUFFIX"
    echo
}

if [ $# -lt 2 ]; then
    echo "ERROR: Missing required TARGET_DOCROOT_PATH!"
    showUsage
    exit 1
fi

if [ -z "$RAWSUFFIX" ]; then
    echo "ERROR: Missing required suffix param!"
    showUsage
    exit 1
fi

if [ ! -d "${TARGET_DOCROOT_PATH}" ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "FATAL ERROR -- Invalid TARGET_DOCROOT_PATH!"
    echo "            ${TARGET_DOCROOT_PATH}"
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 2
fi


function getHostPath()
{
    ASSETS_HOST_PATH="${TARGET_DOCROOT_PATH}/sites/default/files"
}

getHostPath

TIMESTAMP=$(date +"%Y_%m_%d")

S3_DIRECTORY_NAME="$PROJECTNAME-assets-$RAWSUFFIX"

S3_URI="$SHARED_S3_ASSETS_BUCKET"

S3_ASSET_SYNC_FULLDIR="${S3_DIRECTORY_NAME}"

S3_SOURCE="${S3_URI}/${S3_ASSET_SYNC_FULLDIR}"
TARGET_PATH="$ASSETS_HOST_PATH"
SOURCE_PATH="$S3_SOURCE"

echo " "
echo "ASSETS INSTALLATION"
echo "... into $TARGET_PATH"
echo "... from $SOURCE_PATH"

echo
echo "CHECKING SOURCE EXISTS..."
GREP=" | grep 'dumps'"
#IMPORTANT TO PUT THE SLASH AT THE START and END FOR THE GREP CHECK!!!!!!!!!!!!!!
CMD_GREPEXISTS="aws s3 ls ${S3_SOURCE} --recursive | grep '$S3_ASSET_SYNC_FULLDIR/'"
GREPEXISTS_RESULT=$(eval "$CMD_GREPEXISTS")
if [ -z "$GREPEXISTS_RESULT" ]; then
    echo
    echo "ERROR: There is no content at $SOURCE_PATH"
    echo "       We abort now otherwise all target content would be deleted!"
    echo "NOTE: Tested with command $CMD_GREPEXISTS"
    echo
    exit 111
fi
echo "FOUND SOURCE CONTENT!"

EXCLUDE_CACHE="--exclude 'css/css_*.css' --exclude 'js/js_*.js'"
EXCLUDE_DOCS="--exclude '*.pdf' --exclude '*.doc*' --exclude '*.xls*'"
EXCLUDE_VIDS="--exclude '*.webm' --exclude '*.avi' --exclude '*.mov' --exclude '*.qt' --exclude '*.wmv' --exclude '*.asf' --exclude '*.mpg' --exclude '*.mpeg' --exclude '*.mpv' --exclude '*.mp4' --exclude '*.flv'"
CMD_S3="aws s3 sync ${S3_SOURCE} ${ASSETS_HOST_PATH} --delete $EXCLUDE_CACHE $EXCLUDE_DOCS $EXCLUDE_VIDS"
echo
echo "SYNC CMD: $CMD_S3"

echo " "
echo "#####################################################################"
echo "This will REPLACE your asset files in $TARGET_DOCROOT_PATH"
read -p "Press any key to continue (or CTRL-C to abort now)... " -n1 -s
echo

#Sync the files to S3 bucket now
echo "Syncing our $S3_SOURCE into ${ASSETS_HOST_PATH}"
($CMD_S3)
CMD_STATUS=$?
if [ $CMD_STATUS -ne 0 ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "ERROR: Failed to sync ${ASSETS_HOST_PATH} from ${S3_SOURCE}!"
    echo "THE FAILED SYNC CMD: $CMD_S3"
    echo "THE EXIT CODE: $CMD_STATUS"
    echo "TIP: Check permissions of target folder."
    exit $CMD_STATUS
fi

echo "Installed ${TARGET_PATH}"

echo "#####################################################################"
echo "Completed $0"
