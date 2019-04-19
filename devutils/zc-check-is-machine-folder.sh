#!/bin/bash

PWD=$(pwd)

if [ ! -f "./machine.env" ]; then
    #echo " "
    #echo "$PWD is NOT a machine image folder"
    exit 2
fi

echo "$PWD is a machine image folder"

