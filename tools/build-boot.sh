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
  -m, --menuconfig               Run U-Boot menuconfig (yes/no).
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
        elif [ "x$1" == "x-m" -o "x$1" == "x--menuconfig" ]; then
            MENUCONFIG=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-e" -o "x$1" == "x--ccache" ]; then
            USE_CCACHE=`echo $2`
            shift
            shift
        else
            echo "ERROR: Unknown parameter: $1"
            return 2
        fi
    done
}

# 应用 U-Boot 补丁
patch_uboot()
{
    local patchdir=$1
    local targetdir=$2
    
    if [ ! -d "${targetdir}" ];then
        echo "ERROR: U-Boot source directory not found: ${targetdir}"
        return 1
    fi
    
    echo "Applying U-Boot patches from: ${patchdir}"
    
    # 应用补丁文件
    if [ -d "${TOOL_DIR}/../patches/uboot/${patchdir}/patches" ];then
        for pth in $(ls "${TOOL_DIR}/../patches/uboot/${patchdir}/patches" 2>/dev/null)
        do
            echo "  Applying patch: ${pth}"
            cp "${TOOL_DIR}/../patches/uboot/${patchdir}/patches/${pth}" "${targetdir}/"
            pushd "${targetdir}" > /dev/null
            patch -p1 < "${pth}" || {
                echo "ERROR: Failed to apply patch: ${pth}"
                popd > /dev/null
                return 1
            }
            rm "${pth}"
            popd > /dev/null
        done
        echo "  Patches applied successfully"
    else
        echo "  No patch directory found (skipping)"
    fi
    
    # 复制额外文件
    if [ -d "${TOOL_DIR}/../patches/uboot/${patchdir}/files" ];then
        echo "  Copying additional files..."
        cp -rv "${TOOL_DIR}/../patches/uboot/${patchdir}/files/"* "${targetdir}/"
        sync
    fi
}

is_mainline_uboot()
{
    [ "${BL_CONFIG}" = "mainline-uboot" ] || [ "${BL_CONFIG}" = "sunxi-uboot" ]
}

find_uboot_dts_file()
{
    local uboot_dts=$1
    local source_root="${WORKSPACE}/${BL_CONFIG}"
    local dts_basename
    dts_basename="$(basename "${uboot_dts}")"

    local candidates=(
        "${source_root}/dts/upstream/src/${UBOOT_ARCH}/${uboot_dts}.dts"
        "${source_root}/dts/upstream/src/arm64/${uboot_dts}.dts"
        "${source_root}/dts/upstream/src/arm/${uboot_dts}.dts"
        "${source_root}/arch/arm/dts/${uboot_dts}.dts"
        "${source_root}/arch/arm/dts/${dts_basename}.dts"
    )

    local candidate
    for candidate in "${candidates[@]}"; do
        if [ -f "${candidate}" ]; then
            echo "${candidate}"
            return 0
        fi
    done

    if [ -d "${source_root}/dts/upstream/src/${UBOOT_ARCH}" ]; then
        echo "${source_root}/dts/upstream/src/${UBOOT_ARCH}/${uboot_dts}.dts"
    elif [ -d "${source_root}/dts/upstream/src/arm64" ]; then
        echo "${source_root}/dts/upstream/src/arm64/${uboot_dts}.dts"
    else
        echo "${source_root}/arch/arm/dts/${uboot_dts}.dts"
    fi
}

format_uboot_dts_path()
{
    local full_path=$1
    local source_root="${WORKSPACE}/${BL_CONFIG}/"
    echo "${full_path#${source_root}}"
}

deploy_uboot_dts()
{
    local uboot_dts="${UBOOT_DTS}"

    if [ -z "${uboot_dts}" ]; then
        return 0
    fi

    local target_board="${TARGET_BOARD:-${BOARD_NAME:-${BOARD}}}"
    local source_file="${BASE_DIR}/configs/target/${target_board}/uboot.dts"
    local target_file
    target_file="$(find_uboot_dts_file "${uboot_dts}")"
    local target_dir

    if [ -f "${source_file}" ]; then
        if [ -s "${source_file}" ]; then
            target_dir="$(dirname "${target_file}")"
            mkdir -p "${target_dir}"
            cp "${source_file}" "${target_file}"
            echo "Deployed U-Boot DTS: ${source_file} -> ${target_file}"
            return 0
        fi
        echo "Target U-Boot DTS exists but is empty: ${source_file}"
        echo "Falling back to U-Boot source DTS: $(format_uboot_dts_path "${target_file}")"
    else
        echo "Target U-Boot DTS not found: ${source_file}"
        echo "Falling back to U-Boot source DTS: $(format_uboot_dts_path "${target_file}")"
    fi

    if [ ! -s "${source_file}" ]; then
        if [ -f "${target_file}" ]; then
            echo "U-Boot DTS found in source tree: $(format_uboot_dts_path "${target_file}")"
        else
            echo "Notice: No board-specific U-Boot DTS override for ${uboot_dts}"
        fi
        return 0
    fi
}

