#!/bin/bash -e

# iMX95 Yocto Build Script
# This script sets up the Yocto build environment and builds an Ubuntu-based
# image for the CompuLab UCM-iMX95 board

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
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
echoblue "  iMX95 Yocto Build Script for CompuLab UCM-iMX95"
echoblue "================================================================"
echo ""

# Check for required tools
echoblue "Checking for required tools..."
REQUIRED_TOOLS="repo git python3 wget"
MISSING_TOOLS=""

for tool in $REQUIRED_TOOLS; do
    if ! command -v $tool &> /dev/null; then
        MISSING_TOOLS="$MISSING_TOOLS $tool"
    fi
done

if [ -n "$MISSING_TOOLS" ]; then
    echored "Error: Missing required tools:$MISSING_TOOLS"
    echoyellow "Please install missing tools:"
    echo "  Ubuntu/Debian: sudo apt-get install repo git python3 wget"
    exit 1
fi

echogreen "All required tools are available."
echo ""

# Create build directory structure
echoblue "Setting up build directory: ${YOCTO_DIR}"
mkdir -p "${YOCTO_DIR}"
cd "${YOCTO_DIR}"

# Initialize repo if not already done
if [ ! -d ".repo" ]; then
    echoblue "Initializing repo manifests from NXP..."
    repo init -u "${NXP_MANIFEST_URL}" -b "${NXP_MANIFEST_BRANCH}" -m "${NXP_MANIFEST_FILE}"
    
    echoblue "Adding CompuLab BSP layer..."
    mkdir -p .repo/local_manifests
    
    cat > .repo/local_manifests/meta-bsp-imx95.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8" ?>
 <manifest>
 <remote fetch="https://github.com/compulab-yokneam" name="compulab"/>

    <project name="meta-compulab" remote="compulab" revision="a9ef2a47c3ca56f985174b6781882db457bd389f" path="sources/meta-compulab"/>
    <project name="meta-compulab-bsp" remote="compulab" revision="3a9724ca2f7d3a55cef3a648b814c5b26bd18c86" path="sources/meta-compulab-bsp"/>
    <project name="meta-compulab-uefi" remote="compulab" revision="d9646b4b9ae785f3c36e90a375bc1059b8baf580" path="sources/meta-compulab-uefi"/>
    <project name="meta-bsp-imx95" remote="compulab" revision="scarthgap-6.6.36-EVAL-UCM-iMX95-1.0" path="sources/meta-bsp-imx95" >
        <linkfile src="tools/compulab-setup-env" dest="compulab-setup-env"/>
    </project>

 </manifest>
EOF
    
    echoblue "Syncing repositories (this may take a while)..."
    repo sync
    
    echogreen "Repository sync completed."
else
    echoyellow "Repo already initialized. Skipping initialization."
    echoblue "Updating repositories..."
    repo sync
fi

echo ""

# Setup build environment
echoblue "Setting up Yocto build environment for ${MACHINE}..."
export MACHINE="${MACHINE}"
export DISTRO="${DISTRO}"

# Check if build directory already exists
if [ -d "${BUILD_DIR}" ]; then
    echoyellow "Build directory already exists. Re-using existing configuration."
    source compulab-setup-env "build-${BOARD}"
else
    echoblue "Creating new build environment..."
    source compulab-setup-env "build-${BOARD}"
    
    # Append our custom configuration
    echoblue "Appending custom configuration..."
    if [ -f "${YOCTO_ROOT}/config/local.conf.append" ]; then
        cat "${YOCTO_ROOT}/config/local.conf.append" >> conf/local.conf
        echogreen "Custom configuration added to local.conf"
    fi
fi

echo ""
echoblue "================================================================"
echoblue "  Build Environment Ready"
echoblue "================================================================"
echoyellow "Build directory: ${BUILD_DIR}"
echoyellow "Machine: ${MACHINE}"
echoyellow "Distro: ${DISTRO}"
echoyellow "Image: ${IMAGE_NAME}"
echo ""

# Parse command line arguments
if [ "$1" == "clean" ]; then
    echoyellow "Cleaning build directory..."
    bitbake -c cleanall ${IMAGE_NAME}
    echogreen "Clean complete."
    exit 0
elif [ "$1" == "shell" ]; then
    echogreen "Build environment configured. Starting interactive shell..."
    exec bash
elif [ "$1" == "bootloader" ]; then
    echoblue "Building bootloader only..."
    bitbake -k imx-boot
    echogreen "Bootloader build complete!"
    echoyellow "Location: ${DEPLOY_DIR}/imx-boot-tagged"
    exit 0
fi

# Build the image
echoblue "================================================================"
echoblue "  Starting Image Build"
echoblue "================================================================"
echoyellow "This may take several hours on the first build..."
echo ""

bitbake -k ${IMAGE_NAME}

echo ""
echoblue "================================================================"
echogreen "  Build Complete!"
echoblue "================================================================"
echoyellow "Image location:"
echo "  ${DEPLOY_DIR}/${IMAGE_BASENAME}*.wic.zst"
echo ""
echoyellow "To flash to SD card:"
echo "  sudo zstd -dc \${image_file} | sudo dd bs=1M status=progress of=/dev/sdX"
echo ""
echoyellow "To flash via UUU:"
echo "  cd ${DEPLOY_DIR}"
echo "  sudo uuu -v -b emmc_all imx-boot-tagged ${IMAGE_BASENAME}.wic.zst"
echo ""
