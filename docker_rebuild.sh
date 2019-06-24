#!/usr/bin/env bash
docker build -t 'sogis/qgis-server-v3:master' .
# set +e means "exit immediately if a command exits with a non-zero result status"
set +e
docker rm -f qgis-server-v3
set -e
docker run -p 9991:9991 --name qgis-server-v3 -d --restart=always sogis/qgis-server-v3:master
echo
echo "#####################################################"
echo "Use the following comand to see QGIS server live logs"
echo "docker logs -f qgis-server"
