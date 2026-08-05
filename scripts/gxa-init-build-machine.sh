#!/bin/bash -e

# Check root user
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root"
  exit 1
fi

WGET_EXTRA_ARGS="-q"


# if CI is exported in the environment, then we are running in CI
if [ -z "CI" ]; then
  echo "CI is set, running in CI"
  WGET_EXTRA_ARGS="-q"
  APT_EXTRA_ARGS="-qq"
fi

#######################################################
#
# SOURCE THE ENVIRONMENT VARIABLES -  MOSTLY DIRECTORIES
#
#######################################################

# Include config file
source ./config/gxa-build.conf

#create build dir as unprivileged user
if [ ! -d $BUILD ]; then
  mkdir -p $BUILD
  chmod a+rw $BUILD
fi

#######################################################
#
# Parse arguments
#
#######################################################
# If first arg is prod
if [ "$1" == "prod" ]; then
  FINAL="TRUE"
else
  FINAL="FALSE"
fi

# Second arg is release version. Historically this was stored in $L4T_RELEASE
# but the XML lookup and downstream references used $RELEASE / $L4T_VERSION,
# neither of which was ever set on the happy path -- so the "user specified"
# branch was dead code and every invocation fell through to get_default().
# Unify on $L4T_VERSION (which is what get_default() also exports) so both
# paths agree.
L4T_VERSION=$2

source ./scripts/gxa-utils.sh $L4T_VERSION
echoblue "GXA-1 Initialization Script"


# If CI defined in environment, then we are running in CI
if [ -z "$CI" ]; then
  echo "CI is not set, running in local environment"
else
  echo "CI is set, running in CI"
fi

#######################################################
#
# Install necessary packages (Check if needed for PROD build...)
#
#######################################################
echoblue "Installing necessary packages for L4T ${L4T_VERSION:-<default>} build"
sudo apt-get update -y $APT_EXTRA_ARGS

