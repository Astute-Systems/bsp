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

# Detect L4T major to gate r36-only patches
L4T_REL=$(sed -n 's/^# R\([0-9]\+\) .*REVISION: \([0-9]\+\).*/\1.\2/p' \
    "$L4T/rootfs/etc/nv_tegra_release" 2>/dev/null | head -n1)
L4T_MAJOR=${L4T_REL%%.*}

# Allow caller (gxa-make.sh) to override the overlay source directory so we can
# support both r36 (config/l4t-overlay) and r39+ (config/l4t-overlay-r39).
# If unset, auto-select based on detected L4T generation.
if [ -z "$L4T_OVERLAY_DIR" ]; then
    if [ -n "$L4T_MAJOR" ] && [ "$L4T_MAJOR" -ge 39 ] && [ -d "$CONFIG/l4t-overlay-r39" ]; then
        L4T_OVERLAY_DIR="$CONFIG/l4t-overlay-r39"
    else
        L4T_OVERLAY_DIR="$CONFIG/l4t-overlay"
    fi
fi

if [ ! -d "$L4T_OVERLAY_DIR" ]; then
    echored "Overlay directory not found: $L4T_OVERLAY_DIR"
    exit 1
fi

#######################################################
#
# COPY RELEVANT CONFIG FILES TO L4T DIRECTORY
#
#######################################################
function copy_configs()
{
  local MB2_BCT_COMMON=tegra234-mb2-bct-common.dtsi

  echogreen "Copying $L4T_OVERLAY_DIR onto Linux for Tegra..."
  sudo cp -rf "$L4T_OVERLAY_DIR"/* "$L4T"/

  # r36-only tweaks: board conf permission + MB2 BCT EEPROM read-size patch
  if [ -n "$L4T_MAJOR" ] && [ "$L4T_MAJOR" -lt 39 ]; then
    if [ -n "$L4T_CONFIG_FILE" ] && [ -f "$L4T/$L4T_CONFIG_FILE" ]; then
      chmod a+rwx "$L4T/$L4T_CONFIG_FILE"
    fi
    if [ -f "$L4T/bootloader/$MB2_BCT_COMMON" ]; then
      sed -i 's/cvb_eeprom_read_size = <0x100>;/cvb_eeprom_read_size = <0x0>;/' \
        "$L4T/bootloader/$MB2_BCT_COMMON"
    fi
  fi
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
