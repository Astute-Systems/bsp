# Board Support Packages (BSP) for GXA

## Overview

This repository contains scripts and configuration files for building, configuring, and flashing the GXA board support package (BSP) for Jetson AGX Orin platforms.

## Directory Structure

- `./config/`  
  Contains board-specific configuration files, device tree overlays, and bootloader files.
- `./scripts/`  
  Utility scripts for patching, building, packaging, and flashing.
- `./build/`  
  Output directory for build artifacts and installers.
- `./src`
  The device FTDI tool [as-pinctl](src/as-pinctl/README.md) to control recovery/reboot and debug UART

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