# qemu user-mode static binary package.
# * <= 25.04: qemu-user-static (real package). Ships /usr/bin/qemu-*-static
#             binaries (static-linked) that NVIDIA's nv-apply-debs.sh (and
#             our own chroot-test.sh) expect by hardcoded path/name.
# * >= 25.10: qemu-user-static is a virtual package. The real static-linked
#             aarch64 emulator now lives in qemu-user (installed via the
#             qemu-user-binfmt metapackage) at /usr/bin/qemu-aarch64 --
#             *without* the "-static" suffix, even though the binary is
#             still statically linked. Anything that looks for the
#             "*-static" filename (nv-apply-debs.sh, chroot-test.sh, ...)
#             breaks on 25.10+. Install qemu-user + qemu-user-binfmt, then
#             restore the historical filenames via compatibility symlinks.
UBUNTU_REL=$(lsb_release -rs 2>/dev/null || echo "")
UBUNTU_MAJOR=${UBUNTU_REL%%.*}
UBUNTU_MINOR=${UBUNTU_REL##*.}
NEEDS_QEMU_STATIC_SYMLINKS=0
if [ -n "$UBUNTU_MAJOR" ] && \
   { [ "$UBUNTU_MAJOR" -gt 25 ] 2>/dev/null || \
     { [ "$UBUNTU_MAJOR" -eq 25 ] 2>/dev/null && [ "$UBUNTU_MINOR" -ge 10 ] 2>/dev/null; }; }; then
  QEMU_PKG="qemu-user qemu-user-binfmt"
  NEEDS_QEMU_STATIC_SYMLINKS=1
else
  QEMU_PKG=qemu-user-static
fi

sudo apt-get install -y $APT_EXTRA_ARGS $QEMU_PKG libxml2-utils flex bison bc libxml2-utils makeself cpio pkg-config dialog dpkg wget sudo lbzip2 make cmake gcc g++ libgpiod-dev libftdi1-dev libgflags-dev

# 25.10+: shim in the "-static" filenames that nv-apply-debs.sh expects.
# We only symlink aarch64 (the target ISA we actually flash); add more here
# if a future step needs another arch. Idempotent.
if [ "$NEEDS_QEMU_STATIC_SYMLINKS" = "1" ]; then
  if [ -x /usr/bin/qemu-aarch64 ] && [ ! -e /usr/bin/qemu-aarch64-static ]; then
    echogreen "Creating /usr/bin/qemu-aarch64-static -> qemu-aarch64 shim (25.10+ rename)"
    sudo ln -s qemu-aarch64 /usr/bin/qemu-aarch64-static
  fi
fi

echoblue "Reading L4T Version from XML file"
if [ -z "$L4T_VERSION" ]; then
    echogreen "No user-specified L4T version, using default"
    get_default
else
    grunt=$(xmllint --xpath "string(/l4tSources/l4t${L4T_VERSION})" ${XML_FILE})
    if [ -z "$grunt" ]; then
        echo "User-specified L4T version $L4T_VERSION not found in XML file."
        echo "Falling back to latest L4T version."
        get_default
    else
        echogreen "Using user-specified L4T version=${L4T_VERSION}"
    fi
fi
export L4T_VERSION

TOOLCHAIN=$(xmllint --xpath "string(/l4tSources/l4t${L4T_VERSION}/toolchain)" ${XML_FILE})
NVIDIA=$(xmllint --xpath "string(/l4tSources/l4t${L4T_VERSION}/nvidia)" ${XML_FILE})
ROOTFS=$(xmllint --xpath "string(/l4tSources/l4t${L4T_VERSION}/rootfs)" ${XML_FILE})
KERNEL=$(xmllint --xpath "string(/l4tSources/l4t${L4T_VERSION}/kernel)" ${XML_FILE})
echogreen "TOOLCHAIN=$TOOLCHAIN"
echogreen "NVIDIA=$NVIDIA"
echogreen "ROOTFS=$ROOTFS"
echogreen "KERNEL=$KERNEL"

if [ ! -d $FLAGS ]; then
  sudo -u $SUDO_USER mkdir -p "$FLAGS"
fi

echoblue "Setting up development environment"

download_and_extract $NVIDIA $SOURCES
download_and_extract $ROOTFS $L4T_ROOTFS

if [ ! -f "$FLAGS/bin_flag" ]; then
  echoblue "Applying binaries"
  "$L4T/apply_binaries.sh"
  sudo -u $SUDO_USER  touch "$FLAGS/bin_flag"
fi

###############################################
##
##    END OF PRODUCTION BUILD
##
##############################################
if [ "$FINAL" == "TRUE" ]; then
  echo "Production build setup completed"
  exit 0 
fi

###############################################
##
##    Setup Development Environment
##
##############################################
download_and_extract $TOOLCHAIN $SOURCES/toolchain 
download_and_extract $KERNEL $SOURCES

TOOLCHAIN_FILENAME=$(basename $TOOLCHAIN)

# Detect toolchain layout. Two shapes are supported:
#   r36.x: aarch64--glibc--stable-2022.08-1.tar.bz2 unpacks to
#          <top>/bin/aarch64-buildroot-linux-gnu-*
#   r39.2+: x-tools.tbz2 unpacks to x-tools/aarch64-none-linux-gnu/bin/aarch64-none-linux-gnu-*
if [ ! -f $FLAGS/toolchain_check ]; then
  echogreen "Extracting $TOOLCHAIN_FILENAME"
  tar -xf $SOURCES/$TOOLCHAIN_FILENAME -C $KERNEL_SOURCES

  # Find the tool-prefix directory that contains a bin/ with gcc.
  # Search two levels deep to cover both r36 (flat) and r39 (x-tools/<triplet>) layouts.
  TOOL_BIN=$(find "$KERNEL_SOURCES" -maxdepth 3 -type f -name 'aarch64-*-gcc' 2>/dev/null | head -n1)
  if [ -z "$TOOL_BIN" ]; then
    echored "Failed to detect aarch64 cross compiler under $KERNEL_SOURCES"
    exit 1
  fi
  # /path/to/KERNEL_SOURCES/<COMPILER_ROOT>/bin/<COMPILER_PREFIX>gcc
  COMPILER_BIN_DIR=$(dirname "$TOOL_BIN")           # .../<COMPILER_ROOT>/bin
  COMPILER_ROOT_ABS=$(dirname "$COMPILER_BIN_DIR")  # .../<COMPILER_ROOT>
  COMPILER_ROOT=${COMPILER_ROOT_ABS#$KERNEL_SOURCES/}
  COMPILER_PREFIX=$(basename "$TOOL_BIN")
  COMPILER_PREFIX=${COMPILER_PREFIX%gcc}            # strip trailing 'gcc'
  # Backward-compat: preserve old COMPILER for r36 flat layout (=top-level dir)
  COMPILER=$(echo "$COMPILER_ROOT" | cut -d/ -f1)

  echogreen "Detected toolchain:"
  echogreen "  COMPILER=$COMPILER"
  echogreen "  COMPILER_ROOT=$COMPILER_ROOT"
  echogreen "  COMPILER_PREFIX=$COMPILER_PREFIX"

  sed -i "/^COMPILER=/c\COMPILER=$COMPILER" $CONFIG/gxa-build.conf
  sed -i "/^COMPILER_ROOT=/c\COMPILER_ROOT=$COMPILER_ROOT" $CONFIG/gxa-build.conf
  sed -i "/^COMPILER_PREFIX=/c\COMPILER_PREFIX=$COMPILER_PREFIX" $CONFIG/gxa-build.conf

  touch $FLAGS/toolchain_check
fi
if [ ! -f $FLAGS/kernel_check ]; then
  echogreen "Extracting kernel_src.tbz2"
  tar -xf $KERNEL_SOURCES/kernel_src.tbz2 -C $KERNEL_SOURCES
  echogreen "Extracting kernel_oot_modules_src.tbz2"
  tar -xf $KERNEL_SOURCES/kernel_oot_modules_src.tbz2 -C $KERNEL_SOURCES
  echogreen "Extracting nvidia_kernel_display_driver_source.tbz2"
  tar -xf $KERNEL_SOURCES/nvidia_kernel_display_driver_source.tbz2 -C $KERNEL_SOURCES
  touch $FLAGS/kernel_check
fi
echoblue "Development build setup completed"


###############################################
##
##    END OF DEVELOPMENT BUILD
##
##############################################
