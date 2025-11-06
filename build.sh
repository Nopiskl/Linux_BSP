#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# BSP Build Framework
# Lightweight and independent build system for BSP development

__usage="
Usage: build [OPTIONS]
Build BSP components (kernel, bootloader, and rootfs).

Options: 
  -b, --board BOARD              Target board name.
  -k, --menuconfig               Run kernel menuconfig (yes/no).
  -g, --target                   Kernel target/branch.
  -l, --local                    Use local sources (default: yes, auto-fetch if missing).
  -i, --mirror GITHUB_MIRROR     GitHub mirror URL.
  -e, --ccache                   Use ccache (default: yes).
  -o, --kernel-only              Build kernel only (yes/no).
  -c, --clean                    Clean output directory (yes/no).
  -r, --build-rootfs             Build rootfs (yes/no).
  -v, --distro-version           Distro version (ubuntu/jammy, debian/bookworm, etc).
  -t, --rootfs-type              Rootfs type (cli, xfce, gnome, kde, lxqt).
  -m, --apt-mirror               APT mirror URL.
  -h, --help                     Show help.
  -d, --docs                     View documentation.

Defaults (Smart Mode):
  - ccache: enabled (faster rebuilds)
  - local sources: enabled (auto-fetch if not found)
  - To force re-fetch: use -l no

Special Commands:
  ./build.sh clean               Clean output directory and fix line endings.
  ./build.sh clean --all         Clean everything including source files.
  ./build.sh docs                View interactive documentation.

