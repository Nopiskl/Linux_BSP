#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# Get Sources Tool
# Fetch kernel and bootloader sources

__usage="
Usage: get-sources [OPTIONS]
Fetch build sources.

Options: 
  -b, --board BOARD              Target board name.
  -i, --mirror GITHUB_MIRROR     GitHub mirror URL.
  -g, --target KERNEL_TARGET     Kernel target/branch.
  -h, --help                     Show help.
"

show_help()
{
    echo "$__usage"
    exit $1
}

init_params() {
    BOARD=test-board
    GITHUB_MIRROR=no
    KERNEL_TARGET=bsp
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
        elif [ "x$1" == "x-i" -o "x$1" == "x--mirror" ]; then
            GITHUB_MIRROR=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-g" -o "x$1" == "x--target" ]; then
            KERNEL_TARGET=`echo $2`
            shift
            shift
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

echo "=========================================="
echo "[TEST] Get Sources Tool"
echo "=========================================="
echo "[DEBUG] Started at: $(date)"
echo "[DEBUG] Working directory: $(pwd)"
echo ""

WORKSPACE=$(pwd)

init_params
parse_args "$@" || show_help $?

echo "[DEBUG] Parameters:"
echo "  Board=${BOARD}"
echo "  Mirror=${GITHUB_MIRROR}"
echo "  Target=${KERNEL_TARGET}"
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
echo "  LinuxRepo=${LINUX_REPO}"
echo "  LinuxBranch=${LINUX_BRANCH}"
echo "  BootloaderType=${BL_CONFIG}"
echo ""

# Simulate fetching
echo "[TEST] Simulating source fetch..."
echo "[TEST] Step 1: Checking workspace..."
echo "  Workspace: ${WORKSPACE}"

# Bootloader sources
if [ "${BL_CONFIG}" == "sunxi-syterkit" ]; then
    echo "[TEST] Step 2: Would fetch SyterKit"
    echo "  Repo: ${SYTERKIT_REPO}"
    echo "  Branch: ${SYTERKIT_BRANCH}"
    mkdir -p ${WORKSPACE}/${BL_CONFIG}
    echo "[TEST] Mock SyterKit directory created"
elif [ "${BL_CONFIG}" == "sunxi-uboot" ]; then
    echo "[TEST] Step 2: Would fetch U-Boot and ATF"
    echo "  U-Boot: ${UBOOT_REPO}"
    echo "  U-Boot Branch: ${UBOOT_BRANCH}"
    echo "  ATF: ${ATF_REPO}"
    echo "  ATF Branch: ${ATF_BRANCH}"
    mkdir -p ${WORKSPACE}/atf
    mkdir -p ${WORKSPACE}/${BL_CONFIG}
    echo "[TEST] Mock U-Boot and ATF directories created"
elif [ "${BL_CONFIG}" == "rockchip-uboot" ]; then
    echo "[TEST] Step 2: Would fetch U-Boot and rkbin"
    echo "  U-Boot: ${UBOOT_REPO}"
    echo "  U-Boot Branch: ${UBOOT_BRANCH}"
    echo "  RKBIN: ${RKBIN_REPO}"
    mkdir -p ${WORKSPACE}/rkbin
    mkdir -p ${WORKSPACE}/${BL_CONFIG}
    echo "[TEST] Mock U-Boot and rkbin directories created"
fi

# Kernel sources
echo "[TEST] Step 3: Would fetch Linux kernel"
if [ "${GITHUB_MIRROR}" != "no" ] && [[ "${LINUX_REPO}" == https://github.com/* ]]; then
    echo "  Using Mirror: ${GITHUB_MIRROR}"
    echo "  Original: ${LINUX_REPO}"
    MIRRORED="${GITHUB_MIRROR}/${LINUX_REPO}"
    echo "  Mirrored: ${MIRRORED}"
else
    echo "  Repo: ${LINUX_REPO}"
fi
echo "  Branch: ${LINUX_BRANCH}"
mkdir -p ${WORKSPACE}/linux
echo "[TEST] Mock Linux kernel directory created"

echo ""
echo "[TEST] Fetch simulation completed!"
echo "[DEBUG] Summary:"
echo "  Workspace: ${WORKSPACE}"
if [ -d ${WORKSPACE}/linux ]; then
    echo "  ✓ Linux kernel directory exists"
fi
if [ -d ${WORKSPACE}/${BL_CONFIG} ] || [ -d ${WORKSPACE}/atf ] || [ -d ${WORKSPACE}/rkbin ]; then
    echo "  ✓ Bootloader source directories exist"
fi

echo ""
echo "[TEST] Completed at: $(date)"
exit 0

