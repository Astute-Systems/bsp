#!/bin/bash -e

#######################################################
#
# SOURCE THE ENVIRONMENT VARIABLES -  MOSTLY DIRECTORIES
#
#######################################################

source ./config/gxa-build.conf
source ./scripts/gxa-utils.sh

if [ ! -d $BUILD ]; then
    mkdir $BUILD
fi

#######################################################
#
# Detect L4T generation to pick the right build layout.
# r36.x  -> "legacy" flow: kernel-jammy-src + make -C kernel + make dtbs
# r39.2+ -> "modern" flow: kernel-noble + make -C source nvidia-dtbs
#
#######################################################

# Read L4T major.minor from the unpacked BSP (rootfs/etc/nv_tegra_release)
L4T_REL=$(sed -n 's/^# R\([0-9]\+\) .*REVISION: \([0-9]\+\).*/\1.\2/p' \
    "$L4T/rootfs/etc/nv_tegra_release" 2>/dev/null | head -n1)
L4T_MAJOR=${L4T_REL%%.*}
if [ -z "$L4T_MAJOR" ]; then
    echored "Could not determine L4T version from $L4T/rootfs/etc/nv_tegra_release"
    exit 1
fi

if [ "$L4T_MAJOR" -ge 39 ]; then
    L4T_FLOW="modern"
    KERNEL_HEADERS="$KERNEL_SOURCES/kernel/kernel-noble"
    L4T_OVERLAY_DIR="$CONFIG/l4t-overlay-r39"
    DTB_BUILD_PATH="$KERNEL_SOURCES/build/nvidia-public/devicetree/generic-dtbs/$DTB_FILE"
    # r39.2 flash.sh sources the DTB from kernel/dtb/; also mirror into
    # rootfs/boot/ so the on-target /boot copy matches after first boot
    # (the nvidia-l4t-kernel-dtbs deb otherwise overwrites it with stock).
    DTB_DEST_REL="kernel/dtb"
    DTB_DEST_REL_EXTRA="rootfs/boot"
else
    L4T_FLOW="legacy"
    KERNEL_HEADERS="$KERNEL_SOURCES/kernel/kernel-jammy-src"
    L4T_OVERLAY_DIR="$CONFIG/l4t-overlay"
    DTB_BUILD_PATH="$L4T/kernel/dtb/$DTB_FILE"
    DTB_DEST_REL="kernel/dtb"
fi

# COMPILER_ROOT / COMPILER_PREFIX are set by gxa-init-build-machine.sh.
# Fall back to the r36-style COMPILER for older configs.
if [ -n "$COMPILER_ROOT" ] && [ -n "$COMPILER_PREFIX" ]; then
    CROSS_COMPILE="$KERNEL_SOURCES/$COMPILER_ROOT/bin/$COMPILER_PREFIX"
else
    CROSS_COMPILE="$KERNEL_SOURCES/$COMPILER/bin/aarch64-buildroot-linux-gnu-"
fi

export CROSS_COMPILE
export INSTALL_MOD_PATH=$L4T_ROOTFS
export IGNORE_PREEMPT_RT_PRESENCE=1
export KERNEL_HEADERS
export KERNEL_OUTPUT=$KERNEL_HEADERS

echoblue "L4T flow=$L4T_FLOW (R${L4T_REL})"
echogreen "  CROSS_COMPILE=$CROSS_COMPILE"
echogreen "  KERNEL_HEADERS=$KERNEL_HEADERS"
echogreen "  L4T_OVERLAY_DIR=$L4T_OVERLAY_DIR"

function make_kernel_legacy {
    cd $KERNEL_SOURCES
    $KERNEL_SOURCES/generic_rt_build.sh "disable"
    make -C kernel
    sudo -E make install -C kernel
    cp $KERNEL_SOURCES/kernel/kernel-jammy-src/arch/arm64/boot/Image \
        $L4T/kernel/Image
    touch $FLAGS/kernel_build
}

