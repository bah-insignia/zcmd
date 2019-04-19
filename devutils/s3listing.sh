#!/bin/bash

if [ $# -eq 0 ]; then
    GREP=""
    echo "Not filtering with grep."
else
    GREP=" | grep '$1'"
    echo "Will grep for '$1'"
fi

source $HOME/zcmd/devutils/default-docker-env.txt
S3_URL="${SHARED_S3_BUCKET}"

PV=$(which pv)
if [ -z "$PV" ]; then
    CMD="aws s3 ls ${S3_URL} --recursive${GREP}"
else
    CMD="aws s3 ls ${S3_URL} --recursive | pv ${GREP}"
fi

echo "LISTING COMMAND: $CMD"
eval "$CMD"
echo
echo "LISTING COMPLETED"
echo

