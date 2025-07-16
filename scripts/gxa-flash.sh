#!/bin/bash 
BACK_TITLE="GXA-1 Flashing Tool"
# Get the console width
CONSOLE_WIDTH=$(tput cols)
# Get the console height
CONSOLE_HEIGHT=$(tput lines)
# Subtract 8 from the console width to get the dialog width
DIALOG_WIDTH=$((CONSOLE_WIDTH-8))
# Subtract 8 from the console height to get the dialog height
DIALOG_HEIGHT=$((CONSOLE_HEIGHT-6))

# Check root user
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

source ./config/gxa-build.conf

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
  USB_DEVICE_ID=0955:7023

  # Set $DETECT is nvidia device is detected in recovery mode
  DEVICE=$(lsusb -d $USB_DEVICE_ID ) || true

  # Check RET is 0
  if [ $RET -eq 0 ]; then
      echo "NVIDIA device ($USB_DEVICE_ID) detected in recovery mode."
      return 0
  else
      echo "NVIDIA device ($USB_DEVICE_ID) not detected in recovery mode."
      echo "attempting to enter recovery mode..."
      # Attempt to enter recovery mode
      as-pinctl -recovery
      wait 
      return 1
  fi
}

# DEFAULT_ITEM=1
# function DialogGen() {
#     selection=$(mktemp)
#     dialog --backtitle "$BACK_TITLE" --erase-on-exit --colors --clear --title "Flashing options" \
#     --default-item $DEFAULT_ITEM \
#     --menu "$DETECT \nWould you like to:" 15 60 46 \
#     1 "Build System Image and Flash to GXA" \
#     2 "Build System Image and Leave (flash later)" \
#     3 "Flash an Existing System Image (from 2)" \
#     4 "Retest" \
#     5 "Exit" \
#     2>$selection
# }


# OUTPUT=$(mktemp)
# menu() {
#   cd $L4T

#   DialogGen
#   dialog --clear

#   opt=$(cat $selection)
#   case $opt in
#     1)
#       full_flash> $OUTPUT 2>&1 &
#       # Get the process ID of the flash command
#       OPTION="Full Flash"
#       PID=$!
#       ;;
#     2)
#       build_only > $OUTPUT 2>&1 &
#       # Get the process ID of the flash command
#       OPTION="No Flash"
#       PID=$!
#       ;;
#     3)
#       flash_only > $OUTPUT 2>&1 &
#       # Get the process ID of the flash command
#       OPTION="Skip System Image"
#       PID=$!
#       ;;
#     4)
#       DEFAULT_ITEM=4
#       recovery
#       retest
#       # dialog sub menu with OK, overlay on top of the main menu
#       dialog --backtitle "$BACK_TITLE" --erase-on-exit --colors --clear --title "Retest for recovery mode" --msgbox "$DETECT\nPress OK to continue." 10 50  
#       menu
#       ;;
#     5)
#       exit 0
#       echo "Exiting"
#       ;;
#     *)
#       echo "Cancelled Selection"
#       exit 0
#       ;;
#   esac
# }

# function output() {
#   # Display the output in a dialog tailbox
#   dialog --backtitle "$BACK_TITLE" \
#         --title "Flash Progress (${OPTION})..." \
#         --exit-label "Close" \
#         --clear \
#         --tailbox $OUTPUT 18 70 

#   # Wait for the flash command to complete
#   wait $PID

#   # If $OUTPUT contains "error probing" then set $? to 1
#   if grep -q "Error: probing" $OUTPUT; then
#       $?=1
#   fi

#   # Check if the flash command was successful
#   if [ $? -eq 0 ]; then
#       dialog --backtitle "$BACK_TITLE" --title "Flash Success" --erase-on-exit --msgbox "Flashing completed successfully. Press Ok to finish." 10 50 
#   else
#       dialog --backtitle "$BACK_TITLE" --title "Flash Error" --erase-on-exit --colors --msgbox "\Z1Flashing failed.\Z4  Please check USB connection and ensure device is in recovery mode.\n\nTry running 'lsusb' to check for nvidia device." 10 50
#   fi

#   echo "Log file saved in ${OUTPUT}..."
# }


##############################
#
# RUN THE CODE
#
###############################
# for arg in "$@"; do 
#     IFS="="
#     read -a split <<<"$arg"
#     case ${split[0]} in
#       -r|--release)
#         RELEASE=$arg
#         ;;
#       -f|--flash)
#         FLASH=$arg
#         ;;
#     esac
# done


recovery
full_flash