#!/bin/bash
VERSIONINFO=20190417.1
echo "Starting $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt

function showUsage()
{
	echo "USAGE: $0 SUBMODULE_REPO_NAME"
	echo "Pick a SUBMODULE_REPO_NAME value from the list shown here ..."
	ssh git@${GIT_REPO_HOST_NAME}
}

SUBMODULE_REPO_NAME=$1
if [ -z "$SUBMODULE_REPO_NAME" ]; then
	showUsage
	exit 2
fi

git submodule add git@${GIT_REPO_HOST_NAME}:${SUBMODULE_REPO_NAME}

echo "Finished $0 $SUBMODULE_REPO_NAME"
