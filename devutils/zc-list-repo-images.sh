#!/bin/bash
source $HOME/zcmd/devutils/default-docker-env.txt

if [ -z "$PRIVATE_DOCKER_FULL_REGISTRY_URL" ]; then
    echo No other docker registry found
else
    echo Listing from our private Docker Registry....
    CMD="curl -4 ${PRIVATE_DOCKER_FULL_REGISTRY_URL}/v2/_catalog --insecure"
    echo $CMD
    eval $CMD
fi
#curl -4 ${PRIVATE_DOCKER_FULL_REGISTRY_URL}/v2/_catalog


