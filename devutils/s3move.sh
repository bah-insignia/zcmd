#!/bin/bash

source $HOME/zcmd/devutils/default-docker-env.txt
S3_URL="${SHARED_S3_BUCKET}"

if [ ! $# -eq 2 ]; then
    echo "Purpose: Move files from one keyt to a new one on $S3_URL"
    echo "USAGE: $0 SOURCE_OBJECT_KEY DESTINATION_OBJECT_KEY"
    exit 1
fi

KEY_FROM=$1
KEY_TO=$2

CMD="aws s3 mv ${S3_URL}/${KEY_FROM} ${S3_URL}/${KEY_TO}"
echo "MOVE COMMAND: $CMD"
eval "$CMD"

