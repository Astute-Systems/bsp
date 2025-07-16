# Board Support Packages

## Apply GXA Configs

The GXA specific configuration files:

* Orin-gxa-1-pinmux.dtsi
* Orin-gxa-1-gpio-default.dtsi
* Orin-gxa-1-padvoltage-default.dtsi
* jetson-agx-orin-gxa-1.conf <**TBC**>
* tegra234-gxa-1-overlay.dts <**TBC**>

:must be stored in the ./config folder.

Run:

```./scripts/gxa-patch-fs.sh```

: to copy the board specific configuration files to the required location.

**Any updates to the config files above require the patch step to be re-run. Changes to dtbs require additional steps outlined below.**

## Build Required Files

It is nessecary to build the kernel and out-of-tree modules before building the device tree binaries.

Run: ```./scripts/gxa-make.sh all```

: to build all of the above (including dtbs).

**If any changes have been made to the device tree overlay file, it will be nessecary to re-run:**

```./scripts/gxa-make.sh dtbs```

: to compile the overlay file into the nessecary DTB file.
It is also possible to run:

```./scripts/gxa-make.sh kernel```

: to re-build the kernel; or run:

```./scripts/gxa-make.sh modules```

: to re-build the kernel out-of-tree modules;

### Flashing

Once the setup steps have been completed, connect the development machine to the GXA debug port via usb. Run:
```./scripts/gxa-flash.sh```
: to flash the board.

### Post Install

Once the unit has been booted, it will be nessecary to install the Analog Video Driver. **NB:** This could probably be
done during the apply binaries script (or by replicating their chroot process)

```bash
    sudo apt install /opt/tw686x*.deb
```

### Creating the installer

Once the system has been approved for release, please run:

```./scripts/gxa-pack.sh```

: this will create an installer called ```gxa-installer_<version>.run``` in the ```./builds/``` directory. This file can
then be deployed to end users, to build and flash SystemX onto their GXA systems.

### Testing the Installer

## PART 1 - Development Process

Copy the installer file to a clean environment (fresh install / docker container/ dev environment) and run the installer
to check that there are no missing dependencies and that the expected file structure is build correctly in a new environment.

## PART 2 - Deployment Process

* Copy the installer to a **HOST** machine that will be used to build and flash SystemX to the GXA. A **Host** machine
should be connected to the internet, and have USB access; the user should have administrative privileges via sudo. The
installer also requires the user to have a home directory.

* Run the ```sudo ./gxa-installer_<version>.run``` on the command-line from the directory containing the installer files.
* During the flashing process, there are four options:
  
    * Build and Flash - will build the system image and flash it to the GXA. First you must connect the development machine to the GXA debug port via usb.
    * Build now, flash later.
    * Flash a file that was previously built.
    * Exit the flashing program.

JUNE 2025

The ```./config``` directory contains the following important files

* the filesystem overlay including the necessary DTBs and bootloader files, the MOTD and the bsp-release file
* the l4t-sources.xml which details the sources for each l4t build
* the readme which is built as part of the installer.
