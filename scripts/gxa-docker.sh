#!/bin/bash
# This script is used to build the GXA docker image

docker build -t gxa -f ./scripts/docker/build/Dockerfile .
#docker run -it  gxa
