#!/bin/bash
#DROPS ALL TABLES IN THE DATABASE AND RECREATES FROM THE SCHEMA AND DATA FILES
#WARNING: Do NOT alter the parameter calling convention unless you update
#         all existing application specific import scripts that depend on it.

VERSIONINFO="20171229.1"
echo "Started $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt

PROJECTNAME=$1
VOLUME_NAME=$2

THEUTIL="$HOME/zcmd/devutils/zc-docker-volume.sh"
S3LISTER="~/zcmd/devutils/s3listing.sh"
S3GETTER="~/zcmd/devutils/s3get-sudo.sh"

#S3FILEDIR="$S3_VOLUMEDUMPS_FILEDIR"
S3FILEDIR="$S3_ASSETDUMPS_FILEDIR"
FILEDIR="$LOCAL_VOLUMEDUMPS_FILEDIR"

DEFAULT_CUSTOM_FILESUFFIX="dev"

ZIP_FILESUFFIX="zip"
GZ_FILESUFFIX="tar.gz"

function showUsage
{
    echo "USAGE: $0 PROJECT_NAME VOLUME_NAME [SUFFIX]"
    echo "   PROJECT_NAME = Name of the project in stack.env"
    echo "   VOLUME_NAME = Name as shown by docker volume ls"
    echo "   SUFFIX = Optional filename suffix for finding files; default is '$DEFAULT_CUSTOM_FILESUFFIX'"
}

