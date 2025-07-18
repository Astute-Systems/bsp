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

export CROSS_COMPILE=$KERNEL_SOURCES/$COMPILER/bin/aarch64-buildroot-linux-gnu-
export INSTALL_MOD_PATH=$L4T_ROOTFS
export IGNORE_PREEMPT_RT_PRESENCE=1
export KERNEL_HEADERS=$KERNEL_SOURCES/kernel/kernel-jammy-src

function make_kernel {
    # BUILD KERNEL AND IN-TREE MODULES
    cd $KERNEL_SOURCES
    #Enable Real Time Kernel
    # $KERNEL_SOURCES/generic_rt_build.sh "enable"
    $KERNEL_SOURCES/generic_rt_build.sh "disable"
    make -C kernel
    sudo -E make install -C kernel
    cp $KERNEL_SOURCES/kernel/kernel-jammy-src/arch/arm64/boot/Image \
        $L4T/kernel/Image
    touch $FLAGS/kernel_build
}
function make_modules {
    # BUILD OUT OF TREE MODULES
    cd $KERNEL_SOURCES
    if [ ! -f $FLAGS/modules_build ]; then
        make modules
        make modules_install
        cd $L4T
        sudo ./tools/l4t_update_initrd.sh
        touch $FLAGS/modules_build
    fi
}
function make_dtbs {

###################
###
### Need the device tree compiler. Probably could just install it.
###
#################

    # Takes too long to compile the device tree compiler from source
    # so we will just install it from the package manager
    # if [ ! -f $FLAGS/kernel_build ]; then
    #     echoblue "Making the kernel source"
    #     make_kernel
    # fi

    sudo apt install -y device-tree-compiler
    # create a symbolic link to the dtc binary
    if [ ! -f /lib/modules/6.11.0-29-generic/build/scripts/dtc/dtc ]; then
        sudo ln -s /usr/bin/dtc /lib/modules/6.11.0-29-generic/build/scripts/dtc/dtc
    fi

###################
###
### Need to patch the filesystem to include the device tree files
###
#################
    echoblue "Patching the BSP"
    cd $PROJECT_ROOT
    $PROJECT_ROOT/scripts/gxa-patch-fs.sh

####################
###
### BUILD THE DEVICE TREE binary
###
#######################

    # BUILD DEVICE TREE
    echoblue "Making the dtbs device tree"
    cd $KERNEL_SOURCES
    make dtbs
    cp $L4T/kernel/dtb/$DTB_FILE $CONFIG/l4t-overlay/kernel/dtb/
    ls -al $L4T/kernel/dtb/$DTB_FILE 

    echoblue "Copied to $CONFIG/l4t-overlay/kernel/dtb/$DTB_FILE"
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
    # make_analog
    make_pinctl
}

if [ "$1" = "kernel" ]; then
    echo "Building Kernel"
    make_kernel
elif [ "$1" = "modules" ]; then
    echo "Building Modules"
    make_modules
elif [ "$1" = "dtbs" ]; then
    echo "Building Device Tree"
    make_dtbs
# elif [ "$1" = "analog" ]; then
#     echo "Building Analog Video Driver"
#     make_analog
elif [ "$1" = "pinctl" ]; then
    echo "Making pinctl applet"
    make_pinctl
elif [ "$1" = "all" ]; then
    echo "Building All"
    make_all
else
    echo "Usage: $0 [kernel|modules|dtbs|all]"
    echo "Defaulting to all"
    make_all
fi



