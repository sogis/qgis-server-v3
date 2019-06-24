#!/bin/bash
set -e

cd /build

git clone -b $1 --depth 1 https://github.com/qgis/QGIS.git
cd QGIS

#next line show how to pull a specific pull request for testing
#git pull origin pull/9878/head
