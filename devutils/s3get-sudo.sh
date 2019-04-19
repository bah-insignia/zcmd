#!/bin/bash

if [ ! $# -eq 2 ]; then
  echo "$0 SOURCE_OBJECT_KEY DESTINATION_FILEPATH [SET_OWNER_GROUPNAME]"
  exit 1
fi

KEY=$1
LOCALNAME=$2
SET_OWNER_GROUPNAME=$3

source $HOME/zcmd/devutils/default-docker-env.txt

#Get the path now because SUDO ROOT MIGHT not have it on the path!
AWS_PATH=$(which aws)

CMD="sudo $AWS_PATH s3 cp ${SHARED_S3_BUCKET}/${KEY} ${LOCALNAME}"
echo "COPY COMMAND: $CMD"
eval "$CMD"
if [ $? -ne 0 ]; then
    echo "ERROR ON $CMD"
    exit 2
fi

WHOAMI=$(whoami)

if [ ! -z "$SET_OWNER_GROUPNAME" ]; then
    (sudo chown $WHOAMI:$SET_OWNER_GROUPNAME ${LOCALNAME})
    if [ $? -ne 0 ]; then
        echo "ERROR ON changing ownership of ${LOCALNAME} to user=$WHOAMI group=$SET_OWNER_GROUPNAME"
        exit 2
    fi
fi
    

