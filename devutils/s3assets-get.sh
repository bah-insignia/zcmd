#!/bin/bash

source $HOME/zcmd/devutils/default-docker-env.txt
S3_URL="${SHARED_S3_ASSETS_BUCKET}"
if [ ! $# -eq 2 ]; then
    echo "$0 SOURCE_OBJECT_KEY DESTINATION_FILEPATH"
    echo "NOTE: BUCKET=$S3_URL"
    exit 1
fi

KEY=$1
LOCALNAME=$2

CMD="aws s3 cp ${S3_URL}/${KEY} ${LOCALNAME}"
echo "COPY COMMAND: $CMD"
eval "$CMD"


