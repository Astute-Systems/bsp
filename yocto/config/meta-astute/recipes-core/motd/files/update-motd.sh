#!/bin/bash
# update-motd.sh - Update MOTD with current system information

MOTD_TEMPLATE="/etc/motd.template"
MOTD_FILE="/etc/motd"

# If template doesn't exist, create it from current motd
if [ ! -f "$MOTD_TEMPLATE" ] && [ -f "$MOTD_FILE" ]; then
    cp "$MOTD_FILE" "$MOTD_TEMPLATE"
fi

# Get system information
OS_VERSION=$(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d'"' -f2 || echo "Unknown")
KERNEL_VERSION=$(uname -r)
ARCHITECTURE=$(uname -m)
BUILD_DATE=$(date -r /etc/os-release '+%Y-%m-%d %H:%M' 2>/dev/null || date '+%Y-%m-%d %H:%M')

# Update MOTD with current information
if [ -f "$MOTD_TEMPLATE" ]; then
    sed -e "s/%OS_VERSION%/$OS_VERSION/g" \
        -e "s/%KERNEL_VERSION%/$KERNEL_VERSION/g" \
        -e "s/%ARCHITECTURE%/$ARCHITECTURE/g" \
        -e "s/%BUILD_DATE%/$BUILD_DATE/g" \
        "$MOTD_TEMPLATE" > "$MOTD_FILE"
elif [ -f "$MOTD_FILE" ]; then
    # Fallback: update existing motd file
    sed -i -e "s/OS: .*/OS: $OS_VERSION/" \
           -e "s/Kernel: .*/Kernel: $KERNEL_VERSION/" \
           -e "s/Architecture: .*/Architecture: $ARCHITECTURE/" \
           -e "s/Build Date: .*/Build Date: $BUILD_DATE/" \
           "$MOTD_FILE"
fi

# Ensure proper permissions
chmod 644 "$MOTD_FILE" 2>/dev/null || true
