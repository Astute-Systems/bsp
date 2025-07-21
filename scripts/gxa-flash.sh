#!/bin/bash 

# Check root user
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

source ./config/gxa-build.conf
source ./scripts/gxa-utils.sh

if [ ! -f /usr/bin/as-pinctl ]; then
  echo "as-pinctl not found. " 
  if [ ! -f $SOURCES/bin/as-pinctl ]; then
    $PROJECT_ROOT/scripts/gxa-make.sh as-pinctl
  fi
  sudo cp $SOURCES/bin/as-pinctl /usr/bin/
fi

##############################
#
#  DEFINE FUNCTIONS
#
###############################


function full_flash() {
  # build image and flash
  cd $L4T
  sudo $L4T/flash.sh jetson-agx-orin-gxa-1 mmcblk0p1 
}
function build_only() {
  sudo $L4T/flash.sh --no-flash jetson-agx-orin-gxa-1 mmcblk0p1 > $OUTPUT 2>&1 &
} 
function flash_only(){
      sudo $L4T/flash.sh --no-systemimg jetson-agx-orin-gxa-1 mmcblk0p1 > $OUTPUT 2>&1 &
}

function recovery {
  retest

  RET=$?
  while [ $RET -ne 0 ]; do
      sleep 0.5
      retest
      RET=$?
  done
}

function retest() {
  # sleep for 0.5 seconds
  USB_DEVICE_ID="0955:7023"

  # Set $DETECT is nvidia device is detected in recovery mode
  lsusb -d $USB_DEVICE_ID > /dev/null 2>&1
  RET=$?

  # Check RET is 0
  if [ $RET -eq 0 ]; then
      echoblue "NVIDIA device ($USB_DEVICE_ID) detected in recovery mode."
      return 0
  else
      echoblue "NVIDIA device ($USB_DEVICE_ID) not detected in recovery mode."
      echored "Attempting to enter recovery mode..."
      # Attempt to enter recovery mode
      as-pinctl -recovery
      sleep 3
      return 1
  fi
}

recovery
full_flash