function make_modules_legacy {
    cd $KERNEL_SOURCES
    if [ ! -f $FLAGS/modules_build ]; then
        make modules
        make modules_install
        cd $L4T
        sudo ./tools/l4t_update_initrd.sh
        touch $FLAGS/modules_build
    fi
}

# On r39.2+ we currently ship the stock kernel + modules from the BSP debs;
# only the DTB is customised. Kernel/module builds are therefore no-ops here.
function make_kernel {
    if [ "$L4T_FLOW" = "modern" ]; then
        echoblue "make_kernel: skipping (r39 uses stock kernel deb)"
        return 0
    fi
    make_kernel_legacy
}

function make_modules {
    if [ "$L4T_FLOW" = "modern" ]; then
        echoblue "make_modules: skipping (r39 uses stock modules deb)"
        return 0
    fi
    make_modules_legacy
}

function prepare_kernel_noble_scripts {
    # kernel-noble ships without a .config; the nvidia-dtbs build needs
    # scripts/dtc/dtc to exist under it. Build it once.
    if [ -x "$KERNEL_HEADERS/scripts/dtc/dtc" ]; then
        return 0
    fi
    echoblue "Bootstrapping kernel-noble scripts (defconfig + scripts)"
    (
        cd "$KERNEL_HEADERS"
        make ARCH=arm64 CROSS_COMPILE="$CROSS_COMPILE" defconfig
        make ARCH=arm64 CROSS_COMPILE="$CROSS_COMPILE" scripts
    )
}

function make_dtbs {
    echoblue "Patching the BSP"
    cd $PROJECT_ROOT
    L4T_OVERLAY_DIR="$L4T_OVERLAY_DIR" $PROJECT_ROOT/scripts/gxa-patch-fs.sh

    echoblue "Building device tree (${L4T_FLOW})"
    if [ "$L4T_FLOW" = "modern" ]; then
        prepare_kernel_noble_scripts
        cd $KERNEL_SOURCES
        make nvidia-dtbs
    else
        # r36 legacy: dtc from apt, symlink for kernel expectation
        sudo apt install -y device-tree-compiler
        if [ ! -f /lib/modules/6.11.0-29-generic/build/scripts/dtc/dtc ]; then
            sudo ln -sf /usr/bin/dtc /lib/modules/6.11.0-29-generic/build/scripts/dtc/dtc || true
        fi
        cd $KERNEL_SOURCES
        make dtbs
    fi

    if [ ! -f "$DTB_BUILD_PATH" ]; then
        echored "Expected DTB not produced at: $DTB_BUILD_PATH"
        exit 1
    fi

    mkdir -p "$L4T_OVERLAY_DIR/$DTB_DEST_REL"
    cp -v "$DTB_BUILD_PATH" "$L4T_OVERLAY_DIR/$DTB_DEST_REL/"
    echoblue "Copied DTB to $L4T_OVERLAY_DIR/$DTB_DEST_REL/$DTB_FILE"

    if [ -n "$DTB_DEST_REL_EXTRA" ]; then
        mkdir -p "$L4T_OVERLAY_DIR/$DTB_DEST_REL_EXTRA"
        cp -v "$DTB_BUILD_PATH" "$L4T_OVERLAY_DIR/$DTB_DEST_REL_EXTRA/"
        echoblue "Also mirrored DTB to $L4T_OVERLAY_DIR/$DTB_DEST_REL_EXTRA/$DTB_FILE"
    fi

    ls -al "$DTB_BUILD_PATH"
}

function make_pinctl {
    cd $BUILD
    cmake ..
    make pinctl
}

function make_all {
    make_kernel
    make_modules
    make_dtbs
    make_pinctl
}

case "$1" in
    kernel)  echo "Building Kernel";         make_kernel  ;;
    modules) echo "Building Modules";        make_modules ;;
    dtbs)    echo "Building Device Tree";    make_dtbs    ;;
    pinctl)  echo "Making pinctl applet";    make_pinctl  ;;
    all)     echo "Building All";            make_all     ;;
    *)
        echo "Usage: $0 [kernel|modules|dtbs|pinctl|all]"
        echo "Defaulting to all"
        make_all
        ;;
esac
