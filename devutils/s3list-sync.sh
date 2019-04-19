#!/bin/bash

source $HOME/zcmd/devutils/default-docker-env.txt
S3_URL="${SHARED_S3_BUCKET}"

GREP=" | grep 'sync'"
source $HOME/zcmd/devutils/default-docker-env.txt
CMD="aws s3 ls ${SHARED_S3_BUCKET} --recursive${GREP}"
echo "LISTING COMMAND: $CMD"

echo "DEPRECATION NOTICE: Assets will eventually move to dedicated $SHARED_S3_ASSETS_BUCKET bucket!"
echo "Press any key to continue"
read

eval "$CMD"

