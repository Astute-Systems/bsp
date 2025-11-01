#!/bin/bash -e

if [ -n "$1" ]; then
  L4T_VERSION=$1
fi

source ./scripts/gxa-utils.sh

get_default

echoblue "Make release script"

if [ -d "./build/gxa-installer" ]; then
  echo "Cleaning up build directory installer files"
  sudo rm -rf ./build/gxa-installer
fi

echo "Creating directory ./archive/bsp"
mkdir -p ./archive/bsp

./scripts/gxa-pack.sh $L4T_VERSION

# cp ./build/gxa-installer_$L4T_VERSION${OS_VERSION}.run ./archive/bsp/.

echoblue "Complete"