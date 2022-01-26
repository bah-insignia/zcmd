#!/bin/bash
echo "The latest docker compose must be installed as per website"
echo "see https://docs.docker.com/compose/install/#install-compose"
sudo curl -L https://github.com/docker/compose/releases/download/1.17.0/docker compose-`uname -s`-`uname -m` -o /usr/local/bin/docker compose
sudo chmod +x /usr/local/bin/docker compose
docker compose --version

