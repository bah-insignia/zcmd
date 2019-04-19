#MUST ALREADY HAVE default env sourced!

LIBNAME="FIND-FILES"
VERSIONINFO="20171229.1"

if [ -z "$LOADED_LIB_FIND_FILES" ]; then
    echo "#Loaded function-library $LIBNAME v$VERSIONINFO"
fi
LOADED_LIB_FIND_FILES="YES"

if [ -z "$DEFAULT_ENV_VERSIONINFO" ]; then
    echo "MUST LOAD DEFAULT ENVIRONMENT FIRST!"
    exit 2
fi

function lib_fileExistsOnLocal()
{
    #ZERO on found, else NONZERO return
    FILEPATH=$1
    if [ -z "$FILEPATH" ]; then
        echo "MISSING FILEPATH FOR STAGE CHECK!"
        exit 2
    fi

    if [ -f "$FILEPATH" ]; then
        return 0
    else
        return 1
    fi
}

function lib_fileExistsOnS3()
{
    #ZERO on found, else NONZERO return
    FILEKEY=$1
    if [ -z "$FILEKEY" ]; then
        echo "MISSING FILEKEY FOR S3 CHECK!"
        exit 2
    fi

    S3LISTER="$HOME/zcmd/devutils/s3listing.sh"

    BUCKETCONTENT=$(eval "$S3LISTER $FILEKEY")
    GREP_FILE="echo \"${BUCKETCONTENT}\" | awk '{print \$NF}' | grep '${FILEKEY}'"
    FIND_FILE=$(eval "$GREP_FILE")

    if [ ! -z "$FIND_FILE" ]; then
        return 0
    fi
    return 1
}

function lib_downloadFromS3()
{
    #ZERO on found, else NONZERO return
    FILEKEY=$1
    TARGET_PATH=$2
    if [ -z "$TARGET_PATH" ]; then
        echo "MISSING TARGET_PATH FOR '$FILEKEY' S3 DOWNLOAD!"
        exit 2
    fi

    S3GETTER="$HOME/zcmd/devutils/s3get-sudo.sh"

    echo "Dowloading $FILEKEY file from S3 to $TARGET_PATH ..."

    eval "$S3GETTER $FILEKEY $TARGET_PATH"
    CMD_STATUS=$?
    if [ $CMD_STATUS -ne 0 ]; then
        echo "Failed getting '$FILEKEY' into local '$TARGET_PATH'!"
        exit 2
    fi

    return 0
}

function lib_findRequiredApp
{
    local APP_FILENAME=$1
    local APP_LABEL=$2
    local IMPACT=$3
    local HAS_ERRORS="NO"

    which $APP_FILENAME > /tmp/nul
    local RESULT_STATUS_CD=$?
    if [ $RESULT_STATUS_CD -ne 0 ]; then
        echo "ERROR: Missing required $APP_LABEL! (filename $APP_FILENAME)"
        if [ ! -z "$IMPACT" ]; then
            echo "--- APP PURPOSE: $IMPACT"
        fi
        HAS_ERRORS="YES"
    else
        echo "FOUND REQUIRED APP: $APP_LABEL"
        APP_VERSIONINFO=$($APP_FILENAME --version | awk 'NR==1{print $0}')
        if [ ! -z "$APP_VERSIONINFO" ]; then
            echo "... VERSIONINFO: $APP_VERSIONINFO" 
        fi
    fi

    if [ "YES" = "$HAS_ERRORS" ]; then
        return 2
    fi

    return 0
}

function lib_findRecommendedApp
{
    local APP_FILENAME=$1
    local APP_LABEL=$2
    local IMPACT=$3
    local HAS_WARNINGS="NO"

    which $APP_FILENAME > /tmp/nul
    local RESULT_STATUS_CD=$?
    if [ $RESULT_STATUS_CD -ne 0 ]; then
        echo "WARNING: Missing recommended $APP_LABEL! (filename $APP_FILENAME)"
        if [ ! -z "$IMPACT" ]; then
            echo "--- APP PURPOSE: $IMPACT"
        fi
        HAS_WARNINGS="YES"
    else
        echo "FOUND RECOMMENDED APP: $APP_LABEL ($APP_FILENAME)"
        APP_VERSIONINFO=$($APP_FILENAME --version  2> /tmp/nul | awk 'NR==1{print $0}') 
        if [ ! -z "$APP_VERSIONINFO" ]; then
            echo "... VERSIONINFO: $APP_VERSIONINFO" 
        fi
    fi

    if [ "YES" = "$HAS_WARNINGS" ]; then
        return 1
    fi

    return 0

}
