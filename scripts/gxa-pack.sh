#!/bin/bash -e

L4T_VERSION=$1

# Include gza-utils.sh for utility functions
source ./scripts/gxa-utils.sh $ARG1
echoblue "Building GXA Installer package"
get_default

README_L4T_VERSION="L4T${L4T_VERSION}"

#######################################################
#
# SOURCE THE ENVIRONMENT VARIABLES -  MOSTLY DIRECTORIES
#
#######################################################

source ./config/gxa-build.conf

#######################################################
#
# SETUP THE PACKAGE DIRECTORY
#
#######################################################  

# create build directory
DIR=$BUILD/gxa-installer

echoblue "Building GXA Installer package in $DIR"
# create the build directory if it does not exist
if [ ! -d $DIR ]; then
  mkdir -p $DIR
fi


# Remove the DIR if it exists
if [ -d "$DIR" ]; then
  rm -rf "$DIR"
fi

mkdir -p $DIR/scripts

#######################################################
#
# Build as-pinctl, make sure its up to date
#
####################################################### 
if [ ! -f $FLAGS/as_pinctl_build ]; then
  cd $BUILD
  cmake ..
  make as-pinctl
  cd ..
  cp $BUILD/bin/as-pinctl $DIR
fi

#######################################################
#
# COPY SETUP FILES TO THE PACKAGE DIRECTORY
#
#######################################################  

cp -r config $DIR
cp -p LICENSE $DIR/.
cp -p scripts/gxa-installer-cleanup.sh $DIR/scripts
cp -p scripts/gxa-installer.sh $DIR/scripts
cp -p scripts/gxa-init-build-machine.sh $DIR/scripts
cp -p scripts/gxa-patch-fs.sh $DIR/scripts
cp -p scripts/gxa-flash.sh $DIR/scripts
cp -p scripts/gxa-utils.sh $DIR/scripts
cp -pr scripts/${README_L4T_VERSION}/etc $DIR/config/l4t-overlay/rootfs
cp -p scripts/${README_L4T_VERSION}/README.txt $DIR/.

#######################################################
#
# PATCH THE README FILE
#
#######################################################  


echoblue "Patching files in $DIR"

# Store the short git hash
GIT_HASH=$(git rev-parse --short HEAD)

# Read the release version from version file in root
# First line is major version, second line is minor version, third line is patch version
RELEASE_MAJOR=$(sed -n '1p' $PROJECT_ROOT/version | tr -d '\n')
RELEASE_MINOR=$(sed -n '2p' $PROJECT_ROOT/version | tr -d '\n')
RELEASE_PATCH=$(sed -n '3p' $PROJECT_ROOT/version | tr -d '\n')
RELEASE_VERSION="${RELEASE_MAJOR}.${RELEASE_MINOR}.${RELEASE_PATCH}"

# Sed replace %data% with the current date
sed -i "s/%year%/$(date +%Y)/g" $DIR/LICENSE
sed -i "s/%date%/$(date)/g" $DIR/README.txt
sed -i "s/%date%/$(date)/g" $DIR/config/l4t-overlay/rootfs/etc/bsp-release

# Sed replace the L4T version 
sed -i "s/%l4t_version%/${README_L4T_VERSION}/g" $DIR/README.txt
sed -i "s/%l4t_version%/${README_L4T_VERSION}/g" $DIR/config/l4t-overlay/rootfs/etc/bsp-release
sed -i "s/%l4t_version%/${README_L4T_VERSION}/g" $DIR/config/l4t-overlay/rootfs/etc/motd

# Sed replace the BSP version 
sed -i "s/%release_version%/${RELEASE_VERSION}/g" $DIR/README.txt
sed -i "s/%release_version%/${RELEASE_VERSION}/g" $DIR/config/l4t-overlay/rootfs/etc/bsp-release
# Sed replace the git hash with %hash%
sed -i "s/%hash%/$GIT_HASH/g" $DIR/README.txt
sed -i "s/%hash%/#$GIT_HASH/g" $DIR/config/l4t-overlay/rootfs/etc/bsp-release

# Update MOTD with correct L4T version
# Replace line 8 with the L4T version
sed -i "8s/.*/  L4T Version: L4T${L4T_VERSION}/" $DIR/config/l4t-overlay/rootfs/etc/motd

echoblue "Patching README file with L4T version and release version"
cat  $DIR/config/l4t-overlay/rootfs/etc/bsp-release
echoblue "Patching README file with L4T version and release version"
cat  $DIR/README.txt
echoblue "Patching MOTD file with L4T version"
cat  $DIR/config/l4t-overlay/rootfs/etc/motd

#######################################################
#
# CREATE THE PACKAGE
#
#######################################################
echoblue "Creating the GXA Installer package"

# Define the target directory
TARGET_DIR="/opt/AstuteSys/${L4T_VERSION}"

# Get enc OS_VERSION
if [ -z "$OS_VERSION" ]; then
  OS_VERSION="ubuntu-22.04"
fi  

        # --clean /opt/AstuteSys/scripts/gxa-installer-cleanup.sh \
makeself --keep-umask --target "$TARGET_DIR" $DIR ${DIR}_${L4T_VERSION}${OS_VERSION}.run \
        "Astute Systems GXA-1 software installer" \
        ./scripts/gxa-installer.sh ${L4T_VERSION}

echoblue "Created new release ${DIR}_${L4T_VERSION}${OS_VERSION}.run"
