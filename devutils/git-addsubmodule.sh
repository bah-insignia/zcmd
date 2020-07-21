#!/bin/bash
VERSIONINFO=20200721.1
echo "Starting $0 v$VERSIONINFO"

source $HOME/zcmd/devutils/default-docker-env.txt

function showUsage()
{
  echo ""
  echo "============================="
	echo "USAGE: $0 SUBMODULE_REPO_NAME"
	echo "USAGE: path/to/code/location"
	echo "IMPORTANT: Location must end with a folder named the same as the repo name."
	echo "OPTION: -f, passes the force argument to force re-cloning from the repo."
	echo "============================="
	echo ""
	echo "Pick a SUBMODULE_REPO_NAME value from the list shown here ..."
	ssh git@${GIT_REPO_HOST_NAME}
}

if [ '--help' == $1  ]; then
	showUsage
	exit 2
fi
SUBMODULE_REPO_NAME=$1
PATH_TO_CODE_LOCATION=$2
FORCED=$3
if [ -z "$SUBMODULE_REPO_NAME" ]; then
	showUsage
	exit 2
fi
if [ -z "$PATH_TO_CODE_LOCATION" ]; then
	showUsage
	exit 2
fi
if [ -z "$FORCED" ]; then
  git submodule add --force git@${GIT_REPO_HOST_NAME}:${SUBMODULE_REPO_NAME} ${PATH_TO_CODE_LOCATION}
else
  git submodule add git@${GIT_REPO_HOST_NAME}:${SUBMODULE_REPO_NAME} ${PATH_TO_CODE_LOCATION}
fi

echo "Finished $0 $SUBMODULE_REPO_NAME"
