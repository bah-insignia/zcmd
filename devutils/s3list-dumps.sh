#!/bin/bash
VERSIONINFO=20180404.1

echo "Started $0 v$VERSIONINFO"

PROJECTNAME=$1

source $HOME/zcmd/devutils/default-docker-env.txt
S3_URL="${SHARED_S3_BUCKET}"

if [ -z "$PROJECTNAME" ]; then
    GREP=" | grep 'dumps'"
else
    GREP=" | grep 'dumps/$PROJECTNAME'"
fi

PV=$(which pv)
if [ -z "$PV" ]; then
    CMD="aws s3 ls ${S3_URL} --recursive${GREP}"
else
    CMD="aws s3 ls ${S3_URL} --recursive | pv ${GREP}"
fi

if [ -z "$PROJECTNAME" ]; then
    QUALTXT="ANY PROJECT"
else
    QUALTXT="'$PROJECTNAME' PROJECT"
fi
echo "DUMPS LISTING for ${QUALTXT}: $CMD"
echo
eval "$CMD"
echo
echo "DUMPS LISTING for ${QUALTXT} COMPLETED"
echo