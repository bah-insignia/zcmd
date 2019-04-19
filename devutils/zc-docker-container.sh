#!/bin/bash
VERSIONINFO="$0 v20171229.1"

THEUTIL="$HOME/zcmd/devutils/zc-docker-volume.sh"

source $HOME/zcmd/devutils/default-docker-env.txt

VALID_COMMANDS="IS_RUNNING_WILDCARD IS_RUNNING_EXACT"
function showUsage()
{
    echo "################################################################################"
    echo "USAGE: $0 ACTION_COMMAND CONTAINER_NAME"
    echo "  ACTION_COMMAND choices = $VALID_COMMANDS"
    echo "TIP: Get listing of all running with 'docker container ls'"
    echo "################################################################################"
}

if [ -z "$1" ]; then
    echo "Expected a ACTION_COMMAND argument!"
    showUsage
    exit 2
fi
ACTION_COMMAND=$1

if [ -z "$2" ]; then
    echo "Expected a CONTAINER_NAME argument!"
    showUsage
    exit 2
fi
CONTAINER_NAME=$2

#Get the grep results
CMD_DOCKER="docker container ls"
CMD_AWK="awk '{print \$NF}'"
CMD_GREP="grep '$CONTAINER_NAME'"
CMD2RUN="$CMD_DOCKER | $CMD_AWK | $CMD_GREP"
echo "$CMD2RUN"
CMD_RESULT=$(eval $CMD2RUN)
echo "$CMD_RESULT"

if [ "IS_RUNNING_WILDCARD" = "$ACTION_COMMAND" ]; then
    if [ -z "$CMD_RESULT" ]; then
        echo "RESULT: Did not find running container with match on $CONTAINER_NAME"
        exit 1
    else
        echo "RESULT: Found running container with match on $CONTAINER_NAME"
        exit 0
    fi
fi

if [ "IS_RUNNING_EXACT" = "$ACTION_COMMAND" ]; then
    if [ "$CMD_RESULT" = "$CONTAINER_NAME" ]; then
        echo "RESULT: Did not find running container with exact match on $CONTAINER_NAME"
        exit 1
    else
        echo "RESULT: Found running container with exact match on $CONTAINER_NAME"
        exit 0
    fi
fi


#If we are here, we failed to process the command
echo "Did NOT recognize command '$ACTION_COMMAND'!"
showUsage
exit 2
