# iMX95 BSP Example Workflow

This document provides step-by-step examples for common workflows with the iMX95 BSP.

## Example 1: First Time Setup and Build

Complete workflow for building the iMX95 image from scratch.

### Prerequisites

```bash
# Install required packages (Ubuntu 22.04/24.04)
sudo apt-get update
sudo apt-get install -y \
    gawk wget git-core diffstat unzip texinfo gcc-multilib \
    build-essential chrpath socat cpio python3 python3-pip \
    python3-pexpect xz-utils debianutils iputils-ping python3-git \
    python3-jinja2 libegl1-mesa libsdl1.2-dev pylint xterm \
    python3-distutils python3-setuptools zstd lz4 curl

# Install Google repo tool
sudo curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
sudo chmod a+x /usr/local/bin/repo

# Verify installation
repo version
```

### Clone and Build

```bash
# Clone the BSP repository
git clone https://github.com/Astute-Systems/bsp.git
cd bsp/yocto

# Start the build (this will take 4-8 hours on first build)
./build

# The build will:
# 1. Initialize repo with NXP manifests
# 2. Download CompuLab BSP layers
# 3. Setup build environment
# 4. Build the complete image
```

### Monitor Build Progress

```bash
# In another terminal, monitor the build
cd bsp/build/yocto/build-ucm-imx95
tail -f tmp/log/cooker/ucm-imx95/console-latest.log
```

### After Build Completes

```bash
# Find the built image
cd bsp/build/yocto/build-ucm-imx95/tmp/deploy/images/ucm-imx95/
ls -lh imx-image-full-ucm-imx95*.wic.zst

# Image location for flashing
IMAGE_FILE=$(realpath imx-image-full-ucm-imx95*.wic.zst)
echo "Image: $IMAGE_FILE"
```

## Example 2: Flash to SD Card

Flash the built image to an SD card for booting.

```bash
# Identify your SD card device
lsblk

# Example output:
# NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
# sda           8:0    0 232.9G  0 disk
# └─sda1        8:1    0 232.9G  0 part /
# sdb           8:16   1  14.9G  0 disk    ← SD Card
# └─sdb1        8:17   1  14.9G  0 part

# WARNING: Double-check the device! This will erase all data.
# Replace /dev/sdX with your SD card device (e.g., /dev/sdb)

# Unmount any mounted partitions
sudo umount /dev/sdX*

# Flash the image
cd bsp/build/yocto/build-ucm-imx95/tmp/deploy/images/ucm-imx95/
sudo zstd -dc imx-image-full-ucm-imx95*.wic.zst | sudo dd bs=1M status=progress of=/dev/sdX

# Sync to ensure all data is written
sync

# Safely remove the SD card
sudo eject /dev/sdX
```

### Boot from SD Card

```bash
# On the UCM-iMX95 board:
# 1. Power off the board
# 2. Insert the SD card
# 3. Short the alt. boot jumper
# 4. Connect serial console (115200 8N1)
# 5. Power on the board

# Connect via serial console
sudo minicom -D /dev/ttyUSB0 -b 115200

# Or with screen
sudo screen /dev/ttyUSB0 115200

# Default login:
# Username: root
# Password: root (as configured in local.conf.append)
```

## Example 3: Configure APT and Install Packages

Configure package management and install software on the target.

```bash
# On the target device (after booting)

# Configure network (if not using DHCP)
ip addr add 192.168.1.100/24 dev eth0
ip route add default via 192.168.1.1
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Or use NetworkManager
nmcli device wifi connect "YourSSID" password "YourPassword"

# Configure APT sources
cat > /etc/apt/sources.list << 'EOF'
deb http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-security main restricted universe multiverse
EOF

# Update package lists
apt update

# Verify pre-installed development tools
git --version
cmake --version
qmake6 --version

# Install additional packages
apt install -y vim htop curl wget build-essential

# Upgrade system packages
apt upgrade -y
```

## Example 4: Test Filesystem Without Hardware

Test the built filesystem using QEMU chroot.

```bash
# Install QEMU tools (on host)
sudo apt-get install qemu-user-static binfmt-support

# Run chroot test script
cd bsp/yocto
sudo ./scripts/chroot-test.sh

# You'll enter a shell inside the ARM64 filesystem
# Test the installed components:
git --version
cmake --version
qmake6 --version

# Check Qt6 installation
qmake6 -query

# Test APT (won't have network in chroot, but can check configuration)
apt list --installed | grep -i qt6
apt list --installed | grep git
apt list --installed | grep cmake

# Exit chroot
exit
```

## Example 5: Customize and Rebuild

Add custom packages and rebuild the image.

```bash
# Edit configuration to add packages
cd bsp/yocto
nano config/local.conf.append

# Add to the file:
# CORE_IMAGE_EXTRA_INSTALL += " python3-dev python3-pip nodejs "

# Rebuild without cleaning (faster)
./build

# The build system will:
# 1. Detect configuration changes
# 2. Build only the new packages
# 3. Regenerate the rootfs
# 4. Create new image

# New image will be in the same location:
ls -lh build/yocto/build-ucm-imx95/tmp/deploy/images/ucm-imx95/imx-image-full-ucm-imx95*.wic.zst
```

