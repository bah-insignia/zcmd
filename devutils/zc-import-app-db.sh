#!/bin/bash
#DROPS ALL TABLES IN THE DATABASE AND RECREATES FROM THE SCHEMA AND DATA FILES
#WARNING: Do NOT alter the parameter calling convention unless you update
#         all existing application specific import scripts that depend on it.

VERSIONINFO="20180319.1"
echo "Started $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt
if [ -z "$LOADED_LIB_FIND_FILES" ]; then
    source $HOME/zcmd/devutils/function-library/find-files.bash
fi

PROJECTNAME=$1
DATABASE=$2
USERNAME=$3
PASSWORD=$4
HOST=$5
PORT=$6

DEFAULT_FILESUFFIX=""

LOCAL_APPUSER_NAME=appuser
LOCAL_APPUSER_PASSWORD=$PASSWORD

S3LISTER="$HOME/zcmd/devutils/s3listing.sh"
S3GETTER="$HOME/zcmd/devutils/s3get.sh"

S3FILEDIR="database-dumps"
FILEDIR="$LOCAL_DBDUMPS_FILEDIR"

echo "... PROJECTNAME=$PROJECTNAME"
echo "... DATABASE=$DATABASE"
echo "... HOST=$HOST"
echo "... PORT=$PORT"

function showUsage
{
    echo "USAGE: $0 PROJECT_NAME DATABASE_NAME USERNAME PASSWORD HOST PORT [SUFFIX]"
    echo "   PROJECT_NAME = Project name in stack.env"
    echo "   DATABASE_NAME = Database name in stack.env"
    echo "   USERNAME = for logging into the database"
    echo "   PASSWORD = for logging into the database"
    echo "   HOST = for logging into the database"
    echo "   PORT = for logging into the database"
    echo "   SUFFIX = Optional filename suffix for finding files; default is '$DEFAULT_FILESUFFIX'"
}

function checkSuccess()
{
    LABEL_TXT=$1
    CMD_STATUS="$2"
    CMD_TXT=$3

    ISOKAY="NO"
    if [ "$CMD_STATUS" = "0" ]; then
        ISOKAY="YES"
    fi
    if [ "$CMD_STATUS" = "" ]; then
        ISOKAY="YES"
    fi

    if [ "$ISOKAY" = "NO" ]; then
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "ERROR ON ${LABEL_TXT}!"
        echo "FAILED[$CMD_STATUS]: $CMD_TXT"
        exit 2
    fi    
    echo "[$CMD_STATUS] Successfully completed $LABEL_TXT"
}

