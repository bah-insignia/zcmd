#!/bin/bash
#Version 20181227.1

if [ $# -eq 0 ]; then
  echo "Missing python script name!" 
  exit 1
fi

PYTHON_SCRIPT_NAME=$1

PYTHON_SCRIPT_DIR="$HOME/zcmd/devutils/zcmd_python/stack"

#Assumes was launched from a stack folder
ZCMD_LAUNCHDIR=$(pwd)

#Show a helpful message
if [ $# -eq 1 ]; then
  echo "Launch $PYTHON_SCRIPT_NAME at ${ZCMD_LAUNCHDIR} ..."
  CMDARGS=""
else
  echo "Launch $PYTHON_SCRIPT_NAME $2 $3 $4 $5 $6 at ${ZCMD_LAUNCHDIR} ..."
  CMDARGS=" $2 $3 $4 $5 $6"
fi

#Source the stack environment file
STACK_ENV_FILE=./stack.env
if [ ! -f "$STACK_ENV_FILE" ]; then
    echo "FOLDER: $ZCMD_LAUNCHDIR"
    echo "DID NOT FIND ${STACK_ENV_FILE}!"
    exit 2
fi
source $STACK_ENV_FILE

RUNTIME_CONTAINERNAME="TBD"
source $HOME/zcmd/devutils/function-library/docker.bash
lib_getRuntimeWebContainerName
DOCKER_WEBSERVER="$RUNTIME_CONTAINERNAME"

echo "... FOLDER=$ZCMD_LAUNCHDIR"
echo "... PUSH_VARS=$PUSH_VARS"

MOREPUSHVARS=""
if [ ! -z "${DOCKER_WEBSERVER}" ]; then
    MOREPUSHVARS="DOCKER_WEBSERVER=${DOCKER_WEBSERVER}"
fi

#LAUNCH THE STACK
cd $(pwd)
eval "$PUSH_VARS $MOREPUSHVARS python3 ${PYTHON_SCRIPT_DIR}/${PYTHON_SCRIPT_NAME} $CMDARGS"
EC=$?

echo ".................................................................."
echo "LAUNCH DONE with exit code $EC"
echo ".................................................................."
if [ $EC -ne 0 ]; then
    exit $EC
fi

