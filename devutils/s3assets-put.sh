#!/bin/bash
source $HOME/zcmd/devutils/default-docker-env.txt
S3_URL="${SHARED_S3_ASSETS_BUCKET}"
if [ ! $# -eq 2 ]; then
    echo "$0 SOURCE_FILEPATH DESTINATION_OBJECT_KEY"
    echo "NOTE: BUCKET=$S3_URL"
    exit 1
fi

LOCALNAME=$1
KEY=$2

echo "Copy [BUCKET=$S3_URL] ..."
echo "... from: $LOCALNAME"
echo "... into: $KEY"

CMD="aws s3 cp \"${LOCALNAME}\" ${S3_URL}/${KEY}"
echo $CMD
eval "$CMD"

