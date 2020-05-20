#!/bin/bash
echo "EXPERIMENTAL SCRIPT FOR WINDOWS WSL BIND FIXING"
echo "Uses bind approach to resolve difference between"
echo "the docker-compose /c root and the WSL /mnt/c root"
echo
echo "To run, source the script. Examples ..."
echo ">> . $0"
echo ">> source $0"
VERSIONINFO=20200519.1
DRIVE_LETTER="c"
WHOAMI=$(whoami)
WORKING_HOMEDIR="/${DRIVE_LETTER}/Users/${WHOAMI}"
echo
echo "Starting $0 v$VERSIONINFO"
echo

if [ -d "/${DRIVE_LETTER}" ]; then
    echo "Mount directory /${DRIVE_LETTER} already exists -- GOOD"
else
    sudo mkdir "/${DRIVE_LETTER}"
    if [ -d "/${DRIVE_LETTER}" ]; then
        echo "Mount directory /${DRIVE_LETTER} created -- GOOD"
    else
        echo "Mount directory /${DRIVE_LETTER} creation FAILED!"
        exit 2
    fi
    sudo mount --bind /mnt/c /c
fi

sudo mountpoint -q "/${DRIVE_LETTER}" 
EC=$?
if [ $EC -eq 0 ]; then
    echo "Bind /${DRIVE_LETTER} already exists -- GOOD"
else
    sudo mount --bind "/mnt/${DRIVE_LETTER}" "/${DRIVE_LETTER}"
    sudo mountpoint -q "/${DRIVE_LETTER}" 
    EC=$?
    if [ -d "/${DRIVE_LETTER}" ]; then
        echo "Bind /${DRIVE_LETTER} created -- GOOD"
    else
        echo "Bind /${DRIVE_LETTER} creation FAILED!"
        exit 2
    fi
fi
cd "$WORKING_HOMEDIR"
EC=$?
if [ $EC -ne 0 ]; then
    echo "Failed cd into $WORKING_HOMEDIR"
    exit 1
fi
pwd
echo
echo "Done! The docker-compose bind mounts will work from this location and its subdirectories."
echo
