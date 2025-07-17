
Astute Systems GXA-1 Linux 4 Tegra Board Support Package (BSP)

  Support: https://astutesys.com/wiki/knowledge-base/
  Created: %date%
  Linux4Tegra version: %l4t_version%
  BSP Release Version: %release_version%
  Git Hash: %hash%
 
# Flashing

Once the build environment is setup, the GXA-Flashing utility will be run. This program gives the following options.

* Build the System Image and Flash the Device
* Build the System Image and Flash the Device Later
* Flash a System Image Which has Previously Been Built
* Retest for GXA-1 in recovery mode
* Exit the Flashing Utility

To re run the flashing tool.

```
HOST $ cd ~/AstuteSys
HOST $ sudo ./scripts/gxa-flash.sh
```

To re-run the flashing utility helper at a later time, cd to ~/AstuteSys and run ```./scripts/gxa-flash.sh``` from the scripts directory.
Alternatively, you can manually flash the target from the command line.

```
HOST $ sudo ./as-pinctrl -recovery
HOST $ cd ~/AstuteSys/l4t/Linux_for_Tegra/
HOST $ sudo ./flash.sh jetson-agx-orin-gxa-1 mmcblk0p1
```

> NOTE: GXA-1 need to be in recovery mode ready to flash. Please refer to the Software Reference Manual if flashing manually.

# Release Notes

Video driver not included. Please install the analogue video driver from our website 
if you require PAL/NTSC video support.

Please refer to the Software Reference Manual for more information on how to install 
the video driver .deb install package.

# Known Issues

none

