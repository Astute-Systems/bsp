#!/bin/bash
# Validation script for meta-astute layer

LAYER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Validating meta-astute layer at: $LAYER_DIR"

# Check layer.conf
if [ -f "$LAYER_DIR/conf/layer.conf" ]; then
    echo "✓ layer.conf found"
else
    echo "✗ layer.conf missing"
    exit 1
fi

# Check recipe structure
if [ -f "$LAYER_DIR/recipes-core/apt-sources/apt-sources_1.0.bb" ]; then
    echo "✓ apt-sources recipe found"
else
    echo "✗ apt-sources recipe missing"
    exit 1
fi

if [ -f "$LAYER_DIR/recipes-core/motd/motd_1.0.bb" ]; then
    echo "✓ motd recipe found"
else
    echo "✗ motd recipe missing"
    exit 1
fi

# Check source files
if [ -f "$LAYER_DIR/recipes-core/apt-sources/files/astute.list" ]; then
    echo "✓ astute.list found"
else
    echo "✗ astute.list missing"
    exit 1
fi

if [ -f "$LAYER_DIR/recipes-core/apt-sources/files/astute.gpg" ]; then
    echo "✓ astute.gpg found"
else
    echo "✗ astute.gpg missing"
    exit 1
fi

# Check MOTD files
if [ -f "$LAYER_DIR/recipes-core/motd/files/motd" ]; then
    echo "✓ motd file found"
else
    echo "✗ motd file missing"
    exit 1
fi

if [ -f "$LAYER_DIR/recipes-core/motd/files/update-motd.sh" ]; then
    echo "✓ update-motd.sh found"
else
    echo "✗ update-motd.sh missing"
    exit 1
fi

echo "✓ Layer validation passed"