## Example 6: UUU Flashing to eMMC

Flash directly to the board's internal eMMC storage.

### Install UUU Tool

```bash
# Option 1: From package
sudo apt-get install mfgtools

# Option 2: From source
git clone https://github.com/nxp-imx/mfgtools.git
cd mfgtools
cmake .
make
sudo make install
```

### Prepare Board for Flashing

```bash
# Hardware setup:
# 1. Power off the UCM-iMX95 board
# 2. Connect USB cable: Host (Type A) → Board (Serial Download microUSB)
# 3. Short the SDP boot jumper
# 4. Power on the board

# Verify board is detected
lsusb | grep NXP

# Example output:
# Bus 001 Device 015: ID 1fc9:014e NXP Semiconductors SE Blank 95
```

### Flash Image

```bash
# Navigate to images directory
cd bsp/build/yocto/build-ucm-imx95/tmp/deploy/images/ucm-imx95/

# Flash complete image (bootloader + rootfs)
sudo uuu -v -b emmc_all imx-boot-tagged imx-image-full-ucm-imx95*.wic.zst

# The flashing process will show progress:
# uuu (Universal Update Utility) for nxp imx chips -- libuuu_1.x.x
# 
# Success 1    Failure 0
# 
# 1:92     5/ 5 [Done                              ] FB: done
```

### Boot from eMMC

```bash
# After flashing:
# 1. Power off the board
# 2. Remove the SDP boot jumper
# 3. Disconnect USB cable
# 4. Connect serial console
# 5. Power on the board
# 
# The board will boot from eMMC

# Connect via serial
sudo minicom -D /dev/ttyUSB0 -b 115200
```

## Example 7: Kernel Development

Modify and rebuild the kernel.

```bash
# Enter build environment
cd bsp/yocto
./build shell

# Configure kernel
bitbake -c menuconfig linux-compulab

# After making changes in menuconfig, save and exit

# Build kernel
bitbake linux-compulab

# Deploy kernel only (to existing rootfs)
bitbake -c deploy linux-compulab

# The new kernel is in:
ls -lh tmp/deploy/images/ucm-imx95/Image

# To include in complete image, rebuild the image
bitbake imx-image-full
```

## Example 8: Add Custom Application

Create and integrate a custom application.

### Create Recipe Directory

```bash
cd bsp/yocto/build/yocto
mkdir -p sources/meta-custom/recipes-app/myapp/files
cd sources/meta-custom
```

### Create Recipe

```bash
# Create myapp.bb
cat > recipes-app/myapp/myapp_1.0.bb << 'EOF'
SUMMARY = "My Custom Application"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://myapp.c"

S = "${WORKDIR}"

do_compile() {
    ${CC} ${CFLAGS} ${LDFLAGS} myapp.c -o myapp
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 myapp ${D}${bindir}
}
EOF
```

### Create Application Source

```bash
cat > recipes-app/myapp/files/myapp.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from iMX95!\n");
    return 0;
}
EOF
```

### Add Layer and Build

```bash
# Add custom layer
bitbake-layers add-layer ../sources/meta-custom

# Add app to image in config/local.conf.append
echo 'IMAGE_INSTALL:append = " myapp "' >> ../../config/local.conf.append

# Rebuild image
bitbake imx-image-full
```

## Example 9: SDK Generation

Generate an SDK for cross-compilation.

```bash
# Enter build environment
cd bsp/yocto
./build shell

# Build SDK
bitbake -c populate_sdk imx-image-full

# SDK will be created in:
ls -lh tmp/deploy/sdk/

# Install SDK on host
./tmp/deploy/sdk/fsl-imx-xwayland-glibc-x86_64-imx-image-full-armv8a-ucm-imx95-toolchain-*.sh

# Source SDK environment
source /opt/fsl-imx-xwayland/*/environment-setup-armv8a-poky-linux

# Verify cross-compiler
$CC --version

# Cross-compile application
$CC -o myapp myapp.c
file myapp  # Should show: ELF 64-bit LSB executable, ARM aarch64
```

## Troubleshooting Examples

### Example: Fix Build Error

```bash
# If build fails, check the log
cd bsp/build/yocto/build-ucm-imx95

# Find the failed recipe
grep -r "ERROR:" tmp/log/cooker/ucm-imx95/

# Clean and rebuild specific recipe
bitbake -c cleansstate <failed-recipe>
bitbake <failed-recipe>

# If persistent, clean all
cd ../../yocto
./build clean
./build
```

### Example: Update All Layers

```bash
# Update repo sources
cd bsp/build/yocto
repo sync --force-sync

# Rebuild
cd ../../yocto
./build clean
./build
```

## Next Steps

- Explore [Quick Reference](QUICK_REFERENCE.md) for common commands
- Read [APT Configuration](APT_CONFIGURATION.md) for package management
- Check [BSP Components](BSP_COMPONENTS.md) for layer details
- Review main [README](../README.md) for comprehensive documentation
