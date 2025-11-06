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

# Clone Linux kernel repository
clone_linux()
{
    echo "=========================================="
    echo "Fetching Linux Kernel Sources"
    echo "=========================================="
    
    if [ -d ${WORKSPACE}/linux ]; then
        echo "Linux directory exists, checking status..."
        pushd ${WORKSPACE}/linux > /dev/null
        
        # Check if it's a valid git repository
        if [ ! -d .git ]; then
            echo "Invalid git repository, removing and re-cloning..."
            popd > /dev/null
            rm -rf ${WORKSPACE}/linux
            cd ${WORKSPACE}
            git clone --depth=1 ${LINUX_REPO} -b ${LINUX_BRANCH} linux
            if [ $? -ne 0 ] && [ "${LINUX_GITEE_REPO}" != "" ]; then
                echo "Trying fallback repository..."
                git clone --depth=1 ${LINUX_GITEE_REPO} -b ${LINUX_BRANCH} linux
            fi
        else
            # Update remote
            git remote -v update > /dev/null 2>&1
            remote_url=$(git config --get remote.origin.url)
            current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
            
            echo "  Current repository: ${remote_url}"
            echo "  Current branch: ${current_branch}"
            echo "  Target repository: ${LINUX_REPO}"
            echo "  Target branch: ${LINUX_BRANCH}"
            
            if [[ "${remote_url}" == "${LINUX_REPO}" && "${current_branch}" == "${LINUX_BRANCH}" ]]; then
                echo "Repository and branch match, updating..."
                git pull
            else
                echo "Repository or branch mismatch, re-cloning..."
                popd > /dev/null
                rm -rf ${WORKSPACE}/linux
                cd ${WORKSPACE}
                git clone --depth=1 ${LINUX_REPO} -b ${LINUX_BRANCH} linux
                if [ $? -ne 0 ] && [ "${LINUX_GITEE_REPO}" != "" ]; then
                    echo "Trying fallback repository..."
                    git clone --depth=1 ${LINUX_GITEE_REPO} -b ${LINUX_BRANCH} linux
                fi
            fi
            popd > /dev/null
        fi
    else
        echo "Cloning Linux kernel..."
        cd ${WORKSPACE}
        git clone --depth=1 ${LINUX_REPO} -b ${LINUX_BRANCH} linux
        if [ $? -ne 0 ]; then
            if [ "${LINUX_GITEE_REPO}" != "" ]; then
                echo "Trying fallback repository..."
                git clone --depth=1 ${LINUX_GITEE_REPO} -b ${LINUX_BRANCH} linux
            else
                echo "ERROR: Failed to clone Linux kernel"
                return 1
            fi
        fi
    fi
    
    if [ -d ${WORKSPACE}/linux/.git ]; then
        echo "✓ Linux kernel source ready"
        return 0
    else
        echo "✗ Failed to fetch Linux kernel"
        return 1
    fi
}

# Clone SyterKit bootloader
clone_syterkit()
{
    echo "=========================================="
    echo "Fetching SyterKit Bootloader"
    echo "=========================================="
    
    if [ -d ${WORKSPACE}/${BL_CONFIG} ]; then
        echo "SyterKit directory exists, updating..."
        pushd ${WORKSPACE}/${BL_CONFIG} > /dev/null
        rm -rf build-${BOARD}
        git pull
        popd > /dev/null
    else
        echo "Cloning SyterKit..."
        cd ${WORKSPACE}
        git clone --depth=1 ${SYTERKIT_REPO} -b ${SYTERKIT_BRANCH} ${BL_CONFIG}
    fi
    
    if [ -d ${WORKSPACE}/${BL_CONFIG} ]; then
        echo "✓ SyterKit source ready"
        return 0
    else
        echo "✗ Failed to fetch SyterKit"
        return 1
    fi
}

# Clone ARM Trusted Firmware
clone_atf()
{
    echo "=========================================="
    echo "Fetching ARM Trusted Firmware"
    echo "=========================================="
    
    if [ -d ${WORKSPACE}/atf ]; then
        echo "ATF directory exists, updating..."
        pushd ${WORKSPACE}/atf > /dev/null
        git pull
        popd > /dev/null
    else
        echo "Cloning ATF..."
        cd ${WORKSPACE}
        git clone --depth=1 ${ATF_REPO} -b ${ATF_BRANCH} atf
    fi
    
    if [ -d ${WORKSPACE}/atf ]; then
        echo "✓ ATF source ready"
        return 0
    else
        echo "✗ Failed to fetch ATF"
        return 1
    fi
}

# Clone Rockchip binary firmware
clone_rkbin()
{
    echo "=========================================="
    echo "Fetching Rockchip Binary Firmware"
    echo "=========================================="
    
    if [ -d ${WORKSPACE}/rkbin ]; then
        echo "rkbin directory exists, updating..."
        pushd ${WORKSPACE}/rkbin > /dev/null
        git pull
        popd > /dev/null
    else
        echo "Cloning rkbin..."
        cd ${WORKSPACE}
        git clone ${RKBIN_REPO} rkbin
        if [ "${RKBIN_BRANCH_HASH}" != "" ]; then
            pushd rkbin > /dev/null
            git checkout ${RKBIN_BRANCH_HASH}
            popd > /dev/null
        fi
    fi
    
    if [ -d ${WORKSPACE}/rkbin ]; then
        echo "✓ rkbin source ready"
        return 0
    else
        echo "✗ Failed to fetch rkbin"
        return 1
    fi
}