# 编译 ARM Trusted Firmware (ATF)
compile_atf()
{
    echo "=========================================="
    echo "Compiling ARM Trusted Firmware (ATF)"
    echo "=========================================="
    
    if [ ! -d "${WORKSPACE}/atf" ];then
        echo "ERROR: ATF source directory not found: ${WORKSPACE}/atf"
        echo "Please run get-sources.sh first"
        exit 1
    fi
    
    cd "${WORKSPACE}/atf"
    
    # 清理之前的构建
    echo "Cleaning ATF build directory..."
    make distclean 2>/dev/null || true
    
    # 从 UBOOT_DEFCONFIG 自动推断 ATF 平台
    if [ -n "${ATF_PLAT}" ]; then
        # 配置文件中显式指定（高级用法）
        echo "Using ATF_PLAT from config: ${ATF_PLAT}"
    else
        # 自动推断（推荐方式）
        if [[ "${UBOOT_DEFCONFIG}" == *"h618"* ]] || [[ "${UBOOT_DEFCONFIG}" == *"h616"* ]]; then
            ATF_PLAT="sun50i_h616"
        elif [[ "${UBOOT_DEFCONFIG}" == *"h6"* ]]; then
            ATF_PLAT="sun50i_h6"
        elif [[ "${UBOOT_DEFCONFIG}" == *"a64"* ]]; then
            ATF_PLAT="sun50i_a64"
        elif [[ "${UBOOT_DEFCONFIG}" == *"t527"* ]] || [[ "${UBOOT_DEFCONFIG}" == *"t507"* ]]; then
            ATF_PLAT="sun50i_h616"  # T527 使用 H616 平台
        else
            ATF_PLAT="sun50i_h616"  # 默认平台
        fi
        echo "Auto-detected ATF_PLAT: ${ATF_PLAT}"
    fi
    
    # ATF 调试模式（默认使用 debug）
    ATF_DEBUG="${ATF_DEBUG:-1}"
    
    echo "Building ATF with configuration:"
    echo "  Platform: ${ATF_PLAT}"
    echo "  Debug mode: ${ATF_DEBUG}"
    echo "  Cross Compiler: ${ATF_GCC}"
    echo ""
    
    # 编译 ATF BL31
    make CROSS_COMPILE=${ATF_GCC} \
         PLAT=${ATF_PLAT} \
         DEBUG=${ATF_DEBUG} \
         bl31
    
    if [ $? -ne 0 ];then
        echo "ERROR: ATF build failed"
        exit 1
    fi
    
    # 查找生成的 bl31.bin
    BL31_BIN=$(find build -name "bl31.bin" | head -n 1)
    if [ -z "${BL31_BIN}" ];then
        echo "ERROR: bl31.bin not found after build"
        exit 1
    fi
    
    echo "[OK] ATF build successful"
    echo "  BL31: ${WORKSPACE}/atf/${BL31_BIN}"
    
    cd "${WORKSPACE}"
}

