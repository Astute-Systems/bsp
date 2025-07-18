#!/bin/bash -e

# Check root user
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

source ./scripts/gxa-utils.sh $ARG1
echoblue "Patching GXA Filesystem for GXA-1"

#######################################################
#
# SOURCE THE ENVIRONMENT VARIABLES -  MOSTLY DIRECTORIES
#
#######################################################

source ./config/gxa-build.conf

#######################################################
#
# COPY RELEVANT CONFIG FILES TO L4T DIRECTORY
#
#######################################################
function copy_configs()
{
  local MB2_BCT_COMMON=tegra234-mb2-bct-common.dtsi

  echogreen "Copying the filesystem overlay onto Linux for Tegra..."
  sudo cp -rf $CONFIG/l4t-overlay/* $L4T
  chmod a+rwx $L4T/$L4T_CONFIG_FILE
  sed -i 's/cvb_eeprom_read_size = <0x100>;/'"cvb_eeprom_read_size = <0x0>;/" $L4T/bootloader/$MB2_BCT_COMMON
  
}
copy_configs

#######################################################
#
# MODIFY THE FILESYSTEM FOR GXA-1
#
#######################################################
## Need to remove the nvfancontrol service
echo "Removing the nvfancontrol service..."

# If files do not exist, script will echo already removed
if [ ! -f $L4T/rootfs/etc/systemd/system/nvfancontrol.service ]; then
  echo "$L4T/rootfs/etc/systemd/system/nvfancontrol.service already removed"
else
  rm -f $L4T/rootfs/etc/systemd/system/nvfancontrol.service
fi

if [ ! -f $L4T/rootfs/etc/systemd/system/multi-user.target.wants/nvfancontrol.service ]; then
  echo "$L4T/rootfs/etc/systemd/system/multi-user.target.wants/nvfancontrol.service already removed"
else
  rm -f $L4T/rootfs/etc/systemd/system/multi-user.target.wants/nvfancontrol.service
fi

if [ ! -d $L4T/rootfs/etc/nvpower/nvfancontrol ]; then
  echo "$L4T/rootfs/etc/nvpower/nvfancontrol directory already removed"
else
  rm -rf $L4T/rootfs/etc/nvpower/nvfancontrol
fi

echoblue "Patching done..."
