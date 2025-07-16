# BSP

## Make a BSP release

To make a BSP release run the following commands. Specify 'prod' for production release.

``` .bash
./scripts/gxa-init-build-machine.sh [prod | clean]
./scripts/gxa-patch-fs.sh
./scripts/gxa-pack.sh
```

For convenience a script called make can be found in the rout dir.

## Adding a new release

When a new Jetpack version is release it will be added to the archive here https://developer.nvidia.com/embedded/jetson-linux-archive

Using firefox you can download the new artifacts and uncover their source URLs.

Update the xml file in ./config/l4t-sources.xml

``` .xml
?xml version="1.0" encoding="UTF-8"?>
<l4tSources>
    <versions>
        <number_of_versions>3</number_of_versions>
        <version>l4t36.3</version>
        <version>l4t36.4</version>
        <version>l4t36.4.4</version>
    </versions>
    <l4t36.3>
       ...
    </l4t36.3>
    ...
    <l4t36.4.4>
        <webpage>https://developer.nvidia.com/embedded/jetson-linux-r3644</webpage>
        <toolchain>https://developer.download.nvidia.com/embedded/L4T/r36_Release_v3.0/toolchain/aarch64--glibc--stable-2022.08-1.tar.bz2</toolchain>
        <nvidia>https://developer.download.nvidia.com/embedded/L4T/r36_Release_v4.4/release/Jetson_Linux_R36.4.4_aarch64.tbz2</nvidia>
        <rootfs>https://developer.download.nvidia.com/embedded/L4T/r36_Release_v4.4/release/Tegra_Linux_Sample-Root-Filesystem_R36.4.4_aarch64.tbz2</rootfs>
        <kernel>https://developer.download.nvidia.com/embedded/L4T/r36_Release_v4.4/sources/public_sources.tbz2</kernel>
        <l4tVersion>36.4.4</l4tVersion>
    </l4t36.4.4>
</l4tSources>
```

To add new release peform the following checks:

* [ ]  Update <number_of_versions>
* [ ]  Add new version <version>
* [ ]  Add the new URLs for the updated release in </l4t<major>.<minor>.<patch>>
* [ ]  run ./make and build new BSP
* [ ]  Test BSP on GXA-1
* [ ]  Move BSP to /archive/bsp/.
