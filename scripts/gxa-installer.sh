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
# CREATE LINK IN HOME DIRECTORY
#
#######################################################

# Remove link if it exists
if [ -L /home/${SUDO_USER}/AstuteSys ]; then
   unlink /home/${SUDO_USER}/AstuteSys
fi

#######################################################
#
# SOURCE THE ENVIRONMENT VARIABLES -  MOSTLY DIRECTORIES
#
#######################################################
source ./config/gxa-build.conf

#######################################################
#
# ADDRESS ARGS
#
#######################################################
# Check for arguments
L4T_VERSION=$1
echoblue "GXA Installer: Creating symlink in home directory to /opt/AstuteSys/${L4T_VERSION}"
ln -s /opt/AstuteSys/${L4T_VERSION} /home/${SUDO_USER}/AstuteSys

#######################################################
#
# Cat the README.txt file and wite for user input
#
#######################################################
cat ./README.txt
echo ""
echored "NOTE: Please ensure you have an internet connection before proceeding"
echo ""
read -p "Press any key to continue (CTRL+C to cancel)"

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

# Install the as-pinctl command onto the HOST machine
cp ./as-pinctl /usr/bin
# Run the install scripts
echoblue "GXA Installer: Downloading and extracting sources"
./scripts/gxa-init-build-machine.sh prod $L4T_VERSION
echoblue "GXA Installer: Patching filesystem"
./scripts/gxa-patch-fs.sh prod
echoblue "GXA Installer: Preparing to flash"
./scripts/gxa-flash.sh $FLASH
echoblue "GXA Installer: Complete, ~/AstuteSys/scripts/gxa-flash.sh to reenter the flash tool"