if [ $# -lt 6 ]; then
    echo "ERROR: Missing required arguments!"
    showUsage
    exit 2
fi

if [ $# -lt 7 ]; then
  FILESUFFIX="$DEFAULT_FILESUFFIX"  
else
  FILESUFFIX="-$7"  
  echo "... using SUFFIX of $FILESUFFIX in the filenames"
fi

WILDCARD_MATCH="${FILEDIR}/${PROJECTNAME}*"

UNCOMPRESSED_SCHEMA_FILENAME="${PROJECTNAME}-schema${FILESUFFIX}.sql"
UNCOMPRESSED_DATA_FILENAME="${PROJECTNAME}${FILESUFFIX}.sql"

GZ_SCHEMA_FILENAME="${PROJECTNAME}-schema${FILESUFFIX}.sql.gz"
GZ_DATA_FILENAME="${PROJECTNAME}${FILESUFFIX}.sql.gz"

TAR_GZ_SCHEMA_FILENAME="${PROJECTNAME}-schema${FILESUFFIX}.sql.tar.gz"
TAR_GZ_DATA_FILENAME="${PROJECTNAME}${FILESUFFIX}.sql.tar.gz"

ZIP_SCHEMA_FILENAME="${PROJECTNAME}-schema${FILESUFFIX}.sql.zip"
ZIP_DATA_FILENAME="${PROJECTNAME}${FILESUFFIX}.sql.zip"

SCHEMA_PATH="${FILEDIR}/${UNCOMPRESSED_SCHEMA_FILENAME}"
DATA_PATH="${FILEDIR}/${UNCOMPRESSED_DATA_FILENAME}"

S3_SCHEMA_PATH="${S3FILEDIR}/${UNCOMPRESSED_SCHEMA_FILENAME}"
S3_DATA_PATH="${S3FILEDIR}/${UNCOMPRESSED_DATA_FILENAME}"

DOWNLOAD_FROM_BUCKET="TBD"
MISSING_FILE="TBD"
GOT_SCHEMAFILE="TBD"
GOT_DATAFILE="TBD"
FOUND_TYPE="TBD"

echo "#####################################################################"
echo "Listing of existing users on $DATABASE at host=$HOST port=$PORT ..."
CLEAN_CMD="mysql -u $USERNAME -pXXXXXXXXXXXXX --host=$HOST --port=$PORT -e 'select host,user from user order by user' mysql"
echo $CLEAN_CMD
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT -e 'select host,user from user order by user' mysql
CMD_STATUS=$?
checkSuccess "LIST USERS" "$CMD_STATUS" "MYSQL"
echo "Grants of root on $DATABASE at host=$HOST port=$PORT ..."
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT -e 'show grants for 'root'@'$HOST';' 2> /tmp/nul
echo "Grants of $LOCAL_APPUSER_NAME on $DATABASE at host=$HOST port=$PORT ..."
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT -e 'show grants for '$LOCAL_APPUSER_NAME'@'$HOST';' 2> /tmp/nul

function checkHostSQLNameLiterals()
{
    local SCHEMA_FILENAME=$1
    local DATA_FILENAME=$2

    echo "Checking for $SCHEMA_FILENAME and $DATA_FILENAME on host..."

    if [ -f "${FILEDIR}/$SCHEMA_FILENAME" ]; then
        echo "... found schema file in host: $SCHEMA_FILENAME"
        if [ ! -z "${FILEDIR}/$DATA_FILENAME" ]; then
            echo "... found data file in host: $DATA_FILENAME"
            GOT_SCHEMAFILE="YES"
            GOT_DATAFILE="YES"
            MISSING_FILE="NO"
            return 0
        else
            MISSING_FILE="YES"
            echo "... WARNING DID NOT FIND DATA FILE IN HOST!"
        fi
    fi
    return 1
}

function checkHostFiles()
{
    FOUND_TYPE="NONE"
    MISSING_FILE="CHECKING"
    GOT_SCHEMAFILE="NO"
    GOT_DATAFILE="NO"

    #CHECK HOST FOR UNCOMPRESSED FIRST!
    checkHostSQLNameLiterals ${UNCOMPRESSED_SCHEMA_FILENAME} ${UNCOMPRESSED_DATA_FILENAME}
    if [ ! $? -ne 0 ]; then
        FOUND_SCHEMA_FILENAME=${UNCOMPRESSED_SCHEMA_FILENAME}
        FOUND_DATA_FILENAME=${UNCOMPRESSED_DATA_FILENAME}
        FOUND_TYPE="UNCOMPRESSED"
    else
        #CHECK FOR COMPRESSED THEN UNCOMPRESSED AGAIN
        checkHostSQLNameLiterals ${GZ_SCHEMA_FILENAME} ${GZ_DATA_FILENAME}
        if [ ! $? -ne 0 ]; then
            FOUND_SCHEMA_FILENAME=${GZ_SCHEMA_FILENAME}
            FOUND_DATA_FILENAME=${GZ_DATA_FILENAME}
            FOUND_TYPE="GZ"
        else
            checkHostSQLNameLiterals ${ZIP_SCHEMA_FILENAME} ${ZIP_DATA_FILENAME}
            if [ ! $? -ne 0 ]; then
                FOUND_SCHEMA_FILENAME=${ZIP_SCHEMA_FILENAME}
                FOUND_DATA_FILENAME=${ZIP_DATA_FILENAME}
                FOUND_TYPE="ZIP"
            else
                checkHostSQLNameLiterals ${TAR_GZ_SCHEMA_FILENAME} ${TAR_GZ_DATA_FILENAME}
                if [ ! $? -ne 0 ]; then
                    FOUND_SCHEMA_FILENAME=${TAR_GZ_SCHEMA_FILENAME}
                    FOUND_DATA_FILENAME=${TAR_GZ_DATA_FILENAME}
                    FOUND_TYPE="TAR_GZ"
                fi
            fi
        fi

        if [ ! "NONE" = "$FOUND_TYPE" ]; then
            #UNCOMPRESS WHAT WE FOUND
            CMD="zc-uncompress.sh ${FILEDIR}/$FOUND_SCHEMA_FILENAME ${FILEDIR}"
            echo $CMD
            ($CMD)
            CMD_STATUS=$?
            if [ ! $CMD_STATUS -eq 0 ]; then
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "ERROR ON SCHEMA UNCOMPRESS of ${FILEDIR}/$FOUND_SCHEMA_FILENAME"
                echo "FAILED: $CMD"
                exit 2
            fi

            CMD="zc-uncompress.sh ${FILEDIR}/$FOUND_DATA_FILENAME ${FILEDIR}"
            echo $CMD
            ($CMD)
            CMD_STATUS=$?
            if [ ! $CMD_STATUS -eq 0 ]; then
                echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
                echo "ERROR ON DATA UNCOMPRESS of ${FILEDIR}/$FOUND_DATA_FILENAME"
                echo "FAILED: $CMD"
                exit 2
            fi

        fi

        checkHostSQLNameLiterals ${UNCOMPRESSED_SCHEMA_FILENAME} ${UNCOMPRESSED_DATA_FILENAME}
        if [ ! $? -ne 0 ]; then
            FOUND_SCHEMA_FILENAME=${UNCOMPRESSED_SCHEMA_FILENAME}
            FOUND_DATA_FILENAME=${UNCOMPRESSED_DATA_FILENAME}
            FOUND_TYPE="UNCOMPRESSED"
        fi
    fi

}

function checkS3SQLNameLiterals()
{
    BUCKETCONTENT=$1

    SCHEMA_FILENAME=$2
    DATA_FILENAME=$3

    echo "Checking for $SCHEMA_FILENAME and $DATA_FILENAME on S3..."

    GREP_SCHEMAFILE="echo \"${BUCKETCONTENT}\" | grep '${SCHEMA_FILENAME}'"
    GREP_DATAFILE="echo \"${BUCKETCONTENT}\" | grep '${DATA_FILENAME}'"

    FIND_SCHEMAFILE=$(eval "$GREP_SCHEMAFILE")
    FIND_DATAFILE=$(eval "$GREP_DATAFILE")

    if [ ! -z "$FIND_SCHEMAFILE" ]; then
        echo "... found schema file in bucket: $SCHEMA_FILENAME"
        if [ ! -z "$FIND_DATAFILE" ]; then
            echo "... found data file in bucket: $DATA_FILENAME"
            DOWNLOAD_FROM_BUCKET="ASK"
            echo "Found candidates in the S3 bucket!"
            return 0
        else
            echo "... DID NOT FIND DATA FILE IN BUCKET!"
        fi
    fi
    return 1
}

function checkS3()
{
    echo "Listing from $S3LISTER $S3FILEDIR/$PROJECTNAME"
    BUCKETCONTENT=$(eval "$S3LISTER $S3FILEDIR/$PROJECTNAME")
    checkSuccess "S3 LISTING" $? "$S3LISTER"

    echo "$BUCKETCONTENT"

    echo "Checking S3 for matching file names ..."

    FOUND_TYPE="NONE"
    checkS3SQLNameLiterals "$BUCKETCONTENT" ${GZ_SCHEMA_FILENAME} ${GZ_DATA_FILENAME}
    if [ ! $? -ne 0 ]; then
        FOUND_SCHEMA_FILENAME=${GZ_SCHEMA_FILENAME}
        FOUND_DATA_FILENAME=${GZ_DATA_FILENAME}
        FOUND_TYPE="GZ"
        DOWNLOAD_FROM_BUCKET="ASK"
    else
        checkS3SQLNameLiterals "$BUCKETCONTENT" ${ZIP_SCHEMA_FILENAME} ${ZIP_DATA_FILENAME}
        if [ ! $? -ne 0 ]; then
            FOUND_SCHEMA_FILENAME=${ZIP_SCHEMA_FILENAME}
            FOUND_DATA_FILENAME=${ZIP_DATA_FILENAME}
            FOUND_TYPE="ZIP"
            DOWNLOAD_FROM_BUCKET="ASK"
        else
            checkS3SQLNameLiterals "$BUCKETCONTENT" ${TAR_GZ_SCHEMA_FILENAME} ${TAR_GZ_DATA_FILENAME}
            if [ ! $? -ne 0 ]; then
                FOUND_SCHEMA_FILENAME=${TAR_GZ_SCHEMA_FILENAME}
                FOUND_DATA_FILENAME=${TAR_GZ_DATA_FILENAME}
                FOUND_TYPE="TAR_GZ"
                DOWNLOAD_FROM_BUCKET="ASK"
            else

                checkS3SQLNameLiterals "$BUCKETCONTENT" ${UNCOMPRESSED_SCHEMA_FILENAME} ${UNCOMPRESSED_DATA_FILENAME}
                if [ ! $? -ne 0 ]; then
                    FOUND_SCHEMA_FILENAME=${UNCOMPRESSED_SCHEMA_FILENAME}
                    FOUND_DATA_FILENAME=${UNCOMPRESSED_DATA_FILENAME}
                    FOUND_TYPE="UNCOMPRESSED"
                    DOWNLOAD_FROM_BUCKET="ASK"
                fi
            fi
        fi
    fi

    if [ "NONE" = "$FOUND_TYPE" ]; then
        echo
        echo "No file match found in S3!"
        echo
        DOWNLOAD_FROM_BUCKET="NONE"
    fi
}

function downloadFromS3()
{
    
    S3_SCHEMA_PATH="${S3FILEDIR}/${FOUND_SCHEMA_FILENAME}"
    S3_DATA_PATH="${S3FILEDIR}/${FOUND_DATA_FILENAME}"

    SCHEMA_PATH="${FILEDIR}/${FOUND_SCHEMA_FILENAME}"
    DATA_PATH="${FILEDIR}/${FOUND_DATA_FILENAME}"

    echo "Downloading $FOUND_TYPE $S3_SCHEMA_PATH schema file from S3 to host ..."
    lib_downloadFromS3 $S3_SCHEMA_PATH $SCHEMA_PATH
    #eval "$S3GETTER $S3_SCHEMA_PATH $SCHEMA_PATH"

    echo "Downloading $FOUND_TYPE $S3_DATA_PATH data file from S3 to host ..."
    lib_downloadFromS3 $S3_DATA_PATH $DATA_PATH
    #eval "$S3GETTER $S3_DATA_PATH $DATA_PATH"

    CMD="sudo chmod a+r '$SCHEMA_PATH'"
    echo $CMD
    eval $CMD
    CMD="sudo chmod a+r '$DATA_PATH'"
    echo $CMD
    eval $CMD

}

if [ -d "$FILEDIR" ]; then
    echo "folder $FILEDIR found."
else
    echo "folder $FILEDIR NOT found."
    echo "Will now attempt to create folder $FILEDIR"
    sudo mkdir -p $FILEDIR
    if [ ! -d "$FILEDIR" ]; then
        exit 2
    else
        sudo chmod 777 $FILEDIR
        echo "Successfully created $FILEDIR"
    fi
fi

checkHostFiles

#Show what is already downloaded to the host
echo "Local host listing of ${WILDCARD_MATCH} ..."
ls -la ${WILDCARD_MATCH}

#Are we missing files on the host?
if [ "NONE" = "$FOUND_TYPE" ]; then
    checkS3
    if [ "$DOWNLOAD_FROM_BUCKET" = "ASK" ]; then
        DOWNLOAD_FROM_BUCKET="YES"
    fi
    if [ "$DOWNLOAD_FROM_BUCKET" = "YES" ]; then
        downloadFromS3
        checkHostFiles
        if [ "NONE" = "$FOUND_TYPE" ]; then
                echo "Quiting because download failed!"
                exit 1
        fi
    else
        echo "Check available dump files to ensure the argument you pass matches a valid suffix!"
        echo "... if you pass no argument, then names assume no suffix before the '.sql'"
        echo "... if you pass an argument, the suffix is inserted into the name before the '.sql'"
        echo "Quiting because one or more files NOT FOUND!"
        exit 1
    fi
else
    echo "NOTE: Host already has files at ${FILEDIR}"
fi

#Good to load?    
if [ "NONE" = "$FOUND_TYPE" ]; then
    echo "#####################################################################"
    echo "$0 DID NOT LOAD DATABASE"
    echo "#####################################################################"
    exit 2
fi

#Try to load it now
FOUND_SCHEMA_PATH=${FILEDIR}/${FOUND_SCHEMA_FILENAME}
FOUND_DATA_PATH=${FILEDIR}/${FOUND_DATA_FILENAME}

CMD="sudo chmod a+r '$FOUND_SCHEMA_PATH'"
echo $CMD
eval $CMD
CMD="sudo chmod a+r '$FOUND_DATA_PATH'"
echo $CMD
eval $CMD

HAS_PV="YES"
lib_findRecommendedApp "pv" "pv app" "shows database load progress bar and percentage"
if [ $? -ne 0 ]; then
    HAS_PV="NO"
fi

#RESULT_TXT=$(which pv)
#RESULT_STATUS_CD=$?
#HAS_PV="YES"
#if [ $RESULT_STATUS_CD -ne 0 ]; then
#    HAS_PV="NO"
#    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#    echo "NO PROGRESS VIEWER INSTALLED: Consider running apt-get pv on your OS!"
#    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
#fi


echo " "
echo "#####################################################################"
echo "This will DROP ALL TABLES of ${HOST}:${PORT} in $DATABASE"
echo "... recreate schema from $FOUND_SCHEMA_PATH"
echo "... recreate data from $FOUND_DATA_PATH"
read -p "Press any key to continue (or CTRL-C to abort now)... " -n1 -s

echo "..."

#mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT $DATABASE < ${FAST_LOADING_FILEPATH}
echo "Will now DROP all the tables ..."
mysql --user=$USERNAME --password=$PASSWORD --host=$HOST --port=$PORT -BNe "show tables" $DATABASE | tr '\n' ',' | sed -e 's/,$//' | awk '{print "SET FOREIGN_KEY_CHECKS = 0;DROP TABLE IF EXISTS " $1 ";SET FOREIGN_KEY_CHECKS = 1;"}' | mysql --user=$USERNAME --password=$PASSWORD --host=$HOST --port=$PORT $DATABASE
echo "Drop done!"

echo " "
echo "#####################################################################"
echo "Issuing create database '$DATABASE' and user accounts in case not already created..."
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "CREATE DATABASE $DATABASE;"  2> /tmp/nul

#echo "Commands for root account..."
#ROOT_CREATEUSER1="CREATE USER '$USERNAME'@'%' IDENTIFIED BY '$PASSWORD';"
#ROOT_GRANTALL1="GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'%';"
#ROOT_CREATEUSER2="CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$PASSWORD';"
#ROOT_GRANTALL2="GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'localhost';"
#ROOT_CREATEUSER3="CREATE USER '$USERNAME'@'127.0.0.1' IDENTIFIED BY '$PASSWORD';"
#ROOT_GRANTALL3="GRANT ALL PRIVILEGES ON *.* TO '$USERNAME'@'127.0.0.1';"

#mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$ROOT_CREATEUSER1"
#mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$ROOT_CREATEUSER2"
#mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$ROOT_CREATEUSER3"
#mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$ROOT_GRANTALL1"
#mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$ROOT_GRANTALL2"
#mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$ROOT_GRANTALL3"

echo "Commands for 'appuser' account..."
APPUSER_CREATEUSER2="CREATE USER 'appuser'@'localhost' IDENTIFIED BY '$LOCAL_APPUSER_PASSWORD';"
APPUSER_CREATEUSER3="CREATE USER 'appuser'@'127.0.0.1' IDENTIFIED BY '$LOCAL_APPUSER_PASSWORD';"
APPUSER_CREATEUSER1="CREATE USER 'appuser'@'%' IDENTIFIED BY '$LOCAL_APPUSER_PASSWORD';"

APPUSER_REV1="revoke all privileges on $DATABASE.* from '$LOCAL_APPUSER_NAME'@'localhost';"
APPUSER_REV1="revoke all privileges on $DATABASE.* from '$LOCAL_APPUSER_NAME'@'127.0.0.1';"
APPUSER_REV1="revoke all privileges on $DATABASE.* from '$LOCAL_APPUSER_NAME'@'%';"

APPUSER_GRANTALL2="GRANT ALL PRIVILEGES ON $DATABASE.* TO '$LOCAL_APPUSER_NAME'@'localhost';"
APPUSER_GRANTALL3="GRANT ALL PRIVILEGES ON $DATABASE.* TO '$LOCAL_APPUSER_NAME'@'127.0.0.1';"
APPUSER_GRANTALL1="GRANT ALL PRIVILEGES ON $DATABASE.* TO '$LOCAL_APPUSER_NAME'@'%';"

#GRANT ALL ON my_db.* TO 'new_user'@'localhost';

#GRANT ALL PRIVILEGES ON `local_searchexperiment`.* TO 'root'@'127.0.0.1'
#GRANT ALL PRIVILEGES ON database_name.* TO 'username'@'localhost';

FLUSHCMD="FLUSH PRIVILEGES;"

mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$APPUSER_CREATEUSER1" 2>/dev/null
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$APPUSER_CREATEUSER2" 2>/dev/null
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$APPUSER_CREATEUSER3" 2>/dev/null
sleep 1
echo "$APPUSER_GRANTALL2"
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$APPUSER_GRANTALL2" 2>/dev/null
echo "$APPUSER_GRANTALL3"
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$APPUSER_GRANTALL3" 2>/dev/null
echo "$APPUSER_GRANTALL1"
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$APPUSER_GRANTALL1" 
sleep 1

echo "$FLUSHCMD"
mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT  -e "$FLUSHCMD"
sleep 1

echo "#####################################################################"
echo
echo "Starting schema rebuild from $FOUND_SCHEMA_PATH"
TOP_CMD="sed -n 1,10p $FOUND_SCHEMA_PATH"
echo "TOP FEW LINES: $TOP_CMD"
($TOP_CMD)
TAIL_CMD="tail $FOUND_SCHEMA_PATH"
echo "LAST FEW LINES: $TAIL_CMD"
($TAIL_CMD)
echo "mysql -u $USERNAME --host=$HOST --port=$PORT $DATABASE ... < ${FOUND_SCHEMA_PATH}"
if [ "$HAS_PV" = "NO" ]; then
    mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT $DATABASE < ${FOUND_SCHEMA_PATH}
else
    pv ${FOUND_SCHEMA_PATH} | mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT $DATABASE
fi
if [ $? -ne 0 ]; then
    echo "FAILED SCHEMA IMPORT from ${FOUND_SCHEMA_PATH}"
    exit 2
fi
echo "FINISHED mysql -u $USERNAME ... < ${FOUND_SCHEMA_PATH}"

echo "#####################################################################"
echo
echo "Starting data load from $FOUND_DATA_PATH"
TOP_CMD="sed -n 1,10p $FOUND_DATA_PATH"
echo "TOP FEW LINES: $TOP_CMD"
($TOP_CMD)
TAIL_CMD="tail $FOUND_DATA_PATH"
echo "LAST FEW LINES: $TAIL_CMD"
($TAIL_CMD)
#Make fast loading file
FAST_LOADING_FILEPATH="${FOUND_DATA_PATH}.fastloading"
echo "set autocommit=0;" > $FAST_LOADING_FILEPATH
cat ${FOUND_DATA_PATH} >> $FAST_LOADING_FILEPATH
echo "       " >> $FAST_LOADING_FILEPATH
echo "COMMIT;" >> $FAST_LOADING_FILEPATH
echo "#END OF FASTLOADING SQL FILE" >> $FAST_LOADING_FILEPATH
echo "mysql -u $USERNAME ... --host=$HOST --port=$PORT $DATABASE < ${FOUND_DATA_PATH}"
if [ "$HAS_PV" = "NO" ]; then
    mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT $DATABASE < ${FAST_LOADING_FILEPATH}
else
    pv ${FAST_LOADING_FILEPATH} | mysql -u $USERNAME -p$PASSWORD --host=$HOST --port=$PORT $DATABASE
fi
if [ $? -ne 0 ]; then
    echo "FAILED DATA IMPORT from ${FAST_LOADING_FILEPATH}"
    exit 2
fi
rm $FAST_LOADING_FILEPATH
echo "FINISHED mysql -u $USERNAME ... < ${FOUND_DATA_PATH}"

echo "#####################################################################"
echo "Completed $0"
