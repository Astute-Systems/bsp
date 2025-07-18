#!/bin/bash -e

source ./scripts/gxa-utils.sh
echoblue "Make release script"
if [ -d "./build" ]; then
  echo "Cleaning up build directory"
  sudo rm -rf ./build
fi

echo "Creating directory ./archive/bsp"
mkdir -p ./archive/bsp

L4T_VERSION=$1

./scripts/gxa-pack.sh $L4T_VERSION