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
if [ ! -f "${YOCTO_ROOT}/config/imx95-build.conf" ]; then
    echored "Configuration file not found: ${YOCTO_ROOT}/config/imx95-build.conf"
    exit 1
fi
source "${YOCTO_ROOT}/config/imx95-build.conf"

# Validate required variables
REQUIRED_VARS="BOARD MACHINE DISTRO IMAGE_NAME YOCTO_DIR BUILD_DIR NXP_MANIFEST_URL NXP_MANIFEST_BRANCH NXP_MANIFEST_FILE"
MISSING_VARS=""

for var in $REQUIRED_VARS; do
    if [ -z "${!var}" ]; then
        MISSING_VARS="$MISSING_VARS $var"
    fi
done

if [ -n "$MISSING_VARS" ]; then
    echored "Error: Missing required configuration variables:$MISSING_VARS"
    echoyellow "Please check your configuration file: ${YOCTO_ROOT}/config/imx95-build.conf"
    exit 1
fi

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
    if ! repo init -u "${NXP_MANIFEST_URL}" -b "${NXP_MANIFEST_BRANCH}" -m "${NXP_MANIFEST_FILE}"; then
        echored "Failed to initialize repo"
        exit 1
    fi
    
    echoblue "Adding CompuLab BSP layer..."
    mkdir -p .repo/local_manifests
    
    cat > .repo/local_manifests/meta-bsp-imx95.xml << EOF
<?xml version="1.0" encoding="UTF-8" ?>
 <manifest>
 <remote fetch="https://github.com/compulab-yokneam" name="compulab"/>

    <project name="meta-compulab" remote="compulab" revision="${META_COMPULAB_REV}" path="sources/meta-compulab"/>
    <project name="meta-compulab-bsp" remote="compulab" revision="${META_COMPULAB_BSP_REV}" path="sources/meta-compulab-bsp"/>
    <project name="meta-compulab-uefi" remote="compulab" revision="${META_COMPULAB_UEFI_REV}" path="sources/meta-compulab-uefi"/>
    <project name="meta-bsp-imx95" remote="compulab" revision="${META_BSP_IMX95_REV}" path="sources/meta-bsp-imx95" >
        <linkfile src="tools/compulab-setup-env" dest="compulab-setup-env"/>
    </project>

 </manifest>
EOF
    
    echoblue "Syncing repositories (this may take a while)..."
    if ! repo sync; then
        echored "Failed to sync repositories"
        exit 1
    fi
    
    echogreen "Repository sync completed."
else
    echoyellow "Repo already initialized. Skipping initialization."
    echoblue "Updating repositories..."
    if ! repo sync; then
        echoyellow "Warning: Repository sync failed, continuing with existing sources"
    fi
fi

echo ""

# Setup build environment
echoblue "Setting up Yocto build environment for ${MACHINE}..."
export MACHINE="${MACHINE}"
export DISTRO="${DISTRO}"

# Setup custom meta layer (always do this)
echoblue "Setting up custom meta-astute layer..."
if [ ! -d "${YOCTO_DIR}/sources/meta-astute" ]; then
    echoblue "Creating meta-astute layer structure..."
    mkdir -p "${YOCTO_DIR}/sources/meta-astute"
    # Copy layer files from config directory
    cp -r "${YOCTO_ROOT}/config/meta-astute/"* "${YOCTO_DIR}/sources/meta-astute/" 2>/dev/null || true
    echogreen "meta-astute layer files copied"
else
    echoyellow "meta-astute layer already exists, updating files..."
    cp -r "${YOCTO_ROOT}/config/meta-astute/"* "${YOCTO_DIR}/sources/meta-astute/" 2>/dev/null || true
fi

# Verify CompuLab setup environment script exists
if [ ! -f "compulab-setup-env" ]; then
    echored "CompuLab setup environment script not found: compulab-setup-env"
    echoyellow "This should be created by the repo sync process"
    exit 1
fi

# Check if build directory already exists
if [ -d "${BUILD_DIR}" ]; then
    echoyellow "Build directory already exists. Re-using existing configuration."
    if ! source compulab-setup-env "build-${BOARD}"; then
        echored "Failed to source build environment"
        exit 1
    fi
else
    echoblue "Creating new build environment..."
    if ! source compulab-setup-env "build-${BOARD}"; then
        echored "Failed to create build environment"
        exit 1
    fi
    
    # Append our custom configuration
    echoblue "Appending custom configuration..."
    if [ -f "${YOCTO_ROOT}/config/local.conf.append" ]; then
        cat "${YOCTO_ROOT}/config/local.conf.append" >> conf/local.conf
        echogreen "Custom configuration added to local.conf"
    else
        echoyellow "No custom configuration file found at ${YOCTO_ROOT}/config/local.conf.append"
    fi
fi

# Verify we're in the build directory
if [ ! -d "conf" ]; then
    echored "Error: Not in a valid Yocto build directory (conf/ directory not found)"
    echoyellow "Current directory: $(pwd)"
    echoyellow "Expected build directory: ${BUILD_DIR}"
    exit 1
fi

# Add meta-astute layer to bblayers.conf (always do this)
echoblue "Adding meta-astute layer to bblayers.conf..."
if [ -f "conf/bblayers.conf" ]; then
    if ! grep -q "sources/meta-astute" conf/bblayers.conf; then
        # Use BSPDIR relative path to match the pattern
        ASTUTE_LAYER_PATH="\${BSPDIR}/sources/meta-astute"
        
        # Create a temporary file to safely modify bblayers.conf
        cp conf/bblayers.conf conf/bblayers.conf.tmp
        
        # Find the last BBLAYERS += line and add our layer after it
        if grep -q "meta-compulab-uefi" conf/bblayers.conf.tmp; then
            # Add our layer in the existing multi-line BBLAYERS section
            sed -i "/meta-compulab-uefi/a\\	${ASTUTE_LAYER_PATH} \\\\" conf/bblayers.conf.tmp
        else
            # Fallback: add as a new BBLAYERS += line
            echo "BBLAYERS += \"${ASTUTE_LAYER_PATH}\"" >> conf/bblayers.conf.tmp
        fi
        
        # Validate the modified file before replacing
        if grep -q "LCONF_VERSION" conf/bblayers.conf.tmp && ! grep -q "unparsed line" conf/bblayers.conf.tmp; then
            mv conf/bblayers.conf.tmp conf/bblayers.conf
            echogreen "meta-astute layer added to bblayers.conf"
        else
            rm -f conf/bblayers.conf.tmp
            echoyellow "Failed to add meta-astute layer - file format issue"
        fi
    else
        echoyellow "meta-astute layer already present in bblayers.conf"
    fi
else
    echoyellow "bblayers.conf not found - will be added after first bitbake run"
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
