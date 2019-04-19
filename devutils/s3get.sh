#!/bin/bash

if [ ! $# -eq 2 ]; then
  echo "$0 SOURCE_OBJECT_KEY DESTINATION_FILEPATH"
  exit 1
fi

KEY=$1
LOCALNAME=$2

source $HOME/zcmd/devutils/default-docker-env.txt

CMD="aws s3 cp ${SHARED_S3_BUCKET}/${KEY} ${LOCALNAME}"
echo "COPY COMMAND: $CMD"
eval "$CMD"


