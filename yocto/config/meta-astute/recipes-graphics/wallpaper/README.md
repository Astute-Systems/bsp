# BushNET Wallpaper Recipe

This recipe installs the BushNET desktop wallpaper for the iMX95 BSP.

## Files Installed

- `/usr/share/pixmaps/bushnet-wallpaper.png` - Standard pixmaps location
- `/usr/share/backgrounds/bushnet-wallpaper.png` - Standard backgrounds location
- `/etc/xdg/weston/weston.ini` - Weston compositor configuration (if Wayland is enabled)

## Wallpaper Details

- **Resolution**: 1536x1024 pixels
- **Format**: PNG (8-bit RGB)
- **Source**: `/home/newman/repos/bsp/yocto/wallpaper/Wallpaper.png`

## Weston Configuration

When Wayland is enabled in `DISTRO_FEATURES`, the recipe automatically creates a Weston configuration file that sets the wallpaper as the desktop background with the following settings:

- Background type: scale-crop (fills screen while maintaining aspect ratio)
- Fallback color: Dark blue (#002244)

## Usage with Other Desktop Environments

For desktop environments other than Weston, the wallpaper is available at:

- `/usr/share/backgrounds/bushnet-wallpaper.png`

Configure your desktop environment or window manager to use this path as the wallpaper.

## Integration

The wallpaper package is automatically included in the image via `local.conf.append`:

```
CORE_IMAGE_EXTRA_INSTALL += " ... wallpaper "
```
