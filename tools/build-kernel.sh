#!/usr/bin/env bash
#
# SPDX-LICense-Identifier: GPL-3.0
#
# Build Kernel Tool
# Build Linux kernel and generate packages

__usage="
Usage: build-kernel [OPTIONS]
Build Linux kernel.

Options: 
  -b, --board BOARD              Target board name.
  -k, --menuconfig               Run menuconfig (yes/no).
  -g, --target                   Kernel target/branch.
  -e, --ccache                   Use ccache (yes/no).
  -h, --help                     Show help.
"

show_help()
{
    echo "$__usage"
    exit $1
}

init_params() {
    BOARD=test-board
    MENUCONFIG=no
    KERNEL_TARGET=bsp
    USE_CCACHE=no
}

parse_args()
{
    if [ "x$#" == "x0" ]; then
        return 0
    fi

    while [ "x$#" != "x0" ];
    do
        if [ "x$1" == "x-h" -o "x$1" == "x--help" ]; then
            return 1
        elif [ "x$1" == "x" ]; then
            shift
        elif [ "x$1" == "x-b" -o "x$1" == "x--board" ]; then
            BOARD=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-k" -o "x$1" == "x--menuconfig" ]; then
            MENUCONFIG=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-g" -o "x$1" == "x--target" ]; then
            KERNEL_TARGET=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-e" -o "x$1" == "x--ccache" ]; then
            USE_CCACHE=`echo $2`
            shift
            shift
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

echo "=========================================="
echo "[TEST] Build Kernel Tool"
echo "=========================================="
echo "[DEBUG] Started at: $(date)"
echo "[DEBUG] Working directory: $(pwd)"
echo ""

WORKSPACE=$(pwd)

init_params
parse_args "$@" || show_help $?

echo "[DEBUG] Parameters:"
echo "  Board=${BOARD}"
echo "  Menuconfig=${MENUCONFIG}"
echo "  Target=${KERNEL_TARGET}"
echo "  Ccache=${USE_CCACHE}"
echo ""

# Load config
TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${TOOL_DIR}/.." && pwd)"
CONFIG_DIR="${BASE_DIR}/configs"

CONFIG_FILE="${CONFIG_DIR}/${BOARD}.conf"
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "[ERROR] Config file not found: ${CONFIG_FILE}"
    echo "[ERROR] Config directory: ${CONFIG_DIR}"
    exit 1
fi

echo "[DEBUG] Loading config: ${CONFIG_FILE}"
source "${CONFIG_FILE}"

echo "[DEBUG] Config loaded:"
echo "  BoardName=${BOARD_NAME}"
echo "  Arch=${ARCH}"
echo "  CrossCompiler=${KERNEL_GCC}"
echo "  LinuxConfig=${LINUX_CONFIG}"
echo "  PatchDir=${LINUX_PATHDIR}"
echo "  DeviceTree=${DEVICE_DTS}"
echo ""

# Simulate build
echo "[TEST] Simulating kernel build..."
KERNEL_SRC="${WORKSPACE}/linux"
if [ ! -d "${KERNEL_SRC}" ]; then
    echo "[TEST] Creating mock kernel source..."
    mkdir -p ${KERNEL_SRC}
    echo "[TEST] Mock kernel source created"
else
    echo "[TEST] Kernel source exists: ${KERNEL_SRC}"
fi

if [ "${LINUX_PATHDIR}" != "none" ]; then
    echo "[TEST] Step 2: Would apply patches"
    echo "  Patch dir: ../patches/kernel/${LINUX_PATHDIR}"
    echo "[TEST] Simulating patch application..."
else
    echo "[TEST] Step 2: No patches to apply"
fi

echo "[TEST] Step 3: Configuring kernel"
echo "  Config: ${LINUX_CONFIG}"
echo "  Arch: ${ARCH}"
echo "  Cross-compiler: ${KERNEL_GCC}"
echo "  Ccache: ${USE_CCACHE}"

if [ "${MENUCONFIG}" == "yes" ]; then
    echo "[TEST] Would run: make ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} menuconfig"
    echo "[TEST] Simulating menuconfig..."
else
    echo "[TEST] Would run: make ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} ${LINUX_CONFIG}"
    echo "[TEST] Simulating defconfig..."
fi

echo "[TEST] Step 4: Compiling kernel"
echo "[TEST] Would run: make ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} -j$(nproc)"
echo "[TEST] Simulating compilation..."
sleep 0.1

echo "[TEST] Step 5: Installing artifacts"
PKGS_DIR="${WORKSPACE}/${BOARD}-kernel-pkgs"
mkdir -p ${PKGS_DIR}

VERSION="5.15.0-test"
PKG_NAME="linux-${BOARD_NAME//_/-}"

echo "[TEST] Creating mock packages..."
touch ${PKGS_DIR}/linux-dtb-${PKG_NAME}_${VERSION}_${ARCH}.deb
touch ${PKGS_DIR}/linux-image-${PKG_NAME}_${VERSION}_${ARCH}.deb
touch ${PKGS_DIR}/linux-headers-${PKG_NAME}_${VERSION}_${ARCH}.deb
touch ${PKGS_DIR}/linux-libc-dev-${PKG_NAME}_${VERSION}_${ARCH}.deb

echo "[TEST] Step 6: Creating marker file"
echo "${LINUX_CONFIG}" > ${PKGS_DIR}/.done
echo "[TEST] Marker created: ${PKGS_DIR}/.done"

echo ""
echo "[TEST] Kernel build simulation completed!"
echo "[DEBUG] Summary:"
echo "  Kernel source: ${KERNEL_SRC}"
echo "  Packages: ${PKGS_DIR}"
if [ -d ${PKGS_DIR} ]; then
    echo "  ✓ Packages directory exists"
    echo "  Packages:"
    ls -lh ${PKGS_DIR}/*.deb 2>/dev/null | while read line; do
        echo "    $line"
    done || echo "    (no .deb files)"
fi

echo ""
echo "[TEST] Completed at: $(date)"
exit 0

