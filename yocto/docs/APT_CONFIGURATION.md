# APT Sources Configuration for iMX95 Ubuntu Image

This document describes how APT sources are configured in the iMX95 Yocto image.

## Overview

The image is built with APT package management enabled through Yocto's `package-management` feature. This allows software updates and package installation on the target system.

## Configuration in Yocto

The APT configuration is set in `/yocto/config/local.conf.append`:

```bitbake
# Package management and apt sources
CORE_IMAGE_EXTRA_INSTALL += " apt dpkg "
PACKAGE_CLASSES = "package_deb"
EXTRA_IMAGE_FEATURES += "package-management"
```

This configuration:
- Includes APT and DPKG in the image
- Uses Debian package format (.deb)
- Enables package management features

## Default APT Sources

After building, the image will have APT configured but needs repository sources configured for updates. The default Yocto build doesn't automatically configure external repository mirrors.

## Configuring APT Sources on Target

After flashing the image to your device, you need to configure APT sources for Ubuntu packages.

### Option 1: Use Ubuntu Ports (for ARM64)

Create or edit `/etc/apt/sources.list` on the target:

```bash
# Ubuntu Ports repositories for ARM64
deb http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-backports main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-security main restricted universe multiverse
```

Replace `jammy` with your desired Ubuntu version:
- `focal` - Ubuntu 20.04 LTS
- `jammy` - Ubuntu 22.04 LTS
- `noble` - Ubuntu 24.04 LTS

### Option 2: Custom Recipe (Advanced)

To pre-configure APT sources in the image, create a custom Yocto recipe:

Create `recipes-core/custom-apt-sources/custom-apt-sources.bb`:

```bitbake
SUMMARY = "Custom APT sources configuration"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://sources.list"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${sysconfdir}/apt
    install -m 0644 ${WORKDIR}/sources.list ${D}${sysconfdir}/apt/sources.list
}

FILES:${PN} = "${sysconfdir}/apt/sources.list"
```

Create `recipes-core/custom-apt-sources/files/sources.list`:

```
deb http://ports.ubuntu.com/ubuntu-ports/ jammy main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports/ jammy-security main restricted universe multiverse
```

Add to your `local.conf.append`:
```bitbake
IMAGE_INSTALL:append = " custom-apt-sources "
```

## Using APT on Target

Once APT sources are configured:

```bash
# Update package lists
sudo apt update

# Install packages
sudo apt install <package-name>

# Upgrade installed packages
sudo apt upgrade

# Search for packages
apt search <keyword>
```

## Package Feed from Build

The Yocto build creates a local package feed in:
```
build/yocto/build-ucm-imx95/tmp/deploy/deb/
```

You can host this as a local repository:

1. Copy the `deb` directory to a web server
2. On the target, add to `/etc/apt/sources.list`:
   ```
   deb [trusted=yes] http://your-server/deb/aarch64 ./
   deb [trusted=yes] http://your-server/deb/ucm_imx95 ./
   deb [trusted=yes] http://your-server/deb/all ./
   ```

3. Run `apt update` on the target

## HTTPS Support

To use HTTPS APT sources, ensure the image includes CA certificates:

Add to `local.conf.append`:
```bitbake
CORE_IMAGE_EXTRA_INSTALL += " ca-certificates "
```

## Proxy Configuration

If building behind a proxy, configure APT proxy on the target:

Create `/etc/apt/apt.conf.d/proxy.conf`:
```
Acquire::http::Proxy "http://proxy.example.com:8080/";
Acquire::https::Proxy "http://proxy.example.com:8080/";
```

## Troubleshooting

### APT Update Fails with Certificate Errors

Install/update CA certificates:
```bash
sudo apt install --reinstall ca-certificates
```

### Package Architecture Mismatch

Ensure you're using Ubuntu Ports (ports.ubuntu.com) for ARM64 architecture, not regular Ubuntu archives (archive.ubuntu.com).

### Connection Timeout

Check network connectivity:
```bash
ping -c 4 ports.ubuntu.com
```

Configure DNS if needed:
```bash
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
```

## References

- [Ubuntu Ports](https://wiki.ubuntu.com/ARM/Ports)
- [APT Documentation](https://wiki.debian.org/Apt)
- [Yocto Package Management](https://docs.yoctoproject.org/dev-manual/packages.html)
