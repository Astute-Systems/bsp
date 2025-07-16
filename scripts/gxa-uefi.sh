#!/bin/bash -e
sudo apt-get install git python3 python3-setuptools python3-pip
mkdir -p ./build/edkrepo
cd edkrepo
wget https://github.com/tianocore/edk2-edkrepo/releases/download/edkrepo-v2.1.2/edkrepo-2.1.2.tar.gz
tar xvf edkrepo-2.1.2.tar.gz
sudo ./install.py --user ${USER}
cd ..

sudo chown -R ${USER}. ~/.edkrepo

edkrepo clone nvidia-uefi NVIDIA-Platforms main

cd nvidia-uefi
edk2-nvidia/Platform/NVIDIA/Jetson/build.sh
