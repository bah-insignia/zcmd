#!/bin/bash
#Helper utility to find and show us large files

source $HOME/zcmd/devutils/default-docker-env.txt

echo "USAGE: $0 [FILESIZE_FILTER] [SUFFIX_FILTER]"
echo

FILESIZE_FILTER=$1
if [ -z "$FILESIZE_FILTER" ] || [ "-" = "$FILESIZE_FILTER" ]; then
    FILESIZE_FILTER="1000"
fi
SUFFIX_FILTER=$2
if [ ! -z "$SUFFIX_FILTER" ]; then
    P1="-name '*."
    SFARG="${P1}${SUFFIX_FILTER}'"
fi

CMD="find . -type f -size +${FILESIZE_FILTER}M ${SFARG}"
echo $CMD
eval $CMD
echo
