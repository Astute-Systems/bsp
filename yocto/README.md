# iMX95 Yocto BSP

This directory contains the Board Support Package (BSP) for building a Yocto-based Ubuntu distribution for the CompuLab UCM-iMX95 System-on-Module.

## Overview

The iMX95 BSP uses the NXP Yocto Project (Scarthgap) combined with CompuLab's hardware-specific layers to create a complete Linux distribution for the UCM-iMX95 board. The resulting image includes:

- **Development Tools**: git, cmake
- **Qt6 Framework**: Complete Qt6 development environment with Wayland support
- **Package Management**: APT with properly configured sources for software updates
- **System Utilities**: Network management, debugging tools, hardware access utilities
- **Chromium Browser**: Hardware-accelerated web browser with Wayland support

## Prerequisites

### System Requirements

- **Host OS**: Ubuntu 22.04 LTS (recommended) or Ubuntu 24.04 LTS
- **Disk Space**: At least 100GB of free space for the build
- **RAM**: Minimum 8GB, recommended 16GB or more
- **CPU**: Multi-core processor (build time scales with core count)

### Required Packages

Install the necessary packages on your build host:

```bash
sudo apt-get update
sudo apt-get install -y \
    gawk wget git-core diffstat unzip texinfo gcc-multilib \
    build-essential chrpath socat cpio python3 python3-pip \
    python3-pexpect xz-utils debianutils iputils-ping python3-git \
    python3-jinja2 libegl1-mesa libsdl1.2-dev pylint xterm \
    repo git python3 wget curl qemu-user-static
```

## Quick Start

### Building the Image

To build the complete iMX95 Ubuntu image:

```bash
cd /path/to/bsp/yocto
./build
```

The build process will:
1. Initialize the Yocto repo with NXP's i.MX layers
2. Add CompuLab's BSP layers
3. Configure the build environment
4. Build the complete system image

**Note**: The first build can take 4-8 hours depending on your system.

### Build Options

```bash
# Clean build (remove all build artifacts)
./build clean

# Build only the bootloader
./build bootloader

# Enter build environment shell (for manual commands)
./build shell
```

## Directory Structure

```
yocto/
├── build              # Top-level build script
├── config/            # Configuration files
│   ├── imx95-build.conf      # Build configuration
│   └── local.conf.append     # Yocto local.conf additions
├── scripts/           # Build and utility scripts
│   ├── build-imx95.sh        # Main build script
│   └── chroot-test.sh        # Chroot test script
├── docs/              # Additional documentation
└── README.md          # This file
```

After building, a `build/` directory will be created containing:
```
build/
└── yocto/
    ├── sources/       # Yocto layers and metadata
    ├── build-ucm-imx95/  # Build output
    │   └── tmp/
    │       └── deploy/
    │           └── images/
    │               └── ucm-imx95/  # Built images here
    └── .repo/         # Repo tool metadata
```

## Flashing the Image

### Method 1: Bootable SD Card

After the build completes, flash the image to an SD card:

```bash
# Find your image
IMAGE_FILE=$(find build/yocto/build-ucm-imx95/tmp/deploy/images/ucm-imx95/ -name "imx-image-full-ucm-imx95*.wic.zst" | head -n1)

# Flash to SD card (replace /dev/sdX with your SD card device)
sudo zstd -dc ${IMAGE_FILE} | sudo dd bs=1M status=progress of=/dev/sdX
sync
```

**Boot from SD Card:**
1. Power off the board
2. Insert the SD card
3. Short the alt. boot jumper
4. Power on the board

### Method 2: UUU Flashing (Direct to eMMC)

Flash directly to the board's eMMC using NXP's UUU tool:

```bash
# Navigate to the deploy directory
cd build/yocto/build-ucm-imx95/tmp/deploy/images/ucm-imx95/

# Flash complete image (bootloader + rootfs)
sudo uuu -v -b emmc_all imx-boot-tagged imx-image-full-ucm-imx95*.wic.zst
```

