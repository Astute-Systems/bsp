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

  # r36-only: board conf gets shipped read-only in the BSP tarball; loosen it
  # so downstream steps can rewrite it. r39+ ships it writable already.
  if [ -n "$L4T_MAJOR" ] && [ "$L4T_MAJOR" -lt 39 ]; then
    if [ -n "$L4T_CONFIG_FILE" ] && [ -f "$L4T/$L4T_CONFIG_FILE" ]; then
      chmod a+rwx "$L4T/$L4T_CONFIG_FILE"
    fi
  fi

  # MB2 BCT EEPROM read-size patch: GXA-1 has no carrier ID EEPROM at 0xac, so
  # zero the read size to stop MB1/MB2 from probing it at boot. Applies to all
  # L4T generations that ship this dtsi with the stock 0x100 default.
  if [ -f "$L4T/bootloader/$MB2_BCT_COMMON" ]; then
    if ! grep -q 'cvb_eeprom_read_size = <0x0>;' "$L4T/bootloader/$MB2_BCT_COMMON"; then
      sed -i 's/cvb_eeprom_read_size = <0x100>;/cvb_eeprom_read_size = <0x0>;/' \
        "$L4T/bootloader/$MB2_BCT_COMMON"
      if ! grep -q 'cvb_eeprom_read_size = <0x0>;' "$L4T/bootloader/$MB2_BCT_COMMON"; then
        echored "Failed to patch cvb_eeprom_read_size in $MB2_BCT_COMMON"
        exit 1
      fi
    fi
  fi
}
copy_configs

#######################################################
#
# PATCH FLASH.SH's RECOVERY RAMDISK BUILD FOR MODERN OPENSSH HOSTS
#
#######################################################
## flash.sh builds recovery.img via
## tools/ota_tools/version_upgrade/ota_make_recovery_img_dtb.sh, which
## unconditionally generates a DSA host key for the recovery-mode sshd:
##   ssh-keygen -t dsa -N "" -f ... >/dev/null 2>&1;check_error
## Modern OpenSSH (>= 9.8, e.g. Ubuntu 24.10+/25.x flashing hosts) has
## dropped "-t dsa" support entirely ("unknown key type dsa"). Because the
## keygen's output is redirected to /dev/null, the failure is completely
## silent and check_error aborts the whole flash with a bare
## "command is failed" right after the recovery ramdisk's
## "_BASE_KERNEL_VERSION=..." banner. The DSA key is never referenced by the
## sshd_config this script generates (only rsa/ecdsa/ed25519 HostKeys are
## written), so failing to generate it is harmless. Demote it from a fatal
## check_error to a check_warning so flashing from a host with newer OpenSSH
## doesn't abort the build.
REC_IMG_SCRIPT="$L4T/tools/ota_tools/version_upgrade/ota_make_recovery_img_dtb.sh"
if [ -f "$REC_IMG_SCRIPT" ] && grep -q 'ssh-keygen -t dsa.*check_error' "$REC_IMG_SCRIPT"; then
  echo "Patching ota_make_recovery_img_dtb.sh: DSA host key generation is non-fatal on modern OpenSSH..."
  sed -i '/ssh-keygen -t dsa/s/;check_error$/;check_warning/' "$REC_IMG_SCRIPT"
fi

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

## nv-l4t-usb-device-mode.service on GXA-1
##
## Historical: this service was masked because tegra-xudc deferred-probed
## forever ("failed to get usbphy-1"), timing out for ~90s and blocking OOBE.
##
## Root cause fixed: xudc is disabled in the GXA-1 device tree
## (see tegra234-p3737-0000+p3701.dtsi, usb@3550000 { status = "disabled"; }).
## GXA-1 has no USB device-mode port (the OTG-capable USB_0 lane is soldered
## to the FT232RQ debug UART; user ports go through USB2/USB3 hubs in host
## mode), so the driver has nothing to bind to and this service has nothing
## real to configure.
##
## Remaining problem: nv-oobe.service ships with
##   Requires=nv-load-display-modules.service nv-l4t-usb-device-mode.service
## The stock nv-l4t-usb-device-mode.service unit is not installed on this
## rootfs (it lives in the nvidia-l4t-init deb which pulls it in on r39.2),
## and even if it were, we don't want its ExecStart running on GXA-1. If the
## unit is missing, systemd refuses to start nv-oobe.service and OOBE fails.
##
## Fix: ship a no-op stub unit at /etc/systemd/system/. Because /etc/systemd
## overrides /usr/lib/systemd, this stub also survives any future apt upgrade
## of the vendor package that would otherwise re-install a functional (and
## for us, broken) unit under /usr/lib.
echo "Installing no-op nv-l4t-usb-device-mode.service stub..."
STUB="$L4T/rootfs/etc/systemd/system/nv-l4t-usb-device-mode.service"
mkdir -p "$(dirname "$STUB")"
# The stock sample rootfs ships this path as a dangling symlink to
# /opt/nvidia/l4t-usb-device-mode/nv-l4t-usb-device-mode.service (that target
# is only populated later by apply_binaries.sh from nvidia-l4t-init). A shell
# `>` redirect would follow the symlink and fail with "No such file or
# directory", so unlink it first and write our stub as a plain regular file.
rm -f "$STUB"
cat > "$STUB" <<'EOF'
# GXA-1 stub: xudc is disabled in the device tree, this board has no USB
# device-mode port. This unit exists only to satisfy nv-oobe.service's
# Requires= dependency without pulling in the vendor script (which would
# try to configure a non-existent UDC gadget). Placed under /etc/systemd
# so it wins over any /usr/lib/systemd copy shipped by future apt upgrades.
[Unit]
Description=Stub for nv-l4t-usb-device-mode (GXA-1: xudc disabled in DT)
[Service]
Type=oneshot
ExecStart=/bin/true
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

## Disable APT auto-update timers.
##
## apt-daily.service and apt-daily-upgrade.service block multi-user.target
## for up to ~2min at each boot while they try to fetch metadata / upgrade
## packages. On GXA-1 this is unwanted: fielded units may have no network,
## and updates are managed centrally, not by a random background timer.
## The units and timers stay installed so the customer can re-enable them
## manually if desired; only the timer-target symlinks are removed.
echo "Disabling apt-daily timers..."
for t in apt-daily.timer apt-daily-upgrade.timer; do
  rm -f "$L4T/rootfs/etc/systemd/system/timers.target.wants/$t"
done

echoblue "Patching done..."