# Clone U-Boot bootloader
clone_uboot()
{
    echo "=========================================="
    echo "Fetching U-Boot Bootloader"
    echo "=========================================="
    
    if [ -d ${WORKSPACE}/${BL_CONFIG} ]; then
        echo "U-Boot directory exists, updating..."
        pushd ${WORKSPACE}/${BL_CONFIG} > /dev/null
        git pull
        popd > /dev/null
    else
        echo "Cloning U-Boot..."
        cd ${WORKSPACE}
        git clone --depth=1 ${UBOOT_REPO} -b ${UBOOT_BRANCH} ${BL_CONFIG}
    fi
    
    if [ -d ${WORKSPACE}/${BL_CONFIG} ]; then
        echo "✓ U-Boot source ready"
        return 0
    else
        echo "✗ Failed to fetch U-Boot"
        return 1
    fi
}

# Main execution
echo "=========================================="
echo "BSP Get Sources Tool"
echo "=========================================="
echo "Started at: $(date)"
echo ""

WORKSPACE=$(pwd)

init_params
parse_args "$@" || show_help $?

# Load config
TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${TOOL_DIR}/.." && pwd)"
CONFIG_DIR="${BASE_DIR}/configs"

CONFIG_FILE="${CONFIG_DIR}/${BOARD}.conf"
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "ERROR: Config file not found: ${CONFIG_FILE}"
    echo "Available boards:"
    ls -1 ${CONFIG_DIR}/*.conf 2>/dev/null | sed 's/.*\///;s/\.conf$//' || echo "  (none)"
    exit 1
fi

echo "Configuration:"
echo "  Board: ${BOARD}"
echo "  Config: ${CONFIG_FILE}"
echo "  Workspace: ${WORKSPACE}"
echo "  GitHub Mirror: ${GITHUB_MIRROR}"
echo ""

source "${CONFIG_FILE}"

# Apply GitHub mirror if specified
if [[ "${LINUX_REPO:0:18}" == "https://github.com" && "${GITHUB_MIRROR}" != "no" ]]; then
    echo "Applying GitHub mirror: ${GITHUB_MIRROR}"
    LINUX_REPO="${GITHUB_MIRROR}/${LINUX_REPO}"
fi

echo "Source Repositories:"
echo "  Linux: ${LINUX_REPO} (${LINUX_BRANCH})"
if [ "${BL_CONFIG}" == "sunxi-syterkit" ]; then
    echo "  Bootloader: ${SYTERKIT_REPO} (${SYTERKIT_BRANCH})"
elif [ "${BL_CONFIG}" == "sunxi-uboot" ]; then
    echo "  U-Boot: ${UBOOT_REPO} (${UBOOT_BRANCH})"
    echo "  ATF: ${ATF_REPO} (${ATF_BRANCH})"
elif [ "${BL_CONFIG}" == "rockchip-uboot" ]; then
    echo "  U-Boot: ${UBOOT_REPO} (${UBOOT_BRANCH})"
    echo "  RKBIN: ${RKBIN_REPO}"
elif [ "${BL_CONFIG}" == "custom" ]; then
    echo "  Bootloader: Custom (handled separately)"
fi
echo ""

# Fetch bootloader sources
if [ "${BL_CONFIG}" == "sunxi-syterkit" ]; then
    clone_syterkit || exit 1
elif [ "${BL_CONFIG}" == "sunxi-uboot" ]; then
    clone_atf || exit 1
    clone_uboot || exit 1
elif [ "${BL_CONFIG}" == "rockchip-uboot" ]; then
    clone_rkbin || exit 1
    clone_uboot || exit 1
elif [ "${BL_CONFIG}" == "custom" ]; then
    echo "=========================================="
    echo "Custom Bootloader Configuration"
    echo "=========================================="
    echo "Skipping automatic bootloader fetch."
    echo "Please ensure your bootloader is ready manually."
    echo ""
fi

# Fetch kernel sources
clone_linux || exit 1

# Verify all sources are available
echo ""
echo "=========================================="
echo "Source Fetch Summary"
echo "=========================================="

if [ ! -d ${WORKSPACE}/linux/.git ]; then
    echo "✗ Linux kernel source not available"
    echo "ERROR: Fetch sources failed, please check your network connection."
    exit 2
fi

echo "✓ All required sources fetched successfully"
echo ""
echo "Workspace: ${WORKSPACE}"
echo "  - Linux kernel: ${WORKSPACE}/linux"

if [ "${BL_CONFIG}" == "sunxi-syterkit" ]; then
    echo "  - SyterKit: ${WORKSPACE}/${BL_CONFIG}"
elif [ "${BL_CONFIG}" == "sunxi-uboot" ]; then
    echo "  - U-Boot: ${WORKSPACE}/${BL_CONFIG}"
    echo "  - ATF: ${WORKSPACE}/atf"
elif [ "${BL_CONFIG}" == "rockchip-uboot" ]; then
    echo "  - U-Boot: ${WORKSPACE}/${BL_CONFIG}"
    echo "  - RKBIN: ${WORKSPACE}/rkbin"
fi

echo ""
echo "Completed at: $(date)"
exit 0

