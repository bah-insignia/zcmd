#!/bin/bash
VERSIONINFO="$0 v20180312.1"

source $HOME/zcmd/devutils/default-docker-env.txt
source $HOME/zcmd/devutils/function-library/permissions.bash

#EXIT CODE SUCCESS = 0
#EXIT CODE FAILED  = 1
#EXIT CODE ERROR   = 2

VALID_COMMANDS="CHECK_EXISTS CHECK_IS_SOFTLINK CHANGE_INTO_SOFTLINK JUST_GET_HOST_PATH SHOWINFO"

function showUsage()
{
    echo "################################################################################"
    echo "USAGE: $0 VOLUME_NAME ACTION_COMMAND"
    echo "  ACTION_COMMAND choices = $VALID_COMMANDS"
    echo "TIP: Get listing of all volume names with 'docker volume ls'"
    echo "################################################################################"
}

if [ -z "$1" ]; then
    echo "Expected a VOLUME NAME argument!"
    showUsage
    exit 1
fi
VOLUME_NAME=$1

if [ -z "$2" ]; then
    ACTION="SHOWINFO"
else
    ACTION=$2
    GREP_FOUND="$(echo "$VALID_COMMANDS" | grep "$ACTION")"
    if [ -z "$GREP_FOUND" ]; then
        showUsage
        #Continue with and report warning at the end
    fi
fi

if [ "JUST_GET_HOST_PATH" = "$ACTION" ]; then
    RUN_QUIET="YES"
else
    RUN_QUIET="NO"
    if [ ! -z "$3" ]; then
        if [ "QUIET" = "$3" ]; then
            RUN_QUIET="YES"
        fi
    fi
fi

VOLUME_EXISTS="TBD"
HOST_PATH="TBD"
VOLUME_IS_SOFTLINK="TBD"
SOFTLINK_TARGET_INFO="NONE"
FOLDER_CONTENT_COUNT="NOT COUNTED"

function showMessage()
{
    MSG=$1
    if [ "NO" = $RUN_QUIET ]; then
        echo $MSG
    fi
}

function showError()
{
    MSG=$1
    echo "ERROR: $MSG"
}

function checkVolumeExists()
{
    #Grep in way that smartly avoids substring errors
    VOLUME_EXISTS="NO"
    GREP_FOUND="$(docker volume ls | awk '{print $NF}' | grep $VOLUME_NAME)"
    for ONEVOLUMENAME in $GREP_FOUND
    do
        if [ "$ONEVOLUMENAME" = "$VOLUME_NAME" ]; then
            VOLUME_EXISTS="YES"
        fi
        #echo "CHECK $ONEVOLUMENAME = $VOLUME_NAME is $VOLUME_EXISTS"
   done
}

function checkVolumeIsSoftlink()
{
    if [ "YES" = $VOLUME_EXISTS ]; then
        local LIST_CMD="${DOCKER_RUN_MAGIC_TERMINAL_CMD} ls -la ${DOCKER_PATH_VOLUMES_IN_MAGIC_TERMINAL}/$VOLUME_NAME/_data"
        local FIND_TEXT="$VOLUME_NAME/_data -"
        GREP_FOUND="$($LIST_CMD | grep $FIND_TEXT)"
        if [ -z "$GREP_FOUND" ]; then
            VOLUME_IS_SOFTLINK="NO"
            HOST_PATH="${DOCKER_PATH_VOLUMES_LINUX}/${VOLUME_NAME}/_data"
        else
            VOLUME_IS_SOFTLINK="YES"
            SOFTLINK_TARGET_INFO="$GREP_FOUND"
            local MAGIC_PATH_CMD="${DOCKER_RUN_MAGIC_TERMINAL_CMD} readlink -n ${DOCKER_PATH_VOLUMES_IN_MAGIC_TERMINAL}/$VOLUME_NAME/_data"
            #echo "MAGIC COMMAND=$MAGIC_PATH_CMD"
            #HOST_PATH=$(echo "$GREP_FOUND" | tr -d '[:cntrl:]' | tr -d '[:cntrl:]' | awk '{print $NF}')
            HOST_PATH="$($MAGIC_PATH_CMD)"
            lib_ensureDirPermissions775 $HOST_PATH
        fi
    else
        VOLUME_IS_SOFTLINK="NOT APPLICABLE"
    fi
    #echo "LIST_CMD=$LIST_CMD"
    #echo "FIND_TEXT=$FIND_TEXT"
    #echo "GREP_FOUND=$GREP_FOUND"
    #echo "VOLUME_IS_SOFTLINK=$VOLUME_IS_SOFTLINK"
}