# 编译 U-Boot
compile_uboot()
{
    echo "=========================================="
    echo "Compiling U-Boot Bootloader"
    echo "=========================================="
    
    if [ ! -d "${WORKSPACE}/${BL_CONFIG}" ];then
        echo "ERROR: U-Boot source directory not found: ${WORKSPACE}/${BL_CONFIG}"
        echo "Please run get-sources.sh first"
        exit 1
    fi
    
    cd "${WORKSPACE}/${BL_CONFIG}"
    
    # 设置 make 命令
    MAKE="make"
    if [ "${USE_CCACHE}" == "yes" ];then
        if command -v ccache > /dev/null; then
            export CROSS_COMPILE="ccache ${UBOOT_GCC}"
            echo "Using ccache for compilation"
        else
            echo "WARNING: ccache not found, building without ccache"
            export CROSS_COMPILE="${UBOOT_GCC}"
        fi
    else
        export CROSS_COMPILE="${UBOOT_GCC}"
    fi
    
    # 定义 target 目录
    TARGET_BOARD="${TARGET_BOARD:-${BOARD_NAME:-${BOARD}}}"
    TARGET_DEFCONFIG="${BASE_DIR}/configs/target/${TARGET_BOARD}/uboot_defconfig"
    
    # 多级查找 defconfig（按照优先级顺序）
    CONFIG_FOUND=no
    CONFIG_SOURCE=""
    UBOOT_PWD=$(pwd)
    
    echo "Searching for U-Boot configuration..."
    echo "  Target board: ${TARGET_BOARD}"
    echo "  Target config: ${UBOOT_DEFCONFIG}"
    echo "  U-Boot source: ${UBOOT_PWD}"
    echo ""
    
    # 优先级 0: 查找 configs/target/${TARGET_BOARD}/uboot_defconfig
    if [ -f "${TARGET_DEFCONFIG}" ];then
        if [ -s "${TARGET_DEFCONFIG}" ]; then
            echo "✓ Found: configs/target/${TARGET_BOARD}/uboot_defconfig"
            cp "${TARGET_DEFCONFIG}" .config
            ${MAKE} ARCH=${UBOOT_ARCH} olddefconfig
            CONFIG_FOUND=yes
            CONFIG_SOURCE="configs/target/${TARGET_BOARD}/uboot_defconfig"
        else
            echo "Target U-Boot defconfig exists but is empty: ${TARGET_DEFCONFIG}"
            echo "Falling back to U-Boot source defconfig: configs/${UBOOT_DEFCONFIG}"
        fi
    else
        echo "Target U-Boot defconfig not found: ${TARGET_DEFCONFIG}"
        echo "Falling back to U-Boot source defconfig: configs/${UBOOT_DEFCONFIG}"
    fi

    if [ "${CONFIG_FOUND}" != "yes" ]; then
    # 优先级 1: 使用 U-Boot 源码中的 defconfig
    if [ -n "${UBOOT_DEFCONFIG}" ] && [ -f "configs/${UBOOT_DEFCONFIG}" ];then
        echo "✓ Found: configs/${UBOOT_DEFCONFIG} (U-Boot source tree)"
        ${MAKE} ARCH=${UBOOT_ARCH} ${UBOOT_DEFCONFIG}
        CONFIG_FOUND=yes
        CONFIG_SOURCE="configs/${UBOOT_DEFCONFIG} (U-Boot source)"

    # 优先级 2: 检查是否有用户自定义配置（menuconfig 保存的配置）
    elif [ -f "${WORKSPACE}/uboot_user_defconfig" ];then
        echo "✓ Found: uboot_user_defconfig (from previous menuconfig)"
        cp "${WORKSPACE}/uboot_user_defconfig" .config
        ${MAKE} ARCH=${UBOOT_ARCH} oldconfig
        CONFIG_FOUND=yes
        CONFIG_SOURCE="uboot_user_defconfig"
        
    # 优先级 4: 检查是否已有 .config
    elif [ -f ".config" ];then
        echo "✓ Using existing .config in U-Boot source directory"
        ${MAKE} ARCH=${UBOOT_ARCH} oldconfig
        CONFIG_FOUND=yes
        CONFIG_SOURCE="existing .config"
        
    else
        echo ""
        echo "=========================================="
        echo "ERROR: No U-Boot configuration found!"
        echo "=========================================="
        echo "Searched locations (in order):"
        echo "  1. ${TARGET_DEFCONFIG}"
        echo "  2. ${UBOOT_PWD}/configs/${UBOOT_DEFCONFIG}"
        if [ -f "${UBOOT_PWD}/configs/${UBOOT_DEFCONFIG}" ]; then echo "     [EXISTS]"; else echo "     [NOT FOUND]"; fi
        echo ""
        echo "  3. ${WORKSPACE}/uboot_user_defconfig"
        if [ -f "${WORKSPACE}/uboot_user_defconfig" ]; then echo "     [EXISTS]"; else echo "     [NOT FOUND]"; fi
        echo ""
        echo "  4. ${UBOOT_PWD}/.config"
        if [ -f "${UBOOT_PWD}/.config" ]; then echo "     [EXISTS]"; else echo "     [NOT FOUND]"; fi
        echo ""
        echo "Available defconfigs in U-Boot source (configs/):"
        if [ -d "${UBOOT_PWD}/configs" ]; then
            # 显示相关的配置文件
            echo "  Searching for similar configs matching '${UBOOT_DEFCONFIG}'..."
            SIMILAR=$(ls "${UBOOT_PWD}/configs/" 2>/dev/null | grep -i "$(echo ${UBOOT_DEFCONFIG} | sed 's/_defconfig$//' | sed 's/_.*//')" | head -10)
            if [ -n "${SIMILAR}" ]; then
                echo "${SIMILAR}" | sed 's/^/    - /'
            else
                echo "    (No similar configs found)"
            fi
            echo ""
            echo "  Total configs available: $(ls ${UBOOT_PWD}/configs/ | wc -l)"
            echo "  List all: ls ${UBOOT_PWD}/configs/"
        else
            echo "  [configs directory not found]"
        fi
        echo ""
        echo "Solutions:"
        echo "  1. Fill defconfig at: ${TARGET_DEFCONFIG}"
        echo "  2. Use existing U-Boot defconfig: ls ${UBOOT_PWD}/configs/"
        echo "  3. Check if UBOOT_DEFCONFIG='${UBOOT_DEFCONFIG}' is correct in board config"
        echo "=========================================="
        exit 1
    fi
    fi
    
    echo "  Config source: ${CONFIG_SOURCE}"
    echo ""
    
    # 运行 menuconfig（如果需要）
    if [ "${MENUCONFIG}" == "yes" ];then
        echo "Running U-Boot menuconfig..."
        ${MAKE} ARCH=${UBOOT_ARCH} menuconfig
        # 保存用户配置
        cp .config "${WORKSPACE}/uboot_user_defconfig"
        echo "Configuration saved to: ${WORKSPACE}/uboot_user_defconfig"
        echo "(This will be used in future builds with highest priority)"
        echo ""
    fi
    
    # 设置 BL31 路径（如果存在）
    if [ "${BUILD_ATF}" = "yes" ]; then
        BL31_BIN=$(find ${WORKSPACE}/atf/build -name "bl31.bin" 2>/dev/null | head -n 1)
        if [ -n "${BL31_BIN}" ];then
            export BL31="${BL31_BIN}"
            echo "Using ATF BL31: ${BL31}"
        else
            echo "WARNING: BUILD_ATF=yes but bl31.bin not found"
        fi
    else
        unset BL31
    fi
    
    # 编译 U-Boot
    echo "Building U-Boot..."
    echo "  Architecture: ${UBOOT_ARCH}"
    echo "  Cross Compiler: ${CROSS_COMPILE}"
    echo "  Parallel jobs: $(nproc)"
    echo ""
    
    ${MAKE} ARCH=${UBOOT_ARCH} -j$(nproc)
    
    if [ $? -ne 0 ];then
        echo "ERROR: U-Boot build failed"
        exit 1
    fi
    
    echo ""
    echo "[OK] U-Boot build successful"
    
    cd "${WORKSPACE}"
}

