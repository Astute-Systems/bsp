#!/bin/bash -e

# Sudo check
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# First argument is the command to be run in the chroot environment
if [ ! -z "$1" ]; then
    COMMAND=$1
fi

#######################################################
#
# SOURCE THE ENVIRONMENT VARIABLES -  MOSTLY DIRECTORIES
#
#######################################################

source ./config/gxa-build.conf

#######################################################
#
# SET UP CHROOT ENVIRONMENT WITH NETWORK ACCESS
#
#######################################################
echo "Setting up chroot environment with network access..."

# Mount necessary filesystems
mount --bind /dev $L4T/rootfs/dev
mount --bind /dev/pts $L4T/rootfs/dev/pts
mount --bind /proc $L4T/rootfs/proc
mount --bind /sys $L4T/rootfs/sys

# Copy resolv.conf for DNS resolution
cp /etc/resolv.conf $L4T/rootfs/etc/resolv.conf


# If COMMAND spefified then just run the command and exit
if [ ! -z "$COMMAND" ]; then
    chroot $L4T/rootfs $COMMAND
else
    # Enter chroot environment
    chroot $L4T/rootfs /bin/bash
fi

# After exiting chroot, unmount filesystems
umount $L4T/rootfs/dev/pts
umount $L4T/rootfs/dev
umount $L4T/rootfs/proc
umount $L4T/rootfs/sys