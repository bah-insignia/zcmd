#!/bin/bash
source $HOME/zcmd/devutils/default-docker-env.txt

echo Listing from our private Docker Registry....
CMD="curl -4 ${PRIVATE_DOCKER_FULL_REGISTRY_URL}/v2/_catalog --insecure"
echo $CMD
eval $CMD
#curl -4 ${PRIVATE_DOCKER_FULL_REGISTRY_URL}/v2/_catalog