# 生成 boot.scr
generate_boot_scr()
{
    local output_dir=$1
    
    echo "Generating boot.scr..."
    
    # 创建 boot.cmd
    cat > "${output_dir}/boot.cmd" << 'EOF'
# U-Boot boot script
# Auto-generated by build-boot.sh

# Set bootargs
setenv bootargs "${bootargs}"

# Load kernel and device tree
load ${devtype} ${devnum}:${distro_bootpart} ${kernel_addr_r} /boot/Image
load ${devtype} ${devnum}:${distro_bootpart} ${fdt_addr_r} /boot/dtb/${fdtfile}

# Load ramdisk if available
if load ${devtype} ${devnum}:${distro_bootpart} ${ramdisk_addr_r} /boot/initrd.img; then
    booti ${kernel_addr_r} ${ramdisk_addr_r}:${filesize} ${fdt_addr_r}
else
    booti ${kernel_addr_r} - ${fdt_addr_r}
fi
EOF
    
    # 检查是否有 mkimage 工具
    if ! command -v mkimage > /dev/null; then
        echo "WARNING: mkimage not found, cannot generate boot.scr"
        echo "Please install u-boot-tools package"
        return 1
    fi
    
    # 生成 boot.scr（使用内核架构，因为 boot.scr 是给内核用的）
    mkimage -C none -A ${ARCH} -T script -d "${output_dir}/boot.cmd" "${output_dir}/boot.scr" > /dev/null 2>&1
    
    if [ $? -eq 0 ];then
        echo "[OK] boot.scr generated successfully"
        rm -f "${output_dir}/boot.cmd"
    else
        echo "WARNING: Failed to generate boot.scr"
    fi
}

# 主程序开始
echo "=========================================="
echo "Build Bootloader Tool"
echo "=========================================="
echo "Started at: $(date)"
echo ""

WORKSPACE=$(pwd)

init_params
parse_args "$@" || show_help $?

# Load config
TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${TOOL_DIR}/.." && pwd)"
CONFIG_DIR="${BASE_DIR}/configs/board"

CONFIG_FILE="${CONFIG_DIR}/${BOARD}.conf"
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "ERROR: Config file not found: ${CONFIG_FILE}"
    echo "Available boards:"
    ls -1 "${CONFIG_DIR}"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/.conf$//' | sed 's/^/  - /'
    exit 1
fi

echo "Loading board configuration: ${CONFIG_FILE}"
source "${CONFIG_FILE}"

TARGET_BOARD="${TARGET_BOARD:-${BOARD_NAME:-${BOARD}}}"

# 架构配置回退机制
if [ -z "${UBOOT_ARCH}" ]; then
    UBOOT_ARCH="${ARCH}"
    echo "Notice: UBOOT_ARCH not set, using ARCH (${ARCH})"
