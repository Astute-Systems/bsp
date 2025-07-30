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

# Second arg is release version
L4T_RELEASE=$2

source ./scripts/gxa-utils.sh $L4T_RELEASE
echoblue "GXA-1 Initialization Script"

echo "L4T Version: $L4T_VERSION"

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
echoblue "Installing necessary packages for $RELEASE build"
sudo apt-get update -y $APT_EXTRA_ARGS
sudo apt-get install -y $APT_EXTRA_ARGS qemu-user-static flex bison bc libxml2-utils makeself cpio pkg-config dialog dpkg wget sudo lbzip2 make cmake gcc g++ libgpiod-dev libftdi1-dev libgflags-dev
echo "L4T Version: $L4T_VERSION"

echoblue "Reading L4T Version from XML file"
grunt=$(xmllint --xpath "string(/l4tSources/l4t${RELEASE})" ${XML_FILE})
if [ -z "$grunt" ]; then
    echogreen "No user specified L4T version"
    get_default
else
  grunt=$(xmllint --xpath "string(/l4tSources/l4t${RELEASE})" ${XML_FILE})
  
  #check if grunt is empty
  if [ -z "$grunt" ]; then
      echo "User specified L4T version $RELEASE not found in XML file."
      echo "Falling back to latest L4T version."
      get_default
  fi
fi
echo "L4T Version: $L4T_VERSION"

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

COMPILER=$(tar -xvf $SOURCES/$TOOLCHAIN_FILENAME -C $KERNEL_SOURCES | head -n 1 | cut -d '/' -f 1)
if [ ! -f $FLAGS/toolchain_check ]; then
  echogreen "Extracting $TOOLCHAIN_FILENAME"
  tar -xf $SOURCES/$TOOLCHAIN_FILENAME -C $KERNEL_SOURCES

  # Replace the COMPILER value in gxa-build.conf
  sed -i "/^COMPILER=/c\COMPILER=$COMPILER" $CONFIG/gxa-build.conf

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
