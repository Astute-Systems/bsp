#!/bin/bash -e

# iMX95 Chroot Test Script
# This script allows you to enter the built filesystem using QEMU for testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echoblue() { echo -e "${BLUE}$1${NC}"; }
echogreen() { echo -e "${GREEN}$1${NC}"; }
echored() { echo -e "${RED}$1${NC}"; }
echoyellow() { echo -e "${YELLOW}$1${NC}"; }

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
YOCTO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${YOCTO_ROOT}/.." && pwd)"

# Source configuration
source "${YOCTO_ROOT}/config/imx95-build.conf"

echoblue "================================================================"
echoblue "  iMX95 Filesystem Chroot Test Script"
echoblue "================================================================"
echo ""

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echored "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check for QEMU
if ! command -v qemu-aarch64-static &> /dev/null; then
    echored "Error: qemu-aarch64-static not found"
    echoyellow "Please install QEMU user-mode emulation:"
    echo "  Ubuntu/Debian: sudo apt-get install qemu-user-static"
    exit 1
fi

# Find the rootfs
echoblue "Looking for built rootfs..."

# Check if the image exists
if [ ! -d "${DEPLOY_DIR}" ]; then
    echored "Error: Deploy directory not found: ${DEPLOY_DIR}"
    echoyellow "Please build the image first using: ./yocto/scripts/build-imx95.sh"
    exit 1
fi

# Find the .wic.zst file
IMAGE_FILE=$(find "${DEPLOY_DIR}" -name "${IMAGE_BASENAME}*.wic.zst" -type f | head -n1)

if [ -z "$IMAGE_FILE" ]; then
    echored "Error: No image file found in ${DEPLOY_DIR}"
    echoyellow "Please build the image first using: ./yocto/scripts/build-imx95.sh"
    exit 1
fi

echogreen "Found image: $(basename ${IMAGE_FILE})"
echo ""

# Create temporary mount point
MOUNT_POINT="/tmp/imx95-rootfs-$$"
TEMP_IMG="/tmp/imx95-temp-$$.img"
LOOP_DEVICE=""

cleanup() {
    echoblue "Cleaning up..."
    
    # Unmount special filesystems if mounted
    for fs in proc sys dev/pts dev; do
        if mountpoint -q "${MOUNT_POINT}/${fs}" 2>/dev/null; then
            umount "${MOUNT_POINT}/${fs}" || true
        fi
    done
    
    # Unmount rootfs
    if mountpoint -q "${MOUNT_POINT}" 2>/dev/null; then
        umount "${MOUNT_POINT}" || true
    fi
    
    # Remove QEMU binary if copied
    if [ -f "${MOUNT_POINT}/usr/bin/qemu-aarch64-static" ]; then
        rm -f "${MOUNT_POINT}/usr/bin/qemu-aarch64-static" || true
    fi
    
    # Cleanup loop device
    if [ -n "$LOOP_DEVICE" ]; then
        losetup -d "$LOOP_DEVICE" 2>/dev/null || true
    fi
    
    # Remove temporary image file
    if [ -f "${TEMP_IMG}" ]; then
        rm -f "${TEMP_IMG}" || true
    fi
    
    # Remove mount point
    if [ -d "${MOUNT_POINT}" ]; then
        rmdir "${MOUNT_POINT}" 2>/dev/null || true
    fi
    
    echogreen "Cleanup complete."
}

trap cleanup EXIT

echoblue "Creating mount point..."
mkdir -p "${MOUNT_POINT}"

echoblue "Decompressing and mounting image..."
echoyellow "This may take a few minutes..."

# Decompress and find the rootfs partition
zstd -dc "${IMAGE_FILE}" > "${TEMP_IMG}"

# Find the rootfs partition (usually partition 2 or 3)
PARTITION_INFO=$(sfdisk -d "${TEMP_IMG}" 2>/dev/null || true)

# Calculate the offset for the rootfs partition
# Look for the largest partition which is typically the rootfs
# Parse the partition info line by line:
# 1. Filter lines starting with the image path
# 2. Extract the "start=" value and remove comma
# 3. Convert to bytes (multiply by 512)
# 4. Sort numerically and take the largest
OFFSET=$(echo "$PARTITION_INFO" | \
    grep "^${TEMP_IMG}" | \
    awk '{
        if ($4 ~ /^start=/) {
            gsub("start=", "", $4);
            gsub(",", "", $4);
            print $4 * 512
        }
    }' | \
    sort -n | \
    tail -1)

if [ -z "$OFFSET" ]; then
    echored "Error: Could not determine rootfs partition offset"
    exit 1
fi

echoblue "Mounting rootfs partition (offset: $OFFSET)..."
mount -o loop,offset=$OFFSET "${TEMP_IMG}" "${MOUNT_POINT}"

# Copy QEMU binary to the chroot
echoblue "Setting up QEMU for ARM emulation..."
cp /usr/bin/qemu-aarch64-static "${MOUNT_POINT}/usr/bin/"

# Mount special filesystems
echoblue "Mounting special filesystems..."
mount -t proc proc "${MOUNT_POINT}/proc"
mount -t sysfs sys "${MOUNT_POINT}/sys"
mount -o bind /dev "${MOUNT_POINT}/dev"
mount -t devpts devpts "${MOUNT_POINT}/dev/pts"

echo ""
echoblue "================================================================"
echogreen "  Chroot Environment Ready"
echoblue "================================================================"
echoyellow "You are now in the iMX95 filesystem chroot."
echoyellow "Type 'exit' to leave the chroot environment."
echo ""
echoyellow "You can test installed packages:"
echo "  - git --version"
echo "  - cmake --version"
echo "  - qmake6 --version (or qmake -v)"
echo "  - apt update"
echo ""
echoblue "================================================================"
echo ""

# Enter chroot
chroot "${MOUNT_POINT}" /bin/bash

# Cleanup happens automatically via trap