fi

if [ -z "${ATF_ARCH}" ]; then
    ATF_ARCH="${UBOOT_ARCH}"
    echo "Notice: ATF_ARCH not set, using UBOOT_ARCH (${UBOOT_ARCH})"
fi

# 工具链配置回退机制
if [ -z "${UBOOT_GCC}" ]; then
    UBOOT_GCC="${KERNEL_GCC}"
    echo "Notice: UBOOT_GCC not set, using KERNEL_GCC"
fi

if [ -z "${ATF_GCC}" ]; then
    ATF_GCC="${UBOOT_GCC}"
    echo "Notice: ATF_GCC not set, using UBOOT_GCC"
fi

if [ -z "${BUILD_ATF}" ]; then
    if [ "${ARCH}" = "arm64" ] || [ "${UBOOT_ARCH}" = "arm64" ]; then
        BUILD_ATF="yes"
    else
        BUILD_ATF="no"
    fi
fi

echo "Configuration loaded:"
echo "  Board: ${BOARD_NAME}"
echo "  Kernel Architecture: ${ARCH}"
echo "  U-Boot Architecture: ${UBOOT_ARCH}"
echo "  ATF Architecture: ${ATF_ARCH}"
echo "  Bootloader Type: ${BL_CONFIG}"
echo "  Kernel Compiler: ${KERNEL_GCC}"
echo "  U-Boot Compiler: ${UBOOT_GCC}"
echo "  ATF Compiler: ${ATF_GCC}"
echo "  Build ATF: ${BUILD_ATF}"
echo "  Menuconfig: ${MENUCONFIG}"
echo "  Use ccache: ${USE_CCACHE}"
echo ""

# 根据 Bootloader 类型进行构建
if is_mainline_uboot; then
    if [ "${BL_CONFIG}" = "mainline-uboot" ]; then
        echo "Building Mainline U-Boot"
    else
        echo "Building Allwinner U-Boot"
    fi
    echo "  U-Boot Config: ${UBOOT_DEFCONFIG}"
    echo "  U-Boot Patch: ${BL_PATCHDIR:-none}"
    echo ""
    
    # 应用补丁
    if [ -n "${BL_PATCHDIR}" ] && [ "${BL_PATCHDIR}" != "none" ]; then
        patch_uboot "${BL_PATCHDIR}" "${WORKSPACE}/${BL_CONFIG}" || exit 1
    fi
    deploy_uboot_dts
    
    # 编译 ATF
    if [ "${BUILD_ATF}" = "yes" ]; then
        compile_atf || exit 1
    else
        echo "Skipping ATF build (BUILD_ATF=${BUILD_ATF})"
    fi
    
    # 编译 U-Boot
    compile_uboot || exit 1
    
    # 创建输出目录
    OUTPUT="${WORKSPACE}/bootloader-${BOARD}"
    echo ""
    echo "Preparing output directory: ${OUTPUT}"
    rm -rf "${OUTPUT}"
    mkdir -p "${OUTPUT}"
    
    # 复制输出文件
    echo "Copying output files..."
    if [ -f "${WORKSPACE}/${BL_CONFIG}/u-boot-sunxi-with-spl.bin" ]; then
        cp "${WORKSPACE}/${BL_CONFIG}/u-boot-sunxi-with-spl.bin" "${OUTPUT}/"
        cp "${WORKSPACE}/${BL_CONFIG}/u-boot-sunxi-with-spl.bin" "${WORKSPACE}/bootloader-u-boot.bin"
        echo "  [OK] u-boot-sunxi-with-spl.bin"
    fi
    
    if [ -f "${WORKSPACE}/${BL_CONFIG}/u-boot.bin" ]; then
        cp "${WORKSPACE}/${BL_CONFIG}/u-boot.bin" "${OUTPUT}/"
        echo "  [OK] u-boot.bin"
    fi
    
    if [ -f "${WORKSPACE}/${BL_CONFIG}/u-boot.dtb" ]; then
        cp "${WORKSPACE}/${BL_CONFIG}/u-boot.dtb" "${OUTPUT}/"
        echo "  [OK] u-boot.dtb"
    fi
    
    # 复制 ATF bl31.bin
    if [ "${BUILD_ATF}" = "yes" ]; then
        BL31_BIN=$(find ${WORKSPACE}/atf/build -name "bl31.bin" 2>/dev/null | head -n 1)
        if [ -n "${BL31_BIN}" ]; then
            cp "${BL31_BIN}" "${OUTPUT}/"
            echo "  [OK] bl31.bin"
        else
            echo "  WARNING: BUILD_ATF=yes but bl31.bin not found, skip copy"
        fi
    fi
    
    # 生成 boot.scr
    generate_boot_scr "${OUTPUT}"
    
    # 创建标记文件
    echo "${BOARD}" > "${OUTPUT}/.done"
    
    echo ""
    echo "=========================================="
    echo "Build completed successfully!"
    echo "=========================================="
    echo "Output directory: ${OUTPUT}"
    echo "Files:"
    ls -lh "${OUTPUT}" 2>/dev/null | tail -n +2 | while read line; do
        echo "  $line"
    done
    
