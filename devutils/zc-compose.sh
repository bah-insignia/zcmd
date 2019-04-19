#!/bin/bash
#Updated 20190417.1

source $HOME/zcmd/devutils/default-docker-env.txt

if [ $# -eq 0 ]; then
  echo "Missing action: up or down or pull" 
  exit 1
fi

ACTION="$1"
ECO="$2"
CMDARGS="$3"

ZCMD_LAUNCHDIR=$(pwd)
if [ -z "$CMDARGS" ]; then
    TXT_CMDARGS=""
else
    TXT_CMDARGS=" $CMDARGS"
    CMDARGS=" -f $2 "
fi
if [ -z "$CMDARGS" ]; then
    TXT_ECO=" default"
else
    TXT_ECO=" $ECO"
fi
echo "Compose ${ACTION}${TXT_CMDARGS}${TXT_ECO} stack at ${ZCMD_LAUNCHDIR} ..."

STACK_ENV_FILE=./stack.env

if [ ! -f "$STACK_ENV_FILE" ]; then
    echo "FOLDER: $ZCMD_LAUNCHDIR"
    echo "DID NOT FIND ${STACK_ENV_FILE}!"
    exit 2
fi

source $STACK_ENV_FILE

if [ ! -z "$ECO" ]; then
    #Add our override to the end
    if [ "$IS_PRODUCTION" = "YES" ]; then
        echo
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! NOT ALLOWED FOR PRODUCTION ENVIRONMENT !!!"
        echo "! You cannot declare a different environment context when on a production box!"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! NOT ALLOWED FOR PRODUCTION ENVIRONMENT !!!"
        echo
        exit 2
    fi
    PUSH_VARS="$PUSH_VARS ENVIRONMENT_CONTEXT='$ECO'"
fi

echo "... FOLDER=$ZCMD_LAUNCHDIR"
echo "... PUSH_VARS=$PUSH_VARS"

#LAUNCH THE STACK
cd $(pwd)
ACTIONCMD="$PUSH_VARS docker-compose $ACTION $CMDARGS"
echo $ACTIONCMD
if [ "up" = "$ACTION" ]; then
    eval "$PUSH_VARS docker-compose $ACTION $CMDARGS &"
else
    eval "$PUSH_VARS docker-compose $ACTION $CMDARGS"
fi

echo Listing of all current docker processes and their status...
docker ps -a
echo ".................................................................."
echo "To release stack resources, run zcmd down"
echo ".................................................................."

