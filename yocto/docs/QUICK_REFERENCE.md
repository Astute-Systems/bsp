# iMX95 BSP Quick Reference

Quick reference guide for common tasks with the iMX95 Yocto BSP.

## Quick Start

```bash
# Navigate to yocto directory
cd yocto/

# Build the complete image (first build takes 4-8 hours)
./build

# Build with multiple cores for faster builds
./build

# Enter build environment shell
./build shell
```

## Building

### Full Image Build
```bash
./build
```

### Bootloader Only
```bash
./build bootloader
```

### Clean Build
```bash
./build clean
./build
```

### Build Specific Recipes
```bash
./build shell
bitbake linux-compulab       # Kernel only
bitbake u-boot-compulab       # U-Boot only
bitbake imx-image-core        # Minimal image
```

## Flashing

### SD Card (Linux Host)
```bash
# Find the image
IMAGE=$(find build/yocto/build-ucm-imx95/tmp/deploy/images/ucm-imx95/ -name "*.wic.zst" | head -n1)

# Flash to SD card (replace sdX with your device)
sudo zstd -dc ${IMAGE} | sudo dd bs=1M status=progress of=/dev/sdX
sync
```

### UUU Flashing (Direct to eMMC)
```bash
# Install UUU tool
sudo apt-get install mfgtools

# Navigate to images directory
cd build/yocto/build-ucm-imx95/tmp/deploy/images/ucm-imx95/

# Flash bootloader and rootfs
sudo uuu -v -b emmc_all imx-boot-tagged imx-image-full-ucm-imx95*.wic.zst

# Flash bootloader only
sudo uuu -v -b emmc imx-boot-tagged
```

### Board Setup for UUU
1. Power off board
2. Connect USB (type A to microUSB Serial Download port)
3. Short SDP boot jumper
4. Power on board

## Testing

### Chroot Test (No Hardware Required)
```bash
# Build must complete first
sudo ./scripts/chroot-test.sh

# Inside chroot, test packages
git --version
cmake --version
qmake6 --version
apt update
```

### Serial Console
```bash
# Connect to UART (usually ttyUSB0 or ttyUSB1)
sudo minicom -D /dev/ttyUSB0 -b 115200

# Or with screen
sudo screen /dev/ttyUSB0 115200
```

## Customization

### Add Packages
Edit `config/local.conf.append`:
```bitbake
CORE_IMAGE_EXTRA_INSTALL += " your-package "
```

### Change Image Type
Edit `config/imx95-build.conf`:
```bash
IMAGE_NAME="imx-image-multimedia"  # or imx-image-core
```

### Add Custom Layer
```bash
./build shell
bitbake-layers add-layer /path/to/meta-custom
```

### Modify Kernel Config
```bash
./build shell
bitbake -c menuconfig linux-compulab
bitbake linux-compulab
```

## Troubleshooting

### Build Fails - Fetcher Error
```bash
# Use HTTPS instead of git://
git config --global url."https://".insteadOf git://
```

### Out of Disk Space
```bash
# Clean old builds
./build clean

# Or manually clean
rm -rf build/yocto/build-ucm-imx95/tmp
```

### Repo Sync Issues
```bash
cd build/yocto/
repo sync --force-sync
```

### Build Hangs
```bash
# Check build status in another terminal
cd build/yocto/build-ucm-imx95/
tail -f tmp/log/cooker/ucm-imx95/console-latest.log
```

### QEMU Chroot Fails
```bash
# Install qemu-user-static
sudo apt-get install qemu-user-static binfmt-support

# Check if registered
update-binfmts --display qemu-aarch64
```

## Common Bitbake Commands

```bash
# Enter build environment first
./build shell

# Clean specific recipe
bitbake -c cleansstate <recipe-name>

# Rebuild without cleaning
bitbake <recipe-name>

# Get recipe info
bitbake -e <recipe-name> | grep ^S=

# List all recipes
bitbake-layers show-recipes

# Show recipe dependencies
bitbake -g <recipe-name>
```

## Directory Locations

```
yocto/
├── build/yocto/                          # Build root
│   ├── sources/                          # Yocto layers
│   ├── build-ucm-imx95/                  # Build directory
│   │   ├── conf/                         # Build configuration
│   │   └── tmp/
│   │       ├── deploy/images/ucm-imx95/  # Built images ★
│   │       ├── deploy/deb/               # .deb packages
│   │       ├── work/                     # Build work area
│   │       └── log/                      # Build logs
│   └── .repo/                            # Repo metadata
```

## Performance Tips

### Use RAM Disk for Builds
```bash
# Create 40GB RAM disk
sudo mkdir -p /mnt/ramdisk
sudo mount -t tmpfs -o size=40G tmpfs /mnt/ramdisk

# Move build directory
mv build/yocto /mnt/ramdisk/
ln -s /mnt/ramdisk/yocto build/yocto
```

### Parallel Builds
Edit `config/local.conf.append`:
```bitbake
BB_NUMBER_THREADS = "16"  # Number of CPU cores
PARALLEL_MAKE = "-j 16"   # Parallel make jobs
```

### Use sstate Cache
Keep the sstate cache between builds:
```bitbake
SSTATE_DIR = "/path/to/persistent/sstate-cache"
```

## Useful Environment Variables

```bash
# Before running ./build
export MACHINE=ucm-imx95              # Target machine
export DISTRO=fsl-imx-xwayland        # Distribution
export BB_NUMBER_THREADS=16           # Build threads
```

## Package Management on Target

### Configure APT Sources
```bash
# On target device
sudo nano /etc/apt/sources.list
```

Add:
```
deb http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-security main restricted universe multiverse
```

### Use APT
```bash
sudo apt update
sudo apt install <package>
sudo apt upgrade
```

## Resources

- **Full Documentation**: [README.md](README.md)
- **APT Configuration**: [docs/APT_CONFIGURATION.md](docs/APT_CONFIGURATION.md)
- **BSP Components**: [docs/BSP_COMPONENTS.md](docs/BSP_COMPONENTS.md)
- **CompuLab UCM-iMX95**: https://www.compulab.com/products/computer-on-modules/ucm-imx95-nxp-i-mx-95-som-system-on-module/
- **Yocto Documentation**: https://docs.yoctoproject.org/

## Support

For issues or questions:
1. Check build logs: `build/yocto/build-ucm-imx95/tmp/log/`
2. Review Yocto documentation
3. Check CompuLab BSP repository issues
4. Consult NXP i.MX documentation
