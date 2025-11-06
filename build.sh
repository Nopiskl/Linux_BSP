#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# BSP Build Framework
# Lightweight and independent build system for BSP development

__usage="
Usage: build [OPTIONS]
Build BSP components (kernel and bootloader).

Options: 
  -b, --board BOARD              Target board name.
  -k, --menuconfig               Run kernel menuconfig (yes/no).
  -g, --target                   Kernel target/branch.
  -l, --local                    Use local sources (default: yes, auto-fetch if missing).
  -i, --mirror GITHUB_MIRROR     GitHub mirror URL.
  -e, --ccache                   Use ccache (default: yes).
  -o, --kernel-only              Build kernel only (yes/no).
  -c, --clean                    Clean output directory (yes/no).
  -h, --help                     Show help.

Defaults (Smart Mode):
  - ccache: enabled (faster rebuilds)
  - local sources: enabled (auto-fetch if not found)
  - To force re-fetch: use -l no

Special Commands:
  ./build.sh clean               Clean output directory and fix line endings.
  ./build.sh clean --all         Clean everything including source files.
"

show_help()
{
    echo "$__usage"
    exit $1
}

clean_workspace()
{
    local CLEAN_ALL=$1
    
    echo "=========================================="
    echo "BSP Cleanup"
    echo "=========================================="
    echo ""
    
    BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    OUTPUT_DIR="${BASE_DIR}/output"
    
    # Clean output directory
    echo "Step 1: Cleaning output directory..."
    if [ -d "${OUTPUT_DIR}" ]; then
        if [ "${CLEAN_ALL}" == "--all" ]; then
            # Remove everything
            if [ -w "${OUTPUT_DIR}" ]; then
                rm -rf "${OUTPUT_DIR}" 2>/dev/null
                if [ $? -eq 0 ]; then
                    echo "  ✓ Removed output/"
                else
                    echo "  ⚠ Failed to remove output/ (permission denied)"
                    echo "  Run: sudo ./build.sh clean --all"
                fi
            else
                echo "  ⚠ Output directory requires sudo permissions"
                echo "  Run: sudo ./build.sh clean --all"
            fi
        else
            # Remove only build artifacts, keep sources
            CLEANED=0
            for dir in ${OUTPUT_DIR}/bootloader-* ${OUTPUT_DIR}/*-kernel-pkgs; do
                if [ -d "$dir" ]; then
                    rm -rf "$dir" 2>/dev/null && {
                        echo "  ✓ Removed $(basename $dir)"
                        CLEANED=$((CLEANED + 1))
                    } || {
                        echo "  ⚠ Failed to remove $(basename $dir) (try sudo)"
                    }
                fi
            done
            if [ $CLEANED -eq 0 ]; then
                echo "  (No build artifacts found)"
            fi
        fi
    else
        echo "  (Output directory not found)"
    fi
    echo ""
    
    # Fix line endings
    echo "Step 2: Fixing line endings..."
    FIXED=0
    
    cd "${BASE_DIR}"
    
    # Fix configs/
    if [ -d "configs" ]; then
        find configs/ -type f \( -name "*.sh" -o -name "*.conf" \) 2>/dev/null | while read -r file; do
            if [ -f "$file" ] && file "$file" | grep -q CRLF; then
                sed -i 's/\r$//' "$file"
                echo "  ✓ Fixed $file"
                FIXED=$((FIXED + 1))
            fi
        done
    fi
    
    # Fix tools/
    if [ -d "tools" ]; then
        find tools/ -type f -name "*.sh" 2>/dev/null | while read -r file; do
            if [ -f "$file" ] && file "$file" | grep -q CRLF; then
                sed -i 's/\r$//' "$file"
                echo "  ✓ Fixed $file"
                FIXED=$((FIXED + 1))
            fi
        done
    fi
    
    # Fix root scripts
    for script in build.sh cleanup.sh; do
        if [ -f "$script" ] && file "$script" | grep -q CRLF; then
            sed -i 's/\r$//' "$script"
            echo "  ✓ Fixed $script"
            FIXED=$((FIXED + 1))
        fi
    done
    
    if [ $FIXED -eq 0 ]; then
        echo "  (All files already in Unix format)"
    fi
    echo ""
    
    echo "=========================================="
    echo "Cleanup completed!"
    echo "=========================================="
    exit 0
}

init_params() {
    BOARD=none
    MENUCONFIG=no
    KERNEL_TARGET=bsp
    USE_LOCAL=yes
    GITHUB_MIRROR=no
    KERNEL_ONLY=no
    USE_CCACHE=yes
    CLEAN=no
}

parse_args()
{
    if [ "x$#" == "x0" ]; then
        INTERACTIVE=yes
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
        elif [ "x$1" == "x-l" -o "x$1" == "x--local" ]; then
            if [ "x$2" == "x" ] || [[ "$2" == -* ]]; then
                USE_LOCAL=yes
                shift
            else
                USE_LOCAL=`echo $2`
                shift
                shift
            fi
        elif [ "x$1" == "x-i" -o "x$1" == "x--mirror" ]; then
            GITHUB_MIRROR=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-o" -o "x$1" == "x--kernel-only" ]; then
            KERNEL_ONLY=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-e" -o "x$1" == "x--ccache" ]; then
            USE_CCACHE=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-c" -o "x$1" == "x--clean" ]; then
            CLEAN=`echo $2`
            shift
            shift
        else
            echo `date` - ERROR, UNKNOWN params "$@"
            return 2
        fi
    done
}

show_dialog()
{
    if [ "${INTERACTIVE}" != "yes" ]; then
        return 0
    fi

    if ! command -v dialog &> /dev/null; then
        echo "ERROR: 'dialog' command not found. Install with: sudo apt-get install dialog"
        echo "Or use command line arguments instead."
        exit 1
    fi

    # Get available targets
    TARGETS=$(ls -1 ${CONFIG_DIR}/*.conf 2>/dev/null | sed 's/.*\///;s/\.conf$//')
    if [ -z "$TARGETS" ]; then
        echo "ERROR: No configuration files found in ${CONFIG_DIR}/"
        echo "Create a config file in ${CONFIG_DIR}/"
        exit 1
    fi

    # Select board
    if [ "${BOARD}" == "none" ]; then
        tmp=`mktemp -t build.XXXXXX`
        MENU=""
        for tgt in $TARGETS; do
            MENU="$MENU $tgt \"$tgt\""
        done
        
        dialog --clear --shadow --backtitle "BSP Build" --title "Select Target" \
            --menu "Choose target board:" 15 60 8 \
            $MENU 2> $tmp
        
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        BOARD=$(cat $tmp)
        clear
        rm $tmp
    fi

    # Load config
    CONFIG_FILE="${CONFIG_DIR}/${BOARD}.conf"
    if [ ! -f "${CONFIG_FILE}" ]; then
        echo "ERROR: Config file not found: ${CONFIG_FILE}"
        exit 1
    fi
    source "${CONFIG_FILE}"
    
    # Select kernel target
    if [ "${INTERACTIVE}" == "yes" ]; then
        IFS=',' read -ra BRANCHES <<< "${KERNEL_BRANCH}"
        if [ ${#BRANCHES[@]} -gt 1 ] || [ "${KERNEL_TARGET}" == "bsp" ]; then
            MENU=""
            for br in "${BRANCHES[@]}"; do
                MENU="$MENU ${br} \"${br} Branch\""
            done
            
            tmp=`mktemp -t build.XXXXXX`
            dialog --clear --shadow --backtitle "BSP Build" --title "Kernel Target" \
                --menu "Select kernel target:" 15 60 8 \
                $MENU 2> $tmp
            
            if [ $? == 1 ]; then
                rm $tmp
                exit 2
            fi
            KERNEL_TARGET=$(cat $tmp)
            clear
            rm $tmp
            source "${CONFIG_FILE}"
        fi
    fi
    
    # Select menuconfig
    if [ "${MENUCONFIG}" == "no" ] && [ "${INTERACTIVE}" == "yes" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "Kernel Configuration" \
            --menu "Run menuconfig?" 15 60 2 \
            no "No" \
            yes "Yes" \
            2> $tmp
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        MENUCONFIG=$(cat $tmp)
        clear
        rm $tmp
    fi
    
    # Select kernel only
    if [ "${KERNEL_ONLY}" == "no" ] && [ "${INTERACTIVE}" == "yes" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "Build Mode" \
            --menu "Build kernel only?" 15 60 2 \
            no "No" \
            yes "Yes" \
            2> $tmp
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        KERNEL_ONLY=$(cat $tmp)
        clear
        rm $tmp
    fi
    
    # Select use local
    if [ "${USE_LOCAL}" == "no" ] && [ "${INTERACTIVE}" == "yes" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "Source Management" \
            --menu "Use local sources?" 15 60 2 \
            no "No" \
            yes "Yes" \
            2> $tmp
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        USE_LOCAL=$(cat $tmp)
        clear
        rm $tmp
    fi
    
    # Select ccache
    if [ "${USE_CCACHE}" == "no" ] && [ "${INTERACTIVE}" == "yes" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "Compilation" \
            --menu "Use ccache?" 15 60 2 \
            no "No" \
            yes "Yes" \
            2> $tmp
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        USE_CCACHE=$(cat $tmp)
        clear
        rm $tmp
    fi
    
    # Select clean
    if [ "${CLEAN}" == "no" ] && [ "${INTERACTIVE}" == "yes" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "Clean Build" \
            --menu "Clean output directory?" 15 60 2 \
            no "No" \
            yes "Yes" \
            2> $tmp
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        CLEAN=$(cat $tmp)
        clear
        rm $tmp
    fi
    
    # GitHub mirror
    if [ "${GITHUB_MIRROR}" == "no" ] && [ "${INTERACTIVE}" == "yes" ] && [ "${USE_LOCAL}" == "no" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "GitHub Mirror" \
            --menu "Use GitHub mirror?" 15 60 2 \
            no "No" \
            yes "Yes" \
            2> $tmp
        
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        
    
        IF_MIRROR=$(cat $tmp)
        if [ "${IF_MIRROR}" == "yes" ]; then
            tmp2=`mktemp -t build.XXXXXX`
            dialog --clear --shadow --backtitle "BSP Build" \
                --title "GitHub Mirror URL" \
                --inputbox "Enter mirror URL:" 15 60 "https://mirror.ghproxy.com" 2> $tmp2
            
            if [ $? == 1 ]; then
                rm $tmp2 $tmp
                exit 2
            fi
            GITHUB_MIRROR=$(cat $tmp2)
            rm $tmp2
        fi
        clear
        rm $tmp
    fi
    
    clear
}

check_deps() {
    echo "Checking dependencies..."
    MISSING=""
    
    for tool in gcc make git bc; do
        if ! command -v $tool &> /dev/null; then
            MISSING="$MISSING $tool"
        fi
    done
    
    if [ "${ARCH}" == "arm64" ]; then
        if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
            MISSING="$MISSING gcc-aarch64-linux-gnu"
        fi
    elif [ "${ARCH}" == "arm" ]; then
        if ! command -v arm-linux-gnueabihf-gcc &> /dev/null; then
            MISSING="$MISSING gcc-arm-linux-gnueabihf"
        fi
    fi
    
    if [ -n "$MISSING" ]; then
        echo "WARNING: Missing:$MISSING"
        echo "Install: sudo apt-get install$MISSING dialog"
        if [ "${INTERACTIVE}" != "yes" ]; then
            read -p "Continue? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            read -p "Press Enter to continue..."
        fi
    fi
}

show_config(){
    echo "+-------[ Build Config ]--------"
    echo "| Board=${BOARD}"
    echo "| Arch=${ARCH:-unknown}"
    echo "| Menuconfig=${MENUCONFIG}"
    echo "| Target=${KERNEL_TARGET:-bsp}"
    echo "| Local=${USE_LOCAL}"
    echo "| Mirror=${GITHUB_MIRROR}"
    echo "| KernelOnly=${KERNEL_ONLY}"
    echo "| Ccache=${USE_CCACHE}"
    echo "| Clean=${CLEAN}"
    echo "| LinuxRepo=${LINUX_REPO:-unknown}"
    echo "| LinuxBranch=${LINUX_BRANCH:-unknown}"
    echo "| LinuxConfig=${LINUX_CONFIG:-unknown}"
    echo "+-------------------------------"
    if [ -n "${KERNEL_TARGET}" ]; then
        echo "Next time run:"
        echo "sudo ./build.sh -b ${BOARD} -k ${MENUCONFIG} -g ${KERNEL_TARGET} -l ${USE_LOCAL} -i ${GITHUB_MIRROR} -o ${KERNEL_ONLY} -e ${USE_CCACHE} -c ${CLEAN}"
        echo "-------------------------------"
    fi
}

# Main
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${BASE_DIR}/configs"
TOOLS_DIR="${BASE_DIR}/tools"
OUTPUT_DIR="${BASE_DIR}/output"

# Handle clean command
if [ "$1" == "clean" ]; then
    clean_workspace "$2"
fi

INTERACTIVE=no
init_params
parse_args "$@" || show_help $?

show_dialog

if [ "${BOARD}" == "none" ]; then
    echo "ERROR: Board name required"
    echo "Available:"
    ls -1 ${CONFIG_DIR}/*.conf 2>/dev/null | sed 's/.*\///;s/\.conf$//' || echo "  (none)"
    exit 1
fi

CONFIG_FILE="${CONFIG_DIR}/${BOARD}.conf"
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "ERROR: Config not found: ${CONFIG_FILE}"
    exit 1
fi

source "${CONFIG_FILE}"

if [ "${KERNEL_TARGET}" != "bsp" ]; then
    source "${CONFIG_FILE}"
fi

check_deps
show_config

if [ ! -d "${TOOLS_DIR}" ]; then
    mkdir -p "${TOOLS_DIR}"
fi

if [ "${CLEAN}" == "yes" ]; then
    echo "Cleaning output directory..."
    sudo rm -rf ${OUTPUT_DIR}
fi

if [ ! -d ${OUTPUT_DIR} ]; then
    mkdir -p ${OUTPUT_DIR}
fi

cd ${OUTPUT_DIR}
WORKSPACE=$(pwd)

echo "Workspace: ${WORKSPACE}"
echo "Tools: ${TOOLS_DIR}"
echo "Configs: ${CONFIG_DIR}"

# Fetch sources
echo "=========================================="
echo "Step 1: Checking sources..."
echo "=========================================="

# Smart source management
NEED_FETCH=no

if [ "${USE_LOCAL}" == "yes" ]; then
    # Check if local sources exist
    if [ ! -d "${WORKSPACE}/linux" ] || [ ! -d "${WORKSPACE}/linux/.git" ]; then
        echo "⚠ Local sources not found, will fetch automatically."
        NEED_FETCH=yes
    else
        echo "✓ Using local sources"
        echo "  Kernel source: ${WORKSPACE}/linux"
    fi
else
    # User explicitly wants to fetch
    echo "Fetching sources (forced by -l no)..."
    NEED_FETCH=yes
fi

# Fetch if needed
if [ "${NEED_FETCH}" == "yes" ]; then
    echo ""
    echo "Fetching sources..."
    FETCH_TOOL="${TOOLS_DIR}/get-sources.sh"
    if [ ! -f "${FETCH_TOOL}" ]; then
        echo "ERROR: Tool not found: ${FETCH_TOOL}"
        exit 1
    fi
    sudo bash ${FETCH_TOOL} -b "${BOARD}" -i "${GITHUB_MIRROR}" -g "${KERNEL_TARGET}"
    if [ $? -ne 0 ]; then
        echo "ERROR: Fetch failed"
        exit 1
    fi
fi
echo ""

# Build bootloader
if [ "${KERNEL_ONLY}" == "no" ]; then
    echo "=========================================="
    echo "Step 2: Building bootloader..."
    echo "=========================================="
    if [[ -f ${WORKSPACE}/bootloader-${BOARD}/.done && \
        $(cat ${WORKSPACE}/bootloader-${BOARD}/.done) == "${BOARD}" ]]; then
        echo "Bootloader already built, skipping."
    else
        BOOT_TOOL="${TOOLS_DIR}/build-boot.sh"
        if [ ! -f "${BOOT_TOOL}" ]; then
            echo "ERROR: Tool not found: ${BOOT_TOOL}"
            exit 1
        fi
        sudo bash ${BOOT_TOOL} -b "${BOARD}"
        if [ $? -ne 0 ]; then
            echo "ERROR: Bootloader build failed"
            exit 1
        fi
    fi
else
    echo "=========================================="
    echo "Step 2: Skipping bootloader (kernel only)"
    echo "=========================================="
fi

# Build kernel
echo "=========================================="
echo "Step 3: Building kernel..."
echo "=========================================="
if [[ -f ${WORKSPACE}/${BOARD}-kernel-pkgs/.done && \
    $(cat ${WORKSPACE}/${BOARD}-kernel-pkgs/.done) == "${LINUX_CONFIG}" ]]; then
    echo "Kernel packages already built, skipping."
else
    KERNEL_TOOL="${TOOLS_DIR}/build-kernel.sh"
    if [ ! -f "${KERNEL_TOOL}" ]; then
        echo "ERROR: Tool not found: ${KERNEL_TOOL}"
        exit 1
    fi
    sudo bash ${KERNEL_TOOL} -b "${BOARD}" -k "${MENUCONFIG}" -g "${KERNEL_TARGET}" -e "${USE_CCACHE}"
    if [ $? -ne 0 ]; then
        echo "ERROR: Kernel build failed"
        exit 1
    fi
fi

# Summary
echo "=========================================="
echo "Build Summary"
echo "=========================================="
if [ "${KERNEL_ONLY}" == "no" ]; then
    if [ -d ${WORKSPACE}/bootloader-${BOARD} ]; then
        echo "✓ Bootloader: ${WORKSPACE}/bootloader-${BOARD}"
        ls -lh ${WORKSPACE}/bootloader-${BOARD}/* 2>/dev/null | head -5
    fi
fi

if [ -d ${WORKSPACE}/${BOARD}-kernel-pkgs ]; then
    echo "✓ Kernel packages: ${WORKSPACE}/${BOARD}-kernel-pkgs"
    ls -lh ${WORKSPACE}/${BOARD}-kernel-pkgs/*.deb 2>/dev/null | head -5
fi

echo ""
echo "Build completed successfully!"
echo "Output: ${WORKSPACE}"

