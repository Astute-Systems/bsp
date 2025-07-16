#!/bin/bash -e

if [ -d "./build" ]; then
  echo "Cleaning up build directory"
  sudo rm -rf ./build
fi

L4T_VERSION=$1
# If $1 is provided print
if [ ! -z "$L4T_VERSION" ]; then
  echo "L4T Version: $L4T_VERSION"
fi

./scripts/gxa-pack.sh $L4T_VERSION