Documentation:
  Complete documentation available in docs/ directory.
  Quick access: ./build.sh docs or ./docs/view-docs.sh
  Online guide: docs/00-快速开始.md
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
    BUILD_ROOTFS=none
    DISTRO_VERSION=none
    ROOTFS_TYPE=none
    APT_MIRROR=none
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
        elif [ "x$1" == "x-d" -o "x$1" == "x--docs" ]; then
            # 查看文档
            DOCS_DIR="${BASE_DIR}/docs"
            if [ -x "${DOCS_DIR}/view-docs.sh" ]; then
                echo "📚 Opening documentation viewer..."
                bash "${DOCS_DIR}/view-docs.sh"
            else
                echo "📚 Documentation available in: ${DOCS_DIR}/"
                echo ""
                echo "Available documents:"
                ls -1 "${DOCS_DIR}"/*.md 2>/dev/null | sed 's|.*/||'
                echo ""
                echo "To view: less ${DOCS_DIR}/00-快速开始.md"
            fi
            exit 0
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
        elif [ "x$1" == "x-r" -o "x$1" == "x--build-rootfs" ]; then
            BUILD_ROOTFS=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-v" -o "x$1" == "x--distro-version" ]; then
            DISTRO_VERSION=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-t" -o "x$1" == "x--rootfs-type" ]; then
            ROOTFS_TYPE=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-m" -o "x$1" == "x--apt-mirror" ]; then
            APT_MIRROR=`echo $2`
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
    
    # Select build rootfs
    if [ "${BUILD_ROOTFS}" == "none" ] && [ "${INTERACTIVE}" == "yes" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "Build RootFS" \
            --menu "Build root filesystem?" 15 60 2 \
            no "No, kernel and bootloader only" \
            yes "Yes, build complete system" \
            2> $tmp
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        BUILD_ROOTFS=$(cat $tmp)
        clear
        rm $tmp
    fi
    
    # Select distro version
    if [ "${BUILD_ROOTFS}" == "yes" ] && [ "${DISTRO_VERSION}" == "none" ] && [ "${INTERACTIVE}" == "yes" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "System Distribution" \
            --menu "Select Linux distribution:" 20 70 10 \
            "ubuntu/focal" "Ubuntu 20.04 LTS Focal Fossa" \
            "ubuntu/jammy" "Ubuntu 22.04 LTS Jammy Jellyfish ⭐" \
            "ubuntu/noble" "Ubuntu 24.04 LTS Noble Numbat" \
            "debian/bullseye" "Debian 11 Bullseye" \
            "debian/bookworm" "Debian 12 Bookworm ⭐" \
            "debian/trixie" "Debian 13 Trixie (Testing)" \
            2> $tmp
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        DISTRO_VERSION=$(cat $tmp)
        clear
        rm $tmp
    fi
    
    # Select rootfs type
    if [ "${BUILD_ROOTFS}" == "yes" ] && [ "${ROOTFS_TYPE}" == "none" ] && [ "${INTERACTIVE}" == "yes" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "System Type" \
            --menu "Select rootfs type:" 18 70 8 \
            cli "Console/CLI (Minimal, ~500MB)" \
            xfce "XFCE Desktop (Lightweight, ~2GB)" \
            gnome "GNOME Desktop (Full-featured, ~4GB)" \
            kde "KDE Plasma Desktop (Modern, ~4GB)" \
            lxqt "LXQt Desktop (Ultra-light, ~1.5GB)" \
            2> $tmp
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        ROOTFS_TYPE=$(cat $tmp)
        clear
        rm $tmp
    fi
    
    # Select APT mirror
    if [ "${BUILD_ROOTFS}" == "yes" ] && [ "${APT_MIRROR}" == "none" ] && [ "${INTERACTIVE}" == "yes" ]; then
        tmp=`mktemp -t build.XXXXXX`
        dialog --clear --shadow --backtitle "BSP Build" --title "APT Mirror" \
            --menu "Select APT mirror source:" 20 75 10 \
            "auto" "Auto-detect (use official mirror)" \
            "ustc" "USTC Mirror (China, https://mirrors.ustc.edu.cn)" \
            "tuna" "Tsinghua Mirror (China, https://mirrors.tuna.tsinghua.edu.cn)" \
            "aliyun" "Aliyun Mirror (China, https://mirrors.aliyun.com)" \
            "huawei" "Huawei Mirror (China, https://mirrors.huaweicloud.com)" \
            "official" "Official Mirror (International)" \
            "custom" "Custom URL (will prompt)" \
            2> $tmp
        if [ $? == 1 ]; then
            rm $tmp
            exit 2
        fi
        MIRROR_CHOICE=$(cat $tmp)
        clear
        rm $tmp
        
        # Handle mirror choice
        case "${MIRROR_CHOICE}" in
            auto)
                APT_MIRROR=""
                ;;
            ustc)
                if [[ "${DISTRO_VERSION}" == ubuntu/* ]]; then
                    APT_MIRROR="https://mirrors.ustc.edu.cn/ubuntu-ports"
                else
                    APT_MIRROR="https://mirrors.ustc.edu.cn/debian"
                fi
                ;;
            tuna)
                if [[ "${DISTRO_VERSION}" == ubuntu/* ]]; then
                    APT_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports"
                else
                    APT_MIRROR="https://mirrors.tuna.tsinghua.edu.cn/debian"
                fi
                ;;
            aliyun)
                if [[ "${DISTRO_VERSION}" == ubuntu/* ]]; then
                    APT_MIRROR="https://mirrors.aliyun.com/ubuntu-ports"
                else
                    APT_MIRROR="https://mirrors.aliyun.com/debian"
                fi
                ;;
            huawei)
                if [[ "${DISTRO_VERSION}" == ubuntu/* ]]; then
                    APT_MIRROR="https://mirrors.huaweicloud.com/ubuntu-ports"
                else
                    APT_MIRROR="https://mirrors.huaweicloud.com/debian"
                fi
                ;;
            official)
                APT_MIRROR=""
                ;;
            custom)
                tmp=`mktemp -t build.XXXXXX`
                dialog --clear --shadow --backtitle "BSP Build" --title "Custom Mirror URL" \
                    --inputbox "Enter APT mirror URL:" 10 70 \
                    2> $tmp
                if [ $? == 1 ]; then
                    rm $tmp
                    exit 2
                fi
                APT_MIRROR=$(cat $tmp)
                clear
                rm $tmp
                ;;
        esac
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
    if [ "${BUILD_ROOTFS}" == "yes" ]; then
        echo "+-------[ RootFS Config ]-------"
        echo "| BuildRootFS=${BUILD_ROOTFS}"
        echo "| Distro=${DISTRO_VERSION}"
        echo "| Type=${ROOTFS_TYPE}"
        echo "| APT Mirror=${APT_MIRROR:-auto}"
        echo "+-------------------------------"
    fi
    if [ -n "${KERNEL_TARGET}" ]; then
        echo "Next time run:"
        if [ "${BUILD_ROOTFS}" == "yes" ]; then
            echo "sudo ./build.sh -b ${BOARD} -k ${MENUCONFIG} -g ${KERNEL_TARGET} -l ${USE_LOCAL} -i ${GITHUB_MIRROR} -o ${KERNEL_ONLY} -e ${USE_CCACHE} -c ${CLEAN} -r ${BUILD_ROOTFS} -v ${DISTRO_VERSION} -t ${ROOTFS_TYPE} -m \"${APT_MIRROR}\""
        else
            echo "sudo ./build.sh -b ${BOARD} -k ${MENUCONFIG} -g ${KERNEL_TARGET} -l ${USE_LOCAL} -i ${GITHUB_MIRROR} -o ${KERNEL_ONLY} -e ${USE_CCACHE} -c ${CLEAN}"
        fi
        echo "-------------------------------"
    fi
}

# Main
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${BASE_DIR}/configs"
TOOLS_DIR="${BASE_DIR}/tools"
OUTPUT_DIR="${BASE_DIR}/output"

# Handle special commands
if [ "$1" == "clean" ]; then
    clean_workspace "$2"
fi

# Handle docs command
if [ "$1" == "docs" ]; then
    DOCS_DIR="${BASE_DIR}/docs"
    if [ -x "${DOCS_DIR}/view-docs.sh" ]; then
        echo "📚 Opening documentation viewer..."
        bash "${DOCS_DIR}/view-docs.sh"
    else
        echo "📚 Documentation available in: ${DOCS_DIR}/"
        echo ""
        echo "Available documents:"
        ls -1 "${DOCS_DIR}"/*.md 2>/dev/null | sed 's|.*/||'
        echo ""
        echo "Quick start: less ${DOCS_DIR}/00-快速开始.md"
    fi
    exit 0
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

# Build RootFS
if [ "${BUILD_ROOTFS}" == "yes" ] && [ "${KERNEL_ONLY}" == "no" ]; then
    echo "=========================================="
    echo "Step 4: Building RootFS..."
    echo "=========================================="
    
    # 解析发行版信息（处理 ubuntu/jammy 格式）
    if [[ "${DISTRO_VERSION}" == *"/"* ]]; then
        DISTRO_TYPE=$(echo ${DISTRO_VERSION} | cut -d'/' -f1)
        DISTRO_VER=$(echo ${DISTRO_VERSION} | cut -d'/' -f2)
    else
        # 自动检测发行版类型
        if [[ "${DISTRO_VERSION}" == "jammy" || "${DISTRO_VERSION}" == "focal" || "${DISTRO_VERSION}" == "noble" ]]; then
            DISTRO_TYPE="ubuntu"
            DISTRO_VER="${DISTRO_VERSION}"
        elif [[ "${DISTRO_VERSION}" == "bullseye" || "${DISTRO_VERSION}" == "bookworm" || "${DISTRO_VERSION}" == "trixie" ]]; then
            DISTRO_TYPE="debian"
            DISTRO_VER="${DISTRO_VERSION}"
        else
            DISTRO_TYPE="unknown"
            DISTRO_VER="${DISTRO_VERSION}"
        fi
    fi
    
    # 构建 rootfs 压缩包路径（参考 AvaotaOS）
    ROOTFS_TARBALL="${WORKSPACE}/rootfs-${DISTRO_TYPE}-${DISTRO_VER}-${ROOTFS_TYPE}.tar.gz"
    
    # 检查是否已存在 rootfs 压缩包（参考 AvaotaOS 的缓存机制）
    if [ -f "${ROOTFS_TARBALL}" ]; then
        echo ""
        echo "✓ Found existing rootfs tarball, skip build rootfs."
        echo "  File: ${ROOTFS_TARBALL}"
        ls -lh "${ROOTFS_TARBALL}"
        echo ""
        echo "💡 Tip: To rebuild rootfs, delete the tarball first:"
        echo "    rm ${ROOTFS_TARBALL}"
        echo ""
    else
        ROOTFS_TOOL="${TOOLS_DIR}/build-rootfs.sh"
        if [ ! -f "${ROOTFS_TOOL}" ]; then
            echo "ERROR: Tool not found: ${ROOTFS_TOOL}"
            exit 1
        fi
        
        # Build RootFS arguments
        ROOTFS_ARGS="-b ${BOARD} -v ${DISTRO_VERSION} -t ${ROOTFS_TYPE}"
        if [ -n "${APT_MIRROR}" ]; then
            ROOTFS_ARGS="${ROOTFS_ARGS} -m ${APT_MIRROR}"
        fi
        
        echo "Building RootFS with args: ${ROOTFS_ARGS}"
        cd ${WORKSPACE}
        sudo bash ${ROOTFS_TOOL} ${ROOTFS_ARGS}
        if [ $? -ne 0 ]; then
            echo "ERROR: RootFS build failed"
            exit 1
        fi
        cd ${BASE_DIR}
    fi
fi

# Summary
echo ""
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

if [ "${BUILD_ROOTFS}" == "yes" ]; then
    ROOTFS_TARBALL=$(ls -t ${WORKSPACE}/rootfs-*.tar.gz 2>/dev/null | head -1)
    if [ -n "${ROOTFS_TARBALL}" ]; then
        echo "✓ RootFS tarball: ${ROOTFS_TARBALL}"
        ls -lh "${ROOTFS_TARBALL}"
    fi
fi

echo ""
echo "Build completed successfully!"
echo "Output: ${WORKSPACE}"

