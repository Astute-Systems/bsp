#!/bin/bash -e

echoblue() {
  echo -e "\033[1;34m$1\033[0m"
}

echored() {
  echo -e "\033[1;33m$1\033[0m"
}   


# Check root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# If the first argument is -version, print the version and exit
if [ "$1" = "-version" ]; then
    echo "Installer Version %release_version%"
    exit 0
fi

#######################################################
#
# PARSE ARGS
#
#######################################################
# Positional: <L4T_VERSION>
# Flags:
#   --no-flash    build the image but do not touch a target device
#   --yes / -y    non-interactive; skip the "press any key" gate
#
FLASH_ARGS=""
ASSUME_YES=0
L4T_VERSION=""
for arg in "$@"; do
  case "$arg" in
    --no-flash|--build-only) FLASH_ARGS="--no-flash" ;;
    --flash-only)            FLASH_ARGS="--flash-only" ;;
    --yes|-y)                ASSUME_YES=1 ;;
    -*)
      echo "Unknown option: $arg"
      exit 1
      ;;
    *)
      if [ -z "$L4T_VERSION" ]; then
        L4T_VERSION="$arg"
      fi
      ;;
  esac
done

if [ -z "$L4T_VERSION" ]; then
  echo "Usage: $0 <L4T_VERSION> [--no-flash] [--yes]"
  exit 1
fi

#######################################################
#
# CREATE LINK IN HOME DIRECTORY
#
#######################################################

# When invoked via `sudo`, SUDO_USER is set to the invoking user. When invoked
# directly as root (or via `sudo bash -c ...` from a root shell), SUDO_USER
# may be empty or literally "root", in which case there is no meaningful
# home to link into. Fall back to skipping the symlink in that case.
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

if [ -n "$TARGET_HOME" ] && [ -d "$TARGET_HOME" ] && [ "$TARGET_USER" != "root" ]; then
  # Remove link if it exists
  if [ -L "$TARGET_HOME/AstuteSys" ]; then
    unlink "$TARGET_HOME/AstuteSys"
  fi
  echoblue "GXA Installer: Creating symlink $TARGET_HOME/AstuteSys -> /opt/AstuteSys/${L4T_VERSION}"
  ln -s "/opt/AstuteSys/${L4T_VERSION}" "$TARGET_HOME/AstuteSys"
else
  echoblue "GXA Installer: skipping user home symlink (no non-root invoking user)"
fi

#######################################################
#
# SOURCE THE ENVIRONMENT VARIABLES -  MOSTLY DIRECTORIES
#
#######################################################
source ./config/gxa-build.conf

#######################################################
#
# Cat the README.txt file and wite for user input
#
#######################################################
cat ./README.txt
echo ""
echored "NOTE: Please ensure you have an internet connection before proceeding"
echo ""
if [ "$ASSUME_YES" -ne 1 ]; then
  read -p "Press any key to continue (CTRL+C to cancel)"
fi

# #######################################################
# #
# # Change the SOURCES variable in gxa-build.conf
# #
# #######################################################
# # Sed replace SOURCES=$PROJECT_ROOT/build/l4t with SOURCES=$PROJECT_ROOT/l4t in config/gxa-build.conf
# sed -i "s/build\/l4t/l4t/g" ./config/gxa-build.conf

#######################################################
#
# Run the Install Scripts
#
#######################################################

# The install tree at /opt/AstuteSys/${L4T_VERSION} was extracted by makeself
# as root, so everything is currently owned by root. The downstream scripts
# (gxa-init-build-machine.sh, gxa-utils.sh) intentionally use
# `sudo -u ${SUDO_USER}` to keep build artifacts owned by the invoking user
# so they can be edited without sudo after the install. For that to work,
# the target tree needs to be user-owned before those scripts run.
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
  echoblue "GXA Installer: chown -R $TARGET_USER /opt/AstuteSys/${L4T_VERSION}"
  chown -R "$TARGET_USER":"$TARGET_USER" "/opt/AstuteSys/${L4T_VERSION}"
fi

# Note: as-pinctl is NOT copied to /usr/bin here. Staging to /usr/bin is a
# host-side side effect that only makes sense when we are about to touch USB
# hardware. gxa-flash.sh's require_as_pinctl() handles that lazily, pulling
# from the bundled $PROJECT_ROOT/as-pinctl on first use. This keeps
# --no-flash / --build-only runs free of side effects on the host.

# Run the install scripts
echoblue "GXA Installer: Downloading and extracting sources"
./scripts/gxa-init-build-machine.sh prod $L4T_VERSION
echoblue "GXA Installer: Patching filesystem"
./scripts/gxa-patch-fs.sh prod $L4T_VERSION
echoblue "GXA Installer: Preparing to flash"
./scripts/gxa-flash.sh $FLASH_ARGS
echoblue "GXA Installer: Complete, ~/AstuteSys/scripts/gxa-flash.sh to reenter the flash tool"

