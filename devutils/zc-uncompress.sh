#!/bin/bash

VERSIONINFO="20171227.5"

function showUsage()
{
    echo "USAGE: $0 SOURCEFILE OUTPUTPATH"
    exit 1
}

if [ -z "$1" ]; then
    echo "MISSING required param 1!"
    showUsage
    exit 2
fi

SOURCEFILE=$1

if [ ! -z "$2" ]; then
    OUTPUTPATH=$2
else
    SOURCEBASENAME=$(basename $SOURCEFILE)
    OUTPUTPATH="/tmp/uncompressed/${SOURCEBASENAME}-contents"
fi
if [ ! -d "$OUTPUTPATH" ]; then
    echo "Creating $OUTPUTPATH"
    mkdir -p $OUTPUTPATH
fi

echo "SOURCE FILE: $SOURCEFILE"
echo "OUTPUT PATH: $OUTPUTPATH"

COMPRESSION_TYPE="UNKNOWN"
ZIPCHECK=$(echo "$SOURCEFILE" | grep ".zip")
if [ ! -z "$ZIPCHECK" ]; then
    COMPRESSION_TYPE="ZIP"
else
    TARGZCHECK=$(echo "$SOURCEFILE" | grep ".tar.gz")
    if [ ! -z "$TARGZCHECK" ]; then
        COMPRESSION_TYPE="TAR.GZ"
    else
        GZCHECK=$(echo "$SOURCEFILE" | grep ".gz")
        if [ ! -z "$GZCHECK" ]; then
            COMPRESSION_TYPE="GZ"
        fi
    fi
fi
echo "SOURCE FILE compression is $COMPRESSION_TYPE"

CMD="NO OPERATION"
case "$COMPRESSION_TYPE" in
    "ZIP" )
        CMD="unzip $SOURCEFILE -d $OUTPUTPATH"  
        ;;
    "TAR.GZ" )
        CMD="tar -xvzf $SOURCEFILE -C $OUTPUTPATH" 
        ;;
    "GZ" )
        CMD="gzip -dkvf $SOURCEFILE" 
        ;;
    "*" )
        echo "ERROR: Unrecognized compression for $SOURCEFILE"
        exit 2
        ;;
esac
echo "$CMD"
($CMD)
if [ $? -ne 0 ]; then
    echo "!!!!!!!!!!!!!!!!!!!!!"
    echo "DECOMPRESSION FAILED!"
    echo "!!!!!!!!!!!!!!!!!!!!!"
    exit 2
fi
echo "Finished uncompressing into $OUTPUTPATH"