**Prepare Board for UUU Flashing:**
1. Power off the board
2. Connect USB cable from host to SoM Serial Download microUSB port
3. Short the SDP boot jumper
4. Power on the board

## Testing the Filesystem

You can test the built filesystem using the chroot script without needing hardware:

```bash
sudo ./scripts/chroot-test.sh
```

This script:
- Mounts the built image
- Sets up QEMU ARM emulation
- Allows you to enter the filesystem as if you were on the target hardware
- Useful for verifying installed packages and configurations

Example test commands inside the chroot:
```bash
git --version
cmake --version
qmake6 --version  # or qmake -v
apt update
apt list --installed | grep -i qt6
```

Type `exit` to leave the chroot environment.

## Customizing the Build

### Adding Packages

To add packages to the image, edit `config/local.conf.append`:

```bash
# Add to CORE_IMAGE_EXTRA_INSTALL
CORE_IMAGE_EXTRA_INSTALL += " your-package-name "
```

### Modifying Configuration

Edit `config/imx95-build.conf` to change:
- Build directories
- Machine configuration
- Distro settings
- Repository URLs and branches

### Using Different Image Recipes

The default image is `imx-image-full`. Other available images include:
- `imx-image-core`: Minimal console image
- `imx-image-multimedia`: Includes multimedia codecs
- `imx-image-desktop`: Full desktop environment

To build a different image, modify the `IMAGE_NAME` variable in `config/imx95-build.conf`.

## Rebuilding After Changes

If you modify the configuration:

```bash
# Clean the previous build
./build clean

# Rebuild
./build
```

For small changes (like adding a package), you can rebuild without cleaning:
```bash
./build
```

## BSP Details

### Base Layers

- **NXP i.MX BSP**: Kernel 6.6.36, L4T version per manifest
- **CompuLab Layers**:
  - `meta-compulab`: Core CompuLab layer
  - `meta-compulab-bsp`: Board-specific configurations
  - `meta-compulab-uefi`: UEFI support
  - `meta-bsp-imx95`: UCM-iMX95 specific layer

### Included Packages

#### Development Tools
- git
- cmake
- gcc/g++
- Python 3
- pkg-config

#### Qt6 Framework
- qtbase (core Qt6 libraries)
- qtdeclarative (QML support)
- qtwayland (Wayland integration)
- Qt development tools

#### System Utilities
- NetworkManager/ModemManager
- Bluetooth utilities (bluez5)
- CAN utilities
- I2C/GPIO tools
- USB utilities
- Memory testing tools

#### Package Management
- APT package manager
- DPKG for .deb packages
- Configured apt sources for updates

## Troubleshooting

### Build Fails with "Fetcher failure"
- Check your internet connection
- Some corporate networks block git:// protocol; use https:// instead
- Try: `git config --global url."https://".insteadOf git://`

### Out of Disk Space
- Clean old builds: `./build clean`
- Yocto uses rm_work to save space, but builds still require substantial storage
- Consider using a separate partition with 100GB+ free space

### Build Errors with Qt6
- Ensure you're using the scarthgap branch
- Qt6 packages may have specific build dependencies
- Check build logs in `build/yocto/build-ucm-imx95/tmp/work/`

### QEMU Chroot Test Fails
- Install qemu-user-static: `sudo apt-get install qemu-user-static`
- Ensure you're running as root: `sudo ./scripts/chroot-test.sh`
- Check that the image was built successfully

## Support and Resources

- **CompuLab UCM-iMX95**: https://www.compulab.com/products/computer-on-modules/ucm-imx95-nxp-i-mx-95-som-system-on-module/
- **CompuLab BSP Repository**: https://github.com/compulab-yokneam/meta-bsp-imx95
- **NXP i.MX Yocto**: https://github.com/nxp-imx/imx-manifest
- **Yocto Project**: https://www.yoctoproject.org/

## License

This BSP configuration follows the licensing of the underlying layers:
- NXP BSP components: Various (see individual layer LICENSE files)
- CompuLab BSP: MIT (see CompuLab repository)
- Yocto Project: Various open source licenses

See individual component licenses for details.
