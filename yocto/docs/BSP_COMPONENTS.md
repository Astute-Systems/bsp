# External BSP Components for iMX95

This document lists the external BSP components used in building the iMX95 Yocto image. These components are automatically downloaded during the build process.

## BSP Layer Sources

The build uses the following meta-layers from external repositories:

### NXP Base Layers (via repo manifest)

Source: https://github.com/nxp-imx/imx-manifest.git
Branch: imx-linux-scarthgap
Manifest: imx-6.6.36-2.1.0.xml

This includes:
- meta-imx (NXP i.MX BSP layer)
- meta-freescale (Freescale/NXP base layer)
- poky (Yocto reference distribution)
- meta-openembedded (Additional recipes)

### CompuLab BSP Layers

The following CompuLab-specific layers are added via local manifest:

#### 1. meta-compulab
- **Repository**: https://github.com/compulab-yokneam/meta-compulab
- **Revision**: a9ef2a47c3ca56f985174b6781882db457bd389f
- **Purpose**: Core CompuLab utilities and configurations

#### 2. meta-compulab-bsp
- **Repository**: https://github.com/compulab-yokneam/meta-compulab-bsp
- **Revision**: 3a9724ca2f7d3a55cef3a648b814c5b26bd18c86
- **Purpose**: Board-specific configurations for CompuLab hardware

#### 3. meta-compulab-uefi
- **Repository**: https://github.com/compulab-yokneam/meta-compulab-uefi
- **Revision**: d9646b4b9ae785f3c36e90a375bc1059b8baf580
- **Purpose**: UEFI support for CompuLab boards

#### 4. meta-bsp-imx95
- **Repository**: https://github.com/compulab-yokneam/meta-bsp-imx95
- **Branch**: scarthgap-6.6.36-EVAL-UCM-iMX95-1.0
- **Purpose**: UCM-iMX95 specific BSP layer with kernel, u-boot, and device configurations

## Key BSP Components

### Kernel
- **Version**: 6.6.36
- **Config**: compulab-mx95_defconfig
- **Recipe**: linux-compulab_6.6.36.bb
- **Source**: Managed by Yocto kernel-yocto class, sourced from CompuLab's kernel repository

### Bootloader (U-Boot)
- **Version**: 2024.04
- **Recipe**: u-boot-compulab_2024.04
- **Source**: CompuLab's customized U-Boot for iMX95

### System Manager
- **Component**: imx-system-manager
- **Version**: 1.0.0
- **Purpose**: i.MX95 system resource management
- **Patches**: CompuLab-specific patches for board support

### OEI (On-Chip Infrastructure)
- **Component**: imx-oei
- **Purpose**: LPDDR5 timing configuration for UCM-iMX95
- **Patches**: CompuLab LPDDR5 timing support

## Device Tree

The device tree files are maintained within the kernel source and meta-bsp-imx95 layer:
- Base DTS files from NXP kernel
- Board-specific overlays and configurations from CompuLab
- Device tree compiler flags: `-@` (enable symbol support for overlays)

## Machine Configuration

**Machine Name**: `ucm-imx95`
**Architecture**: aarch64 (ARM 64-bit)
**SOC Family**: NXP i.MX95
**Board**: CompuLab UCM-iMX95 System-on-Module

## Build Configuration

The build is configured through:
1. **Base Configuration**: From NXP and Yocto defaults
2. **CompuLab Templates**: `templates/local.conf.append` and `templates/bblayers.conf`
3. **Custom Configuration**: `/yocto/config/local.conf.append` (this repository)

## Additional Utilities

### CompuLab Utilities (from meta-compulab)
- `cl-uboot`: U-Boot utilities
- `cl-deploy`: Deployment helpers
- `cl-growfs-rootfs`: Filesystem expansion utility
- `libubootenv-bin`: U-Boot environment tools
- `eeprom-util`: EEPROM management

### Hardware Tools
- `libgpiod-tools`: GPIO access
- `i2c-tools`: I2C bus utilities
- `can-utils`: CAN bus utilities
- `usbutils`: USB device utilities

## Updating BSP Components

To update to newer versions:

1. **Update NXP Manifest**:
   Edit `config/imx95-build.conf` to change:
   - `NXP_MANIFEST_BRANCH`
   - `NXP_MANIFEST_FILE`

2. **Update CompuLab Layers**:
   Edit the manifest template in `scripts/build-imx95.sh` to update:
   - Git revision hashes
   - Branch names

3. **Clean Rebuild**:
   ```bash
   ./build clean
   ./build
   ```

## References

- **CompuLab UCM-iMX95**: https://www.compulab.com/products/computer-on-modules/ucm-imx95-nxp-i-mx-95-som-system-on-module/
- **meta-bsp-imx95**: https://github.com/compulab-yokneam/meta-bsp-imx95
- **NXP i.MX Yocto BSP**: https://www.nxp.com/design/software/embedded-software/i-mx-software/embedded-linux-for-i-mx-applications-processors:IMXLINUX
- **Yocto Project**: https://www.yoctoproject.org/

## License Information

Each component has its own license:
- **Linux Kernel**: GPL-2.0
- **U-Boot**: GPL-2.0+
- **Yocto Recipes**: MIT (typically)
- **NXP Components**: Various (see NXP license agreements)
- **CompuLab Components**: MIT (see repository licenses)

Refer to individual component repositories for detailed license information.