elif [ "${BL_CONFIG}" == "rockchip-uboot" ]; then
    echo "Building Rockchip U-Boot"
    echo "  U-Boot Config: ${UBOOT_DEFCONFIG}"
    echo "  U-Boot Patch: ${BL_PATCHDIR:-none}"
    echo ""
    
    # 检查 rkbin
    if [ ! -d "${WORKSPACE}/rkbin" ];then
        echo "ERROR: rkbin directory not found: ${WORKSPACE}/rkbin"
        echo "Please run get-sources.sh first"
        exit 1
    fi
    
    # 检查 U-Boot 源码
    if [ ! -d "${WORKSPACE}/${BL_CONFIG}" ];then
        echo "ERROR: U-Boot source directory not found: ${WORKSPACE}/${BL_CONFIG}"
        echo "Please run get-sources.sh first"
        exit 1
    fi
    
    # 应用补丁
    if [ -n "${BL_PATCHDIR}" ] && [ "${BL_PATCHDIR}" != "none" ]; then
        patch_uboot "${BL_PATCHDIR}" "${WORKSPACE}/${BL_CONFIG}" || exit 1
    fi
    deploy_uboot_dts
    
    # 进入 U-Boot 目录
    cd "${WORKSPACE}/${BL_CONFIG}"
    
    # 重要：先复制 RKBIN 文件，再编译 U-Boot
    # U-Boot 编译时需要 bl31.elf 和 tee.bin 来生成 u-boot.itb
    echo ""
    echo "Preparing Rockchip binary files..."
    
    if [ -n "${BL31_PATH}" ] && [ -f "${WORKSPACE}/rkbin/${BL31_PATH}" ]; then
        cp "${WORKSPACE}/rkbin/${BL31_PATH}" bl31.elf
        echo "  [OK] Copied bl31.elf"
    else
        echo "  ERROR: BL31 file not found: ${BL31_PATH}"
        echo "  Required for U-Boot compilation"
        exit 1
    fi
    
    if [ -n "${TEE_PATH}" ] && [ -f "${WORKSPACE}/rkbin/${TEE_PATH}" ]; then
        cp "${WORKSPACE}/rkbin/${TEE_PATH}" tee.bin
        echo "  [OK] Copied tee.bin"
    else
        echo "  WARNING: TEE file not found: ${TEE_PATH}"
        echo "  (Some boards may not require TEE)"
    fi
    
    # 编译 U-Boot（Rockchip 专用流程）
    echo ""
    echo "=========================================="
    echo "Compiling Rockchip U-Boot"
    echo "=========================================="
    
    # 设置交叉编译器
    if [ "${USE_CCACHE}" == "yes" ];then
        if command -v ccache > /dev/null; then
            export CROSS_COMPILE="ccache ${UBOOT_GCC}"
            echo "Using ccache for compilation"
        else
            export CROSS_COMPILE="${UBOOT_GCC}"
        fi
    else
        export CROSS_COMPILE="${UBOOT_GCC}"
    fi
    
    # 定义 target 目录
    TARGET_BOARD="${TARGET_BOARD:-${BOARD_NAME:-${BOARD}}}"
    TARGET_DEFCONFIG="${BASE_DIR}/configs/target/${TARGET_BOARD}/uboot_defconfig"
    
    echo "Searching for U-Boot configuration..."
    echo "  Target board: ${TARGET_BOARD}"
    echo "  Target config: ${UBOOT_DEFCONFIG}"
    echo ""
    
    # 多级查找 defconfig（与 compile_uboot 相同的逻辑）
    CONFIG_FOUND=no
    UBOOT_PWD=$(pwd)
    
    if [ -f "${TARGET_DEFCONFIG}" ];then
        if [ -s "${TARGET_DEFCONFIG}" ]; then
            echo "✓ Found: configs/target/${TARGET_BOARD}/uboot_defconfig"
            cp "${TARGET_DEFCONFIG}" .config
            make ARCH=${UBOOT_ARCH} olddefconfig
            CONFIG_FOUND=yes
        else
            echo "Target U-Boot defconfig exists but is empty: ${TARGET_DEFCONFIG}"
            echo "Falling back to U-Boot source defconfig: configs/${UBOOT_DEFCONFIG}"
        fi
    else
        echo "Target U-Boot defconfig not found: ${TARGET_DEFCONFIG}"
        echo "Falling back to U-Boot source defconfig: configs/${UBOOT_DEFCONFIG}"
    fi

    if [ "${CONFIG_FOUND}" != "yes" ]; then
    if [ -n "${UBOOT_DEFCONFIG}" ] && [ -f "configs/${UBOOT_DEFCONFIG}" ];then
        echo "✓ Found: configs/${UBOOT_DEFCONFIG} (U-Boot source tree)"
        make CROSS_COMPILE=${UBOOT_GCC} ARCH=${UBOOT_ARCH} ${UBOOT_DEFCONFIG}
        CONFIG_FOUND=yes
    elif [ -f "${WORKSPACE}/uboot_user_defconfig" ];then
        echo "✓ Found: uboot_user_defconfig (from previous menuconfig)"
        cp "${WORKSPACE}/uboot_user_defconfig" .config
        make ARCH=${UBOOT_ARCH} oldconfig
        CONFIG_FOUND=yes
    elif [ -f ".config" ];then
        echo "✓ Using existing .config"
        make ARCH=${UBOOT_ARCH} oldconfig
        CONFIG_FOUND=yes
    else
        echo ""
        echo "=========================================="
        echo "ERROR: No U-Boot configuration found!"
        echo "=========================================="
        echo "Searched locations:"
        echo "  1. ${TARGET_DEFCONFIG}"
        if [ -s "${TARGET_DEFCONFIG}" ]; then echo "     [EXISTS]"; else echo "     [NOT FOUND OR EMPTY]"; fi
        echo ""
        echo "  2. ${UBOOT_PWD}/configs/${UBOOT_DEFCONFIG}"
        if [ -f "${UBOOT_PWD}/configs/${UBOOT_DEFCONFIG}" ]; then echo "     [EXISTS]"; else echo "     [NOT FOUND]"; fi
        echo ""
        echo "  3. ${WORKSPACE}/uboot_user_defconfig"
        if [ -f "${WORKSPACE}/uboot_user_defconfig" ]; then echo "     [EXISTS]"; else echo "     [NOT FOUND]"; fi
        echo ""
        echo "  4. ${UBOOT_PWD}/.config"
        if [ -f "${UBOOT_PWD}/.config" ]; then echo "     [EXISTS]"; else echo "     [NOT FOUND]"; fi
        echo ""
        echo "Available defconfigs in U-Boot source (configs/):"
        if [ -d "${UBOOT_PWD}/configs" ]; then
            echo "  Searching for similar configs matching '${UBOOT_DEFCONFIG}'..."
            SIMILAR=$(ls "${UBOOT_PWD}/configs/" 2>/dev/null | grep -i "$(echo ${UBOOT_DEFCONFIG} | sed 's/_defconfig$//' | sed 's/_.*//')" | head -10)
            if [ -n "${SIMILAR}" ]; then
                echo "${SIMILAR}" | sed 's/^/    - /'
            else
                echo "    (No similar configs found)"
            fi
            echo ""
            echo "  Total configs: $(ls ${UBOOT_PWD}/configs/ | wc -l)"
            echo "  List all: ls ${UBOOT_PWD}/configs/"
        else
            echo "  [configs directory not found]"
        fi
        echo ""
        echo "Solutions:"
        echo "  1. Fill defconfig at: ${TARGET_DEFCONFIG}"
        echo "  2. Use existing defconfig from: ls ${UBOOT_PWD}/configs/"
        echo "  3. Check UBOOT_DEFCONFIG='${UBOOT_DEFCONFIG}' in board config"
        echo "=========================================="
        exit 1
    fi
    fi
    
    # 运行 menuconfig（如果需要）
    if [ "${MENUCONFIG}" == "yes" ];then
        echo "Running U-Boot menuconfig..."
        make ARCH=${UBOOT_ARCH} menuconfig
        cp .config "${WORKSPACE}/uboot_user_defconfig"
        echo "Configuration saved to: ${WORKSPACE}/uboot_user_defconfig"
    fi
    
    # 编译 U-Boot（Rockchip 专用目标）
    echo ""
    echo "Building U-Boot for Rockchip..."
    echo "  Architecture: ${UBOOT_ARCH}"
    echo "  Cross Compiler: ${CROSS_COMPILE}"
    echo "  Parallel jobs: $(nproc)"
    echo ""
    
    # Rockchip 需要编译特定的目标
    make ARCH=${UBOOT_ARCH} CROSS_COMPILE=${UBOOT_GCC} \
         spl/u-boot-spl.bin u-boot.dtb u-boot.itb \
         -j$(nproc)
    
    if [ $? -ne 0 ];then
        echo "ERROR: U-Boot build failed"
        exit 1
    fi
    
    echo ""
    echo "[OK] U-Boot build successful"
    
    # 生成 idbloader.img
    if [ -n "${DDRBIN_PATH}" ] && [ -f "${WORKSPACE}/rkbin/${DDRBIN_PATH}" ]; then
        echo ""
        echo "Generating idbloader.img..."
        
        # 从 UBOOT_DEFCONFIG 自动推断 SoC 类型
        SOC_TYPE="rk3588"  # 默认值
        if [[ "${UBOOT_DEFCONFIG}" == *"rk3588"* ]]; then
            SOC_TYPE="rk3588"
        elif [[ "${UBOOT_DEFCONFIG}" == *"rk3576"* ]]; then
            SOC_TYPE="rk3576"
        elif [[ "${UBOOT_DEFCONFIG}" == *"rk3568"* ]]; then
            SOC_TYPE="rk3568"
        elif [[ "${UBOOT_DEFCONFIG}" == *"rk3566"* ]]; then
            SOC_TYPE="rk3566"
        elif [[ "${UBOOT_DEFCONFIG}" == *"rk3399"* ]]; then
            SOC_TYPE="rk3399"
        fi
        echo "  Auto-detected SOC_TYPE: ${SOC_TYPE}"
        
        if [ -f "spl/u-boot-spl.bin" ]; then
            ./tools/mkimage -n ${SOC_TYPE} -T rksd \
                -d "${WORKSPACE}/rkbin/${DDRBIN_PATH}:spl/u-boot-spl.bin" \
                idbloader.img
            
            if [ $? -eq 0 ]; then
                echo "  [OK] idbloader.img generated successfully"
            else
                echo "  ERROR: Failed to generate idbloader.img"
                exit 1
            fi
        else
            echo "  ERROR: spl/u-boot-spl.bin not found"
            exit 1
        fi
    else
        echo "  ERROR: DDR binary not found: ${DDRBIN_PATH}"
        echo "  Required for idbloader.img generation"
        exit 1
    fi
    
    cd "${WORKSPACE}"
    
    # 创建输出目录
    OUTPUT="${WORKSPACE}/bootloader-${BOARD}"
    echo ""
    echo "Preparing output directory: ${OUTPUT}"
    rm -rf "${OUTPUT}"
    mkdir -p "${OUTPUT}"
    
    # 复制输出文件
    echo "Copying output files..."
    if [ -f "${WORKSPACE}/${BL_CONFIG}/idbloader.img" ]; then
        cp "${WORKSPACE}/${BL_CONFIG}/idbloader.img" "${OUTPUT}/"
        cp "${WORKSPACE}/${BL_CONFIG}/idbloader.img" "${WORKSPACE}/"
        echo "  [OK] idbloader.img"
    fi
    
    if [ -f "${WORKSPACE}/${BL_CONFIG}/u-boot.itb" ]; then
        cp "${WORKSPACE}/${BL_CONFIG}/u-boot.itb" "${OUTPUT}/"
        cp "${WORKSPACE}/${BL_CONFIG}/u-boot.itb" "${WORKSPACE}/"
        echo "  [OK] u-boot.itb"
    fi
    
    if [ -f "${WORKSPACE}/${BL_CONFIG}/u-boot.bin" ]; then
        cp "${WORKSPACE}/${BL_CONFIG}/u-boot.bin" "${OUTPUT}/"
        echo "  [OK] u-boot.bin"
    fi
    
    if [ -f "${WORKSPACE}/${BL_CONFIG}/u-boot.dtb" ]; then
        cp "${WORKSPACE}/${BL_CONFIG}/u-boot.dtb" "${OUTPUT}/"
        echo "  [OK] u-boot.dtb"
    fi
    
    # 生成 boot.scr
    generate_boot_scr "${OUTPUT}"
    
    # 创建标记文件
    echo "${BOARD}" > "${OUTPUT}/.done"
    
    echo ""
    echo "=========================================="
    echo "Build completed successfully!"
    echo "=========================================="
    echo "Output directory: ${OUTPUT}"
    echo "Files:"
    ls -lh "${OUTPUT}" 2>/dev/null | tail -n +2 | while read line; do
        echo "  $line"
    done
    
    echo ""
    echo "Flash commands:"
    echo "  sudo dd if=${OUTPUT}/idbloader.img of=/dev/sdX seek=64 conv=fsync"
    echo "  sudo dd if=${OUTPUT}/u-boot.itb of=/dev/sdX seek=16384 conv=fsync"
    
else
    echo "ERROR: Unknown bootloader type: ${BL_CONFIG}"
    echo "Supported types: mainline-uboot, sunxi-uboot, rockchip-uboot"
    exit 1
fi

echo ""
echo "Completed at: $(date)"
exit 0