function changeVolumeIntoSoftlink()
{
    if [ "NO" = $VOLUME_IS_SOFTLINK ]; then
        local TARGET_PATH=$1
        local MAKE_TARGET_CMD="mkdir ${TARGET_PATH}"
        local RENAME_CMD="${DOCKER_RUN_MAGIC_TERMINAL_CMD} mv /docker/var/lib/docker/volumes/$VOLUME_NAME/_data /docker/var/lib/docker/volumes/$VOLUME_NAME/old_data"
        local LN_CMD="${DOCKER_RUN_MAGIC_TERMINAL_CMD} ln -s $TARGET_PATH /docker/var/lib/docker/volumes/$VOLUME_NAME/_data"

        if [ ! -d "$TARGET_PATH" ]; then
            eval "$MAKE_TARGET_CMD"
            echo "... Created $TARGET_PATH"
        fi
        echo "... RENAMING existing _data : $RENAME_CMD" 
        eval "$RENAME_CMD" 
        echo "... CREATING SOFTLINK to $TARGET_PATH" 
        eval "$LN_CMD"
    fi

    checkVolumeIsSoftlink
    if [ "NO" = $VOLUME_IS_SOFTLINK ]; then
        echo "ERROR: FAILED TO CONVERT _data of volume $VOLUME_NAME into a SOFTLINK to ${TARGET_PATH}!"
        exit 2
    fi

}

function countHostPathContent()
{
    VOLUME_PATH=$1

    local LIST_CMD="ls -lR $VOLUME_PATH"
    local COUNT_CMD="${LIST_CMD} | wc -l"

    #echo "LIST COMMAND: $LIST_CMD"
    #echo "COUNT COMMAND: $COUNT_CMD"

    FOLDER_CONTENT=$(eval $LIST_CMD)

    #echo "LOOK CONTENT: $FOLDER_CONTENT"

    FOLDER_CONTENT_COUNT=$(eval $COUNT_CMD)
}

function countMagicTerminalContent()
{
    #THE VOLUME CANNOT FOLLOW SYMLINK INTO HOST OS SO DO NOT USE THIS FUNCTION!!
    VOLUME_PATH=$1

    local LIST_CMD="${DOCKER_RUN_MAGIC_TERMINAL_CMD} ls -lR $VOLUME_PATH"
    local COUNT_CMD="${LIST_CMD} | wc -l"

    echo "LIST COMMAND: $LIST_CMD"
    echo "COUNT COMMAND: $COUNT_CMD"

    FOLDER_CONTENT=$(eval $LIST_CMD)

    #echo "LOOK CONTENT: $FOLDER_CONTENT"

    FOLDER_CONTENT_COUNT=$(eval $COUNT_CMD)
}

function softlinkRecommended()
{
    local CHECKVOLUMENAME=$1

    CMD_GREP_NOSOFTLINK="echo '$VOLUME_INSTALL_DEFAULT_NOSOFTLINK' | grep '$CHECKVOLUMENAME'"

    #echo "LOOK GREP THING: $CMD_GREP_NOSOFTLINK"
    FIND_NAME_TEXT=$(eval "$CMD_GREP_NOSOFTLINK")
    #echo "LOOK GREP RESULT: $FIND_NAME_TEXT"
    if [ -z "$FIND_NAME_TEXT" ]; then
        #Softlink for this volume IS recommended
        return 1
    else
        #Softlink for this volume is NOT recommended
        return 0
    fi
}

checkVolumeExists
checkVolumeIsSoftlink

