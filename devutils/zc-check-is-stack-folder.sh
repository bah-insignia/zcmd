#!/bin/bash

PWD=$(pwd)

if [ ! -f "./stack.env" ]; then
    #echo " "
    #echo "$PWD is NOT a runtime stack folder"
    exit 2
fi

echo "$PWD is a runtime stack folder"

