#!/bin/bash
source $HOME/zcmd/devutils/default-docker-env.txt
ssh git@${GIT_REPO_HOST_NAME} 2>/tmp/nul | grep "R "
exit 0