if [ $# -lt 2 ]; then
    echo "ERROR: Missing required volume name!"
    showUsage
    echo "Possible choices ..."
    CMD1="docker volume ls"
    ALL_VOLUMES=$($CMD1)
    #echo $ALL_VOLUMES
    (echo "$ALL_VOLUMES" | grep "$PROJECTNAME")
    exit 2
fi

if [ $# -lt 3 ]; then
  RAW_FILESUFFIX=$DEFAULT_CUSTOM_FILESUFFIX  
else
  RAW_FILESUFFIX="$3"  
  echo "... using SUFFIX of '$RAW_FILESUFFIX' in the filenames"
fi
FILESUFFIX="-$RAW_FILESUFFIX"  

WILDCARD_MATCH="${FILEDIR}/${PROJECTNAME}*"

ZIP_ASSETS_FILENAME="${PROJECTNAME}-assets${FILESUFFIX}.${ZIP_FILESUFFIX}"
GZ_ASSETS_FILENAME="${PROJECTNAME}-assets${FILESUFFIX}.${GZ_FILESUFFIX}"

SOURCE_ZIP_ASSETS_PATH="${FILEDIR}/${ZIP_ASSETS_FILENAME}"
SOURCE_GZ_ASSETS_PATH="${FILEDIR}/${GZ_ASSETS_FILENAME}"

S3_SOURCE_ZIP_ASSETS_PATH="${S3FILEDIR}/${ZIP_ASSETS_FILENAME}"
S3_SOURCE_GZ_ASSETS_PATH="${S3FILEDIR}/${GZ_ASSETS_FILENAME}"

LOCAL_COMPRESSED_ASSETS_SOURCEFILE_NAME="TBD"
LOCAL_COMPRESSED_ASSETS_SOURCEFILE_PATH="TBD"

DOWNLOAD_FROM_BUCKET="TBD"

MISSING_FILE="TBD"

GOT_ZIP_ASSETS_FILE="TBD"
GOT_GZ_ASSETS_FILE="TBD"
COMPRESSED_ASSET_FILE_TYPE="TBD"

HOST_PATH="TBD"
ASSETS_HOST_PATH="TBD"

ZIP_ASSETS_HOST_PATH="TBD"
GZ_ASSETS_HOST_PATH="TBD"

function getHostPath()
{
    CMD="$THEUTIL $VOLUME_NAME JUST_GET_HOST_PATH"
    HOST_PATH="$(eval $CMD)"
    if [ ! -d "$HOST_PATH" ]; then
        CMD="ls -la"
        echo "$CMD"
        ($CMD)
        echo "ERROR: Did NOT find usable host path for volume $VOLUME_NAME"
        exit 2
    fi
    ASSETS_HOST_PATH="$HOST_PATH/sites/default/files"
}

getHostPath

TIMESTAMP=$(date +"%Y_%m_%d")

echo "... PROJECTNAME=$PROJECTNAME"
echo "... VOLUME_NAME=$VOLUME_NAME"
echo "... FILESUFFIX='$RAW_FILESUFFIX'"
echo "... ASSETS_HOST_PATH='$ASSETS_HOST_PATH'"

echo "#####################################################################"

function checkHostFilesStagingArea()
{
    MISSING_FILE="CHECKING"
    GOT_ZIP_ASSETS_FILE="NO"
    GOT_GZ_ASSETS_FILE="NO"
    COMPRESSED_ASSET_FILE_TYPE="CHECKING"

    if [ -f "$SOURCE_ZIP_ASSETS_PATH" ]; then
        echo "$SOURCE_ZIP_ASSETS_PATH found on host."
        GOT_ZIP_ASSETS_FILE="YES"
        COMPRESSED_ASSET_FILE_TYPE="ZIP"
        LOCAL_COMPRESSED_ASSETS_SOURCEFILE_PATH="$SOURCE_ZIP_ASSETS_PATH"
        LOCAL_COMPRESSED_ASSETS_SOURCEFILE_NAME="$ZIP_ASSETS_FILENAME"
        MISSING_FILE="NO"
    fi

    if [ -f "$SOURCE_GZ_ASSETS_PATH" ]; then
        echo "$SOURCE_GZ_ASSETS_PATH found on host."
        GOT_GZ_ASSETS_FILE="YES"
        COMPRESSED_ASSET_FILE_TYPE="GZ"
        LOCAL_COMPRESSED_ASSETS_SOURCEFILE_PATH="$SOURCE_GZ_ASSETS_PATH"
        LOCAL_COMPRESSED_ASSETS_SOURCEFILE_NAME="$GZ_ASSETS_FILENAME"
        MISSING_FILE="NO"
    fi

    if [ "CHECKING" = "$MISSING_FILE" ]; then
        COMPRESSED_ASSET_FILE_TYPE="NONE_ON_HOST"
        MISSING_FILE="YES"
        echo "$SOURCE_ZIP_ASSETS_PATH NOT found on host."
        echo "$SOURCE_GZ_ASSETS_PATH NOT found on host."
    fi
}

function checkS3()
{
    local FILENAME=$1

    BUCKETCONTENT=$(eval "$S3LISTER $S3FILEDIR/$PROJECTNAME")
    echo "Listing from $S3LISTER $S3FILEDIR/$PROJECTNAME"
    echo "$BUCKETCONTENT"

    echo "Checking S3 for matching file names ..."

    GREP_ASSETS_FILE="echo \"${BUCKETCONTENT}\" | grep '${FILENAME}'"
    FIND_ASSETS_FILE=$(eval "$GREP_ASSETS_FILE")

    if [ ! -z "$FIND_ASSETS_FILE" ]; then
        echo "... found settings file in bucket: $FILENAME"
        DOWNLOAD_FROM_BUCKET="ASK"
        echo "Found candidate in the S3 bucket!"
    fi
    if [ ! "ASK" = "$DOWNLOAD_FROM_BUCKET" ]; then
            echo "Match not found in S3!"
    fi
}

function downloadFromS3()
{
    COMPRESSED_ASSETS_FILENAME=$1

    LOCAL_COMPRESSED_ASSETS_SOURCEFILE_PATH="${FILEDIR}/${COMPRESSED_ASSETS_FILENAME}"
    S3_SOURCE_COMPRESSED_ASSETS_PATH="${S3FILEDIR}/${COMPRESSED_ASSETS_FILENAME}"

    echo "Dowloading $S3_SOURCE_COMPRESSED_ASSETS_PATH schema file from S3 to host ..."
    eval "$S3GETTER $S3_SOURCE_COMPRESSED_ASSETS_PATH $LOCAL_COMPRESSED_ASSETS_SOURCEFILE_PATH"
}

if [ -d "$FILEDIR" ]; then
    echo "folder $FILEDIR found."
else
    echo "folder $FILEDIR NOT found."
    #Attempt to create it now with user account
    mkdir -p "$FILEDIR"
    if [ -d "$FILEDIR" ]; then
        echo "Created staging folder $FILEDIR"
    else
        echo "------------------ ATTENTION ----------------------------------------"
        echo "The following folder must exist and be writable by your account ..."
        echo "   $FILEDIR"
        echo "Please create it before running this script again."
        echo "------------------ ATTENTION ----------------------------------------"
        exit 1
    fi
fi

checkHostFilesStagingArea

#Show what is already downloaded to the host
echo "Local host listing of ${WILDCARD_MATCH} ..."
ls -la ${WILDCARD_MATCH}

#Are we missing files on the host?
if [ "YES" = "$MISSING_FILE" ]; then
    checkS3 $GZ_ASSETS_FILENAME
    if [ "$DOWNLOAD_FROM_BUCKET" = "ASK" ]; then
        DOWNLOAD_FROM_BUCKET="YES"
    fi
    if [ "$DOWNLOAD_FROM_BUCKET" = "YES" ]; then
        downloadFromS3 $GZ_ASSETS_FILENAME
        checkHostFilesStagingArea $GZ_ASSETS_FILENAME
        if [ "YES" = "$MISSING_FILE" ]; then
            echo "Quiting because download failed!"
            exit 1
        fi
        GOT_ZIP_ASSETS_FILE="NO"
        GOT_GZ_ASSETS_FILE="YES"
        COMPRESSED_ASSET_FILE_TYPE="GZ"
    else
        checkS3 $ZIP_ASSETS_FILENAME
        if [ "$DOWNLOAD_FROM_BUCKET" = "ASK" ]; then
            DOWNLOAD_FROM_BUCKET="YES"
        fi
        if [ "$DOWNLOAD_FROM_BUCKET" = "YES" ]; then
            downloadFromS3 $ZIP_ASSETS_FILENAME
            checkHostFilesStagingArea $ZIP_ASSETS_FILENAME
            if [ "YES" = "$MISSING_FILE" ]; then
                echo "Quiting because download failed!"
                exit 1
            fi
            GOT_ZIP_ASSETS_FILE="YES"
            GOT_GZ_ASSETS_FILE="GZ"
            COMPRESSED_ASSET_FILE_TYPE="ZIP"
        fi
    fi
    if [ ! "$DOWNLOAD_FROM_BUCKET" = "YES" ]; then
        showUsage
        (eval $S3LISTER | grep "$PROJECTNAME")
        echo "------------------ ATTENTION ----------------------------------------"
        echo "Check available dump files to ensure the argument you pass matches a valid suffix!"
        echo "... if you pass an argument, the suffix is inserted into the name before type suffix"
        echo "Quiting because one or more files NOT FOUND!"
        echo "------------------ ATTENTION ----------------------------------------"
        exit 1
    fi
fi

ASSETS_EXIST="TBD"
function checkExistingAssetsPath()
{
    if [ "" = "$ASSETS_HOST_PATH" ]; then
        echo "ERROR: BLANK ASSETS_HOST_PATH!"
        exit 2
    fi

    if [ -d "$ASSETS_HOST_PATH" ]; then
        ASSET_EXIST="YES"
    else
        ASSETS_EXIST="NO"
        echo "Creating ASSETS_HOST_PATH for $VOLUME_NAME"
        mkdir -p "$ASSETS_HOST_PATH"
    fi
}

checkExistingAssetsPath

echo "..."

#Install the asset file content
TARGET_PATH="$ASSETS_HOST_PATH"
SOURCE_PATH="$LOCAL_COMPRESSED_ASSETS_SOURCEFILE_PATH"

echo " "
echo "#####################################################################"
echo "ASSETS INSTALLATION"
echo "... into $TARGET_PATH"
echo "... from $SOURCE_PATH"

if [ ! "NO" = "$ASSETS_EXIST" ]; then
    echo " "
    echo "#####################################################################"
    echo "This will REPLACE your asset files in $VOLUME_NAME"
    read -p "Press any key to continue (or CTRL-C to abort now)... " -n1 -s
fi

TMP_STAGE_TARGET_PATH="/tmp/stage/import-assets/$TIMESTAMP"

CMD="zc-uncompress.sh $SOURCE_PATH $TMP_STAGE_TARGET_PATH"
echo $CMD
($CMD)
CMD_STATUS=$?
if [ ! $CMD_STATUS -eq 0 ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "ERROR ON UNCOMPRESS!"
    echo "FAILED: $CMD"
    exit 2
fi

COPYFROM="TBD"
if [ -d "$TMP_STAGE_TARGET_PATH/files" ]; then
    COPYFROM="$TMP_STAGE_TARGET_PATH/files/"
else
    if [ -d "$TMP_STAGE_TARGET_PATH/sites/default/files" ]; then
        COPYFROM="$TMP_STAGE_TARGET_PATH/sites/default/files/"
    else
        COPYFROM="$TMP_STAGE_TARGET_PATH/"
        echo "Treating all files at root of the compressed file as assets"
    fi
fi
#echo "TODO COPYFROM $COPYFROM"
#echo "TODO INTO $TARGET_PATH"
if [ ! -d "$TARGET_PATH" ]; then
    CMD_MKDIR="sudo mkdir -p $TARGET_PATH"
    echo $CMD_MKDIR
    ($CMD_MKDIR)
fi
CMD_RSYNC="sudo rsync -vrah $COPYFROM $TARGET_PATH"
($CMD_RSYNC)
CMD_STATUS=$?
if [ ! $CMD_STATUS -eq 0 ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "ERROR ON RSYNC!"
    echo "FAILED: $CMD_RSYNC"
    exit 2
fi
echo "Completed $CMD_RSYNC"

#Clean up our staging files now
rm -rf $TMP_STAGE_TARGET_PATH

echo "Installed ${TARGET_PATH}"

echo "#####################################################################"
echo "Completed $0"
