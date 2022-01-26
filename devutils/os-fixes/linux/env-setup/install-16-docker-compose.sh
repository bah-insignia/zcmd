#!/bin/bash
VERSIONNAME="1.16.1"
URL="https://github.com/docker/compose/releases/download/$VERSIONNAME"
echo "The docker compose must be installed as per website"
echo "see https://docs.docker.com/compose/install/#install-compose"
echo "Installing from $URL"
sudo curl -L ${URL}/docker compose-`uname -s`-`uname -m` -o /usr/local/bin/docker compose
sudo chmod +x /usr/local/bin/docker compose
docker compose --version

