#!/bin/bash
#
# gxa-flash.sh: build the GXA-1 flash image and (optionally) flash a target.
#
# Modes:
#   (default)      build the image AND flash a target attached via USB in
#                  recovery mode. Requires as-pinctl on the host.
#   --no-flash     build the image only; do not require a USB target. This
#                  passes L4T flash.sh --no-flash and injects the offline
#                  board-spec env vars from config/gxa-build.conf so that
#                  flash.sh can produce artifacts without EEPROM readback.
#   --flash-only   flash a target using an already-built image (no rebuild).

set -e

# Check root user
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

MODE="full"
for arg in "$@"; do
  case "$arg" in
    --no-flash|-b|--build-only) MODE="build-only" ;;
    --flash-only|-f)            MODE="flash-only" ;;
    "")                         ;;  # ignore empty positional (e.g. unset $FLASH)
    *)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--no-flash | --flash-only]"
      exit 1
      ;;
  esac
done

source ./config/gxa-build.conf
source ./scripts/gxa-utils.sh

##############################
#
#  BOARD SPEC (offline)
#
##############################

# When flash.sh is invoked without a target connected (--no-flash), it needs
# BOARDID/FAB/BOARDSKU/BOARDREV in the environment to identify the module.
# Values come from config/gxa-build.conf.
function export_board_spec() {
  export BOARDID="${GXA_BOARDID:-3701}"
  export FAB="${GXA_FAB:-TS4}"
  export BOARDSKU="${GXA_BOARDSKU:-0008}"
  export BOARDREV="${GXA_BOARDREV:-A.0}"
  export CHIP_SKU="${GXA_CHIP_SKU:-00:00:00:D0}"
  export CHIP_MINOR="${GXA_CHIP_MINOR:-1}"
  export BOOTROM_ID="${GXA_BOOTROM_ID:-1}"
  export RAMCODE_ID="${GXA_RAMCODE_ID:-4}"
  echoblue "GXA-Flash: injecting offline board spec BOARDID=${BOARDID} FAB=${FAB} BOARDSKU=${BOARDSKU} BOARDREV=${BOARDREV}"
}

# Ensure as-pinctl is available on the host for any hardware-touching mode.
# Search order:
#   1. /usr/bin/as-pinctl                  (already installed)
#   2. $PROJECT_ROOT/as-pinctl             (bundled next to the installer in
#                                           /opt/AstuteSys/<ver>/ -- PROD)
#   3. $SOURCES/bin/as-pinctl              (built in-tree from the BSP repo -- DEV)
#   4. rebuild from source via gxa-make.sh (DEV only; gxa-make.sh is not
#                                           shipped in the PROD installer)
function require_as_pinctl() {
  if [ -f /usr/bin/as-pinctl ]; then
    return 0
  fi
  echo "as-pinctl not found in /usr/bin."
  local src=""
  if [ -f "$PROJECT_ROOT/as-pinctl" ]; then
    src="$PROJECT_ROOT/as-pinctl"
  elif [ -f "$SOURCES/bin/as-pinctl" ]; then
    src="$SOURCES/bin/as-pinctl"
  elif [ -x "$PROJECT_ROOT/scripts/gxa-make.sh" ]; then
    # DEV build tree: rebuild from source.
    "$PROJECT_ROOT/scripts/gxa-make.sh" as-pinctl
    src="$SOURCES/bin/as-pinctl"
  else
    echored "as-pinctl is missing and cannot be rebuilt from this tree."
    echored "Expected one of:"
    echored "  /usr/bin/as-pinctl"
    echored "  $PROJECT_ROOT/as-pinctl   (bundled with the installer)"
    echored "  $SOURCES/bin/as-pinctl    (in-tree DEV build)"
    exit 1
  fi
  echoblue "GXA-Flash: staging as-pinctl from $src -> /usr/bin/"
  sudo cp "$src" /usr/bin/
}

##############################
#
#  MODE FUNCTIONS
#
##############################

function full_flash() {
  cd "$L4T"
  sudo "$L4T"/flash.sh jetson-agx-orin-gxa-1 mmcblk0p1
}

function build_only() {
  cd "$L4T"
  export_board_spec
  local logdir="/var/log/gxa"
  sudo mkdir -p "$logdir"
  local logfile="$logdir/flash-build.log"
  echoblue "GXA-Flash: building image (log: $logfile)"
  # Run in foreground so callers see progress; tee for later inspection.
  sudo -E "$L4T"/flash.sh --no-flash jetson-agx-orin-gxa-1 mmcblk0p1 2>&1 \
    | sudo tee "$logfile"
}

function flash_only() {
  cd "$L4T"
  sudo "$L4T"/flash.sh --no-systemimg jetson-agx-orin-gxa-1 mmcblk0p1
}

##############################
#
#  RECOVERY DETECT
#
##############################

function retest() {
  local USB_DEVICE_ID="0955:7023"
  if lsusb -d "$USB_DEVICE_ID" > /dev/null 2>&1; then
    echoblue "NVIDIA device ($USB_DEVICE_ID) detected in recovery mode."
    return 0
  fi
  echoblue "NVIDIA device ($USB_DEVICE_ID) not detected in recovery mode."
  echored "Attempting to enter recovery mode..."
  as-pinctl -recovery
  sleep 3
  return 1
}

function recovery() {
  while ! retest; do sleep 0.5; done
}

##############################
#
#  DISPATCH
#
##############################

case "$MODE" in
  build-only)
    build_only
    ;;
  flash-only)
    require_as_pinctl
    recovery
    flash_only
    ;;
  full|*)
    require_as_pinctl
    recovery
    full_flash
    ;;
esac

