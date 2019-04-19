#!/bin/bash
VERSIONINFO=20180404.1

echo "Started $0 v$VERSIONINFO"

PROJECTNAME=$1

source $HOME/zcmd/devutils/default-docker-env.txt
S3_URL="${SHARED_S3_BUCKET}"

if [ -z "$PROJECTNAME" ]; then
    GREP=" | grep 'database-dumps'"
else
    GREP=" | grep 'database-dumps/$PROJECTNAME'"
fi

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

