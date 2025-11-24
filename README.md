
[![Ubuntu 22.04 Intel BSP](https://github.com/Astute-Systems/bsp/actions/workflows/build-ubuntu-22.04-amd64-bsp.yaml/badge.svg)](https://github.com/Astute-Systems/bsp/actions/workflows/build-ubuntu-22.04-amd64-bsp.yaml)
[![Ubuntu 24.04 Intel BSP](https://github.com/Astute-Systems/bsp/actions/workflows/build-ubuntu-24.04-amd64-bsp.yaml/badge.svg)](https://github.com/Astute-Systems/bsp/actions/workflows/build-ubuntu-24.04-amd64-bsp.yaml)

# Board Support Packages (BSP)

## Overview

This repository contains scripts and configuration files for building, configuring, and flashing board support packages (BSP) for multiple platforms:

- **GXA** (Jetson AGX Orin platforms) - NVIDIA L4T-based BSP
- **iMX95** (CompuLab UCM-iMX95) - Yocto-based Ubuntu BSP

## Directory Structure

- `./yocto/`  
  iMX95 Yocto-based BSP for CompuLab UCM-iMX95. See [yocto/README.md](yocto/README.md) for details.
- `./config/`  
  GXA board-specific configuration files, device tree overlays, and bootloader files.
- `./scripts/`  
  GXA utility scripts for patching, building, packaging, and flashing.
- `./build/`  
  Output directory for build artifacts and installers.
- `./src`
  The device FTDI tool [as-pinctl](src/as-pinctl/README.md) to control recovery/reboot and debug UART

## Supported Platforms

### iMX95 (CompuLab UCM-iMX95)

For building Ubuntu-based images for the iMX95 platform:
- See the [yocto/README.md](yocto/README.md) for complete documentation
- Quick start: `cd yocto && ./build`

---

### GXA (Jetson AGX Orin)

## Configuration Files

Store the following GXA-specific configuration files in the `./config` directory see ```config/l4t-overlay/jetson-agx-orin-gxa-1.conf```

 > Any updates to the config file requires re-running the patch step below.

## Setup & Patch

To copy board-specific configuration files to their required locations, run:

```bash
./scripts/gxa-patch-fs.sh
```

## Building

Before building device tree binaries, build the kernel and out-of-tree modules:

```bash
./scripts/gxa-make.sh all
```

If you modify the device tree overlay file, recompile the DTB:

```bash
./scripts/gxa-make.sh dtbs
```

Other build options:

- Rebuild kernel:  

  ```bash
  ./scripts/gxa-make.sh kernel
  ```

- Rebuild out-of-tree modules:  

  ```bash
  ./scripts/gxa-make.sh modules
  ```

## Flashing the Board

Connect your development machine to the GXA debug port via USB.  
To flash the board, run:

```bash
./scripts/gxa-flash.sh
```

## Post-Install Steps

After booting, install the Analog Video Driver:

```bash
sudo apt install /opt/tw686x*.deb
```

 > This step could be automated in future releases.

## Creating the Installer

To package the BSP for deployment, run:

```bash
./scripts/gxa-pack.sh
```

This creates an installer named `gxa-installer_<version>.run` in the `./build/` directory.

## Testing the Installer

### Development Process

- Copy the installer to a clean environment (fresh install, Docker container, or dev environment).
- Run the installer to verify dependencies and file structure.

### Deployment Process

- Copy the installer to a **host** machine with internet access, USB connectivity, and sudo privileges.
- Run the installer:

  ```bash
  sudo ./gxa-installer_<version>.run
  ```

- During flashing, choose from:
    - Build and Flash (requires USB connection to GXA debug port)
    - Build now, flash later
    - Flash a previously built image
    - Exit

## Notes

- The `./config` directory contains:
    - Filesystem overlay (DTBs, bootloader files, MOTD, bsp-release)
    - `l4t-sources.xml` (source details for each L4T build)
    - README (built as part of the installer)
