#!/bin/bash

if [ ! $# -eq 2 ]; then
  echo "$0 SOURCE_FILEPATH DESTINATION_OBJECT_KEY"
  exit 1
fi

LOCALNAME=$1
KEY=$2

source $HOME/zcmd/devutils/default-docker-env.txt

echo "Copy ..."
echo "... from: $LOCALNAME"
echo "... into: $KEY"

CMD="aws s3 cp \"${LOCALNAME}\" ${SHARED_S3_BUCKET}/${KEY}"
echo $CMD
eval "$CMD"

