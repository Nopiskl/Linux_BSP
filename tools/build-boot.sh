#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# Build Bootloader Tool
# Build bootloader for target board

__usage="
Usage: build-boot [OPTIONS]
Build bootloader.

Options: 
  -b, --board BOARD              Target board name.
  -h, --help                     Show help.
"

show_help()
{
    echo "$__usage"
    exit $1
}

init_params() {
    BOARD=test-board
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
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

echo "=========================================="
echo "[TEST] Build Bootloader Tool"
echo "=========================================="
echo "[DEBUG] Started at: $(date)"
echo "[DEBUG] Working directory: $(pwd)"
echo ""

WORKSPACE=$(pwd)

init_params
parse_args "$@" || show_help $?

echo "[DEBUG] Parameters:"
echo "  Board=${BOARD}"
echo ""

# Load config
TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${TOOL_DIR}/.." && pwd)"
CONFIG_DIR="${BASE_DIR}/configs/board"

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
echo "  BootloaderType=${BL_CONFIG}"
echo ""

# Simulate build
echo "[TEST] Simulating bootloader build..."
echo "[TEST] Step 1: Preparing environment"
echo "  Workspace: ${WORKSPACE}"
echo "  Type: ${BL_CONFIG}"

OUTPUT="${WORKSPACE}/bootloader-${BOARD}"
echo "[TEST] Step 2: Creating output: ${OUTPUT}"
mkdir -p ${OUTPUT}

if [ "${BL_CONFIG}" == "sunxi-syterkit" ]; then
    echo "[TEST] Step 3: Would build SyterKit"
    echo "  Config: ${SYTERKIT_TYPE}"
    echo "  Board: ${BOARD_NAME}"
    touch ${OUTPUT}/boot.bin
    touch ${OUTPUT}/boot0.bin
    echo "[TEST] Mock SyterKit files created"
elif [ "${BL_CONFIG}" == "sunxi-uboot" ]; then
    echo "[TEST] Step 3: Would build U-Boot with ATF"
    echo "  U-Boot Config: ${BL_CONF}"
    echo "  Board: ${BOARD_NAME}"
    touch ${OUTPUT}/u-boot-sunxi-with-spl.bin
    touch ${OUTPUT}/boot.scr
    echo "[TEST] Mock U-Boot files created"
elif [ "${BL_CONFIG}" == "rockchip-uboot" ]; then
    echo "[TEST] Step 3: Would build Rockchip U-Boot"
    echo "  U-Boot Config: ${BL_CONF}"
    echo "  Board: ${BOARD_NAME}"
    touch ${OUTPUT}/idbloader.img
    touch ${OUTPUT}/u-boot.itb
    echo "[TEST] Mock Rockchip U-Boot files created"
else
    echo "[TEST] Step 3: Unknown type: ${BL_CONFIG}"
    touch ${OUTPUT}/bootloader.bin
    echo "[TEST] Generic bootloader file created"
fi

echo "[TEST] Step 4: Creating marker file"
echo "${BOARD}" > ${OUTPUT}/.done
echo "[TEST] Marker created: ${OUTPUT}/.done"

echo ""
echo "[TEST] Bootloader build simulation completed!"
echo "[DEBUG] Summary:"
echo "  Output: ${OUTPUT}"
if [ -d ${OUTPUT} ]; then
    echo "  ✓ Output directory exists"
    echo "  Files:"
    ls -lh ${OUTPUT} 2>/dev/null | tail -n +2 | while read line; do
        echo "    $line"
    done
fi

echo ""
echo "[TEST] Completed at: $(date)"
exit 0

