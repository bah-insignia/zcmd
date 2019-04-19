#!/bin/bash
VERSIONINFO=20190416.1
echo "Starting $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt

function showUsage()
{
	echo "USAGE: $0 REPO_NAME"
	echo "Pick a REPO_NAME value from the list shown here ..."
	ssh git@${GIT_REPO_HOST_NAME}
}

REPO_NAME=$1
if [ -z "$REPO_NAME" ]; then
	showUsage
	exit 2
fi

CMD="git clone --recurse-submodules git@${GIT_REPO_HOST_NAME}:${REPO_NAME}"
echo $CMD
eval $CMD
RC=$?
if [ $RC -ne 0 ]; then
    echo
    echo "########################################"
    echo "WARNING: NON-ZERO EXIT CODE FROM GIT=$RC"
    echo "########################################"
    echo
fi

echo "Finished $0 $REPO_NAME"
echo 