#Exist result check
if [ "CHECK_EXISTS" = $ACTION ]; then
    if [ "NO" = $VOLUME_EXISTS ]; then
        showMessage "MISSING VOLUME $VOLUME_NAME"
        #FAILED
        exit 1
    else
        showMessage "Found volume $VOLUME_NAME"
        #SUCCESS
        exit 0
    fi
fi

#Softlink result check
if [ "CHECK_IS_SOFTLINK" = $ACTION ]; then
    if [ "NO" = $VOLUME_EXISTS ]; then
        showError "ERROR no volume $VOLUME_NAME"
        exit 2
    fi
    if [ "NO" = $VOLUME_IS_SOFTLINK ]; then
        showMessage "No softlink found for volume $VOLUME_NAME"
        #FAILED
        exit 1
    else
        showMessage "Found softlink for volume $VOLUME_NAME"
        #SUCCESS
        exit 0
    fi
fi

#Change to softlink
if [ "CHANGE_INTO_SOFTLINK" = $ACTION ]; then

    if [ "NO" = $VOLUME_EXISTS ]; then
        showError "ERROR no volume $VOLUME_NAME"
        exit 2
    fi

    if [ "YES" = $VOLUME_IS_SOFTLINK ]; then
        showError "ERROR volume $VOLUME_NAME is already SOFTLINKED!"
        exit 2
    fi

    TARGET_PATH="${DOCKER_PATH_SOFTLINK_VOLUMES}/${VOLUME_NAME}"
    changeVolumeIntoSoftlink $TARGET_PATH
    #If we are here, then we have success!
    showMessage "Converted volume $VOLUME_NAME to use $TARGET_PATH"
    #SUCCESS
    exit 0
fi

#Now, set the host path and check it.
if [ ! -d "$HOST_PATH" ]; then
    if [ -L "$HOST_PATH" ]; then
        echo
        echo "NOTE: Found additional indirection at PATH=$HOST_PATH"
        CMD_NAMEI="sudo namei -o $HOST_PATH | grep -- '->'"
        echo $CMD_NAMEI
        eval $CMD_NAMEI
        echo
    else
        echo "VOLUME NAME: $VOLUME_NAME"
        echo "ERROR: The volume path is not a reachable directory on the host!"
        echo "       PATH=$HOST_PATH"
        echo "       Check permissions for that path!"
        ls -la "$HOST_PATH"
        exit 2
    fi
fi

if [ "JUST_GET_HOST_PATH" = $ACTION ]; then
    echo "$HOST_PATH"
    #We will output nothing else, SUCCESS now
    exit 0;
fi

#We are here so just so show info about the volume name provided
echo "VOLUME NAME: $VOLUME_NAME"
echo "... volume exists : $VOLUME_EXISTS"
if [ "YES" = $VOLUME_EXISTS ]; then
    showMessage "...  is softlinked     : $VOLUME_IS_SOFTLINK"
    if [ "YES" = "$VOLUME_IS_SOFTLINK" ]; then
        showMessage "......  filesystem     : $SOFTLINK_TARGET_INFO"
        #CANNOT FOLLOW SYMLINK TO HOST countMagicTerminalContent "${DOCKER_PATH_VOLUMES_IN_MAGIC_TERMINAL}/$VOLUME_NAME/_data/"
        countHostPathContent "${HOST_PATH}/"
    else
        showMessage "......  filesystem     : $HOST_PATH"
        #countHostPathContent "${HOST_PATH}/"
        countMagicTerminalContent "${DOCKER_PATH_VOLUMES_IN_MAGIC_TERMINAL}/$VOLUME_NAME/_data/"
    fi

    softlinkRecommended "$VOLUME_NAME"
    if [ $? -ne 0 ]; then
        showMessage "... softlink recommended : YES"
    else
        showMessage "... softlink recommended : NO"
    fi

    showMessage "... content count        : $FOLDER_CONTENT_COUNT"
fi

#Trap case where command was not executed
if [ ! "SHOWINFO" = $ACTION ]; then
    if [ ! "" = $ACTION ]; then
        showError "ERROR: Did NOT recognize action command '$ACTION'!"
        exit 2
    fi
fi

#We are here then we had success
exit 0
