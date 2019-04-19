#!/bin/bash

source $HOME/zcmd/devutils/default-docker-env.txt
S3_URL="${SHARED_S3_ASSETS_BUCKET}"

if [ $# -eq 0 ]; then
    GREP=""
    echo "Not filtering with grep."
else
    GREP=" | grep '$1'"
    echo "Will grep for '$1'"
fi

CMD="aws s3 ls ${SHARED_S3_ASSETS_BUCKET} --recursive${GREP}"
echo "LISTING COMMAND: $CMD"
eval "$CMD"

