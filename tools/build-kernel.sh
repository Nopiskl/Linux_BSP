#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# Build Kernel Tool
# Build Linux kernel and generate Debian packages

__usage="
Usage: build-kernel [OPTIONS]
Build Linux kernel and generate .deb packages.

Options: 
  -b, --board BOARD              Target board name.
  -k, --menuconfig               Run menuconfig (yes/no).
  -g, --target                   Kernel target (not used, for compatibility).
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
            echo "ERROR: Unknown parameter: $1"
            return 2
        fi
    done
}

# 应用内核补丁
patch_kernel()
{
    local patchdir=$1
    local targetdir=$2
    
    if [ ! -d "${targetdir}" ];then
        echo "ERROR: Kernel source directory not found: ${targetdir}"
        return 1
    fi
    
    echo "Applying kernel patches from: ${patchdir}"
    
    # 应用补丁文件
    if [ -d "${TOOL_DIR}/../patches/kernel/${patchdir}/patches" ];then
        for pth in $(ls "${TOOL_DIR}/../patches/kernel/${patchdir}/patches" 2>/dev/null)
        do
            echo "  Applying patch: ${pth}"
            cp "${TOOL_DIR}/../patches/kernel/${patchdir}/patches/${pth}" "${targetdir}/"
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
        echo "  No patch directory found"
    fi
    
    # 复制额外文件
    if [ -d "${TOOL_DIR}/../patches/kernel/${patchdir}/files" ];then
        echo "  Copying additional files..."
        cp -rv "${TOOL_DIR}/../patches/kernel/${patchdir}/files/"* "${targetdir}/"
        sync
    fi
}

deploy_kernel_dts()
{
    local kernel_dts="${KERNEL_DTS}"

    if [ -z "${kernel_dts}" ]; then
        return 0
    fi

    local target_board="${TARGET_BOARD:-${BOARD_NAME:-${BOARD}}}"
    local source_file="${BASE_DIR}/configs/target/${target_board}/kernel.dts"
    local target_file="${WORKSPACE}/linux/arch/${ARCH}/boot/dts/${kernel_dts}.dts"
    local target_dir

    if [ -f "${source_file}" ]; then
        if [ -s "${source_file}" ]; then
            target_dir="$(dirname "${target_file}")"
            mkdir -p "${target_dir}"
            cp "${source_file}" "${target_file}"
            echo "Deployed kernel DTS: ${source_file} -> ${target_file}"
            return 0
        fi
        echo "Target kernel DTS exists but is empty: ${source_file}"
        echo "Falling back to kernel source DTS: arch/${ARCH}/boot/dts/${kernel_dts}.dts"
    else
        echo "Target kernel DTS not found: ${source_file}"
        echo "Falling back to kernel source DTS: arch/${ARCH}/boot/dts/${kernel_dts}.dts"
    fi

    if [ ! -s "${source_file}" ]; then
        if [ -f "${target_file}" ]; then
            echo "Kernel DTS found in source tree: arch/${ARCH}/boot/dts/${kernel_dts}.dts"
        else
            echo "WARNING: Kernel DTS not found: ${kernel_dts}.dts"
            echo "         Checked configs/target/${target_board}/kernel.dts and kernel source tree"
        fi
        return 0
    fi
}

# 编译内核
compile_linux()
{
    echo "=========================================="
    echo "Compiling Linux Kernel"
    echo "=========================================="
    
    if [ ! -d "${WORKSPACE}/linux" ];then
        echo "ERROR: Linux source directory not found: ${WORKSPACE}/linux"
        exit 1
    fi
    
    cd "${WORKSPACE}/linux"
    
    # 定义 target 目录
    TARGET_BOARD="${TARGET_BOARD:-${BOARD_NAME:-${BOARD}}}"
    TARGET_DEFCONFIG="${BASE_DIR}/configs/target/${TARGET_BOARD}/kernel_defconfig"
    
    # 多级查找 defconfig（按照优先级顺序）
    CONFIG_FOUND=no
    CONFIG_SOURCE=""
    
    echo "Searching for kernel configuration..."
    echo "  Target board: ${TARGET_BOARD}"
    echo "  Target config: ${KERNEL_DEFCONFIG}"
    echo ""
    
    # 优先级 0: 查找 configs/target/${TARGET_BOARD}/kernel_defconfig
    if [ -f "${TARGET_DEFCONFIG}" ];then
        if [ -s "${TARGET_DEFCONFIG}" ]; then
            echo "Found: configs/target/${TARGET_BOARD}/kernel_defconfig"
            cp "${TARGET_DEFCONFIG}" .config
            ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} olddefconfig
            CONFIG_FOUND=yes
            CONFIG_SOURCE="configs/target/${TARGET_BOARD}/kernel_defconfig"
        else
            echo "Target kernel defconfig exists but is empty: ${TARGET_DEFCONFIG}"
            echo "Falling back to kernel source defconfig: arch/${ARCH}/configs/${KERNEL_DEFCONFIG}"
        fi
    else
        echo "Target kernel defconfig not found: ${TARGET_DEFCONFIG}"
        echo "Falling back to kernel source defconfig: arch/${ARCH}/configs/${KERNEL_DEFCONFIG}"
    fi

    if [ "${CONFIG_FOUND}" != "yes" ]; then
    # 优先级 1: 使用内核源码中的 defconfig
    if [ -n "${KERNEL_DEFCONFIG}" ] && [ -f "arch/${ARCH}/configs/${KERNEL_DEFCONFIG}" ];then
        echo "No non-empty target kernel_defconfig, use arch/${ARCH}/configs/${KERNEL_DEFCONFIG} (kernel source)"
        ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} ${KERNEL_DEFCONFIG}
        CONFIG_FOUND=yes
        CONFIG_SOURCE="arch/${ARCH}/configs/${KERNEL_DEFCONFIG}"

    # 优先级 2: 检查是否有用户自定义配置（menuconfig 保存的配置）
    elif [ -f "${WORKSPACE}/user_defconfig" ];then
        echo "Found: user_defconfig (from previous menuconfig)"
        cp "${WORKSPACE}/user_defconfig" .config
        ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} olddefconfig
        CONFIG_FOUND=yes
        CONFIG_SOURCE="user_defconfig"
        
    # 优先级 3: 检查是否已有 .config
    elif [ -f ".config" ];then
        echo "cannot find board defconfig, using existing .config in kernel source directory"
        ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} olddefconfig
        CONFIG_FOUND=yes
        CONFIG_SOURCE="existing .config"
        
    else
        echo ""
        echo "=========================================="
        echo "ERROR: No kernel configuration found!"
        echo "=========================================="
        echo "Searched locations (in order):"
        echo "  1. ${TARGET_DEFCONFIG}"
        echo "  2. arch/${ARCH}/configs/${KERNEL_DEFCONFIG}"
        echo "  3. ${WORKSPACE}/user_defconfig"
        echo "  4. .config (in kernel source)"
        echo ""
        echo "Please create a configuration file in one of these locations."
        echo "=========================================="
        exit 1
    fi
    fi
    
    echo "  Config source: ${CONFIG_SOURCE}"
    echo ""
    
    # 运行 menuconfig（如果需要）
    if [ "${MENUCONFIG}" == "yes" ];then
        echo "Running menuconfig..."
        ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} menuconfig
        # 保存用户配置
        cp .config "${WORKSPACE}/user_defconfig"
        echo "Configuration saved to: ${WORKSPACE}/user_defconfig"
        echo "(This will be used in future builds with highest priority)"
        echo ""
    fi
    
    # 编译内核
    echo "=========================================="
    echo "Building Kernel"
    echo "=========================================="
    echo "  Architecture: ${ARCH}"
    echo "  Cross-compiler: ${KERNEL_GCC}"
    echo "  Jobs: $(nproc)"
    echo "  Ccache: ${USE_CCACHE}"
    echo ""
    
    ${MAKE} ARCH=${ARCH} CROSS_COMPILE=${KERNEL_GCC} -j$(nproc) || {
        echo ""
        echo "ERROR: Kernel compilation failed"
        echo "Check the error messages above for details."
        exit 1
    }
    
    echo ""
    echo "Kernel compilation completed successfully"
    echo ""
    
    # 准备 deb-data 目录
    if [ -d "${WORKSPACE}/deb-data" ];then
        rm -rf "${WORKSPACE}/deb-data"
    fi
    mkdir -p "${WORKSPACE}/deb-data"
}

# 安装设备树
install_dtb(){
    echo "=========================================="
    echo "Installing Device Tree Blobs"
    echo "=========================================="
    
    cd "${WORKSPACE}/linux"
    mkdir -p "${WORKSPACE}/deb-data/dtb/boot"
    
    ${MAKE} ARCH=${ARCH} \
        CROSS_COMPILE=${KERNEL_GCC} \
        dtbs_install \
        INSTALL_PATH="${WORKSPACE}/deb-data/dtb/boot" || {
        echo "WARNING: DTB installation failed (may not be available for this architecture)"
        return 0
    }
    
    # 重命名 dtbs 目录
    if [ -d "${WORKSPACE}/deb-data/dtb/boot/dtbs" ]; then
        KERNEL_VER=$(ls "${WORKSPACE}/deb-data/dtb/boot/dtbs/" 2>/dev/null | head -1)
        if [ -n "${KERNEL_VER}" ]; then
            mv "${WORKSPACE}/deb-data/dtb/boot/dtbs/${KERNEL_VER}" \
               "${WORKSPACE}/deb-data/dtb/boot/dtb-${KERNEL_VER}"
            rm -rf "${WORKSPACE}/deb-data/dtb/boot/dtbs"
            echo "DTBs installed to: dtb-${KERNEL_VER}"
        fi
    fi
}

# 安装内核镜像和模块
install_image_modules(){
    echo "=========================================="
    echo "Installing Kernel Image and Modules"
    echo "=========================================="
    
    cd "${WORKSPACE}/linux"
    mkdir -p "${WORKSPACE}/deb-data/image/boot"
    mkdir -p "${WORKSPACE}/deb-data/image/etc/kernel/postinst.d"
    mkdir -p "${WORKSPACE}/deb-data/image/etc/kernel/postrm.d"
    mkdir -p "${WORKSPACE}/deb-data/image/etc/kernel/preinst.d"
    mkdir -p "${WORKSPACE}/deb-data/image/etc/kernel/prerm.d"
    
    # 安装模块
    echo "Installing modules..."
    ${MAKE} ARCH=${ARCH} \
        CROSS_COMPILE=${KERNEL_GCC} \
        modules_install \
        INSTALL_MOD_PATH="${WORKSPACE}/deb-data/image" || {
        echo "ERROR: Module installation failed"
        exit 1
    }
    
    # 安装内核镜像
    echo "Installing kernel image..."
    ${MAKE} ARCH=${ARCH} \
        CROSS_COMPILE=${KERNEL_GCC} \
        install \
        INSTALL_PATH="${WORKSPACE}/deb-data/image/boot" || {
        echo "ERROR: Kernel image installation failed"
        exit 1
    }
    
    echo "Kernel image and modules installed successfully"
}

# 安装内核头文件
install_headers(){
    echo "=========================================="
    echo "Installing Kernel Headers"
    echo "=========================================="
    
    cd "${WORKSPACE}/linux"
    KERNEL_VER=$(ls "${WORKSPACE}/deb-data/image/lib/modules/" | head -1)
    
    if [ -z "${KERNEL_VER}" ]; then
        echo "ERROR: Cannot determine kernel version"
        exit 1
    fi
    
    echo "Kernel version: ${KERNEL_VER}"
    
    hdr_path="${WORKSPACE}/deb-data/headers/usr/src/linux-headers-${KERNEL_VER}"
    mkdir -p "${hdr_path}"
    mkdir -p "${WORKSPACE}/deb-data/headers/lib/modules/${KERNEL_VER}"
    
    echo "Collecting kernel headers (this may take a while)..."
    
    # 生成文件列表
    temp_file_list=$(mktemp)
    
    (
    find . -name Makefile\* -o -name Kconfig\* -o -name \*.pl
    find arch/*/include include scripts -type f -o -type l 2>/dev/null
    find security/*/include -type f 2>/dev/null
    
    if [ -d "arch/${ARCH}" ]; then
        find "arch/${ARCH}" -name module.lds -o -name Kbuild.platforms -o -name Platform 2>/dev/null
        find $(find "arch/${ARCH}" -name include -o -name scripts -type d 2>/dev/null) -type f 2>/dev/null
    fi
    
    find Module.symvers include scripts -type f 2>/dev/null
    find tools -type f 2>/dev/null
    ) > "${temp_file_list}"
    
    # 复制头文件（优化版本，参考 AvaotaOS）
    echo "Copying header files..."
    
    set -e
    for item in $(cat "${temp_file_list}")
    do
        dir_name=$(dirname "${item}")
        if [ "${dir_name:0:2}" == "./" ];then
            target_dir="${hdr_path}/${dir_name:2}"
        else
            target_dir="${hdr_path}/${dir_name}"
        fi
        if [ ! -d "${target_dir}" ];then
            mkdir -p "${target_dir}"
        fi
        cp -r "${item}" "${target_dir}/" 2>/dev/null || true
    done
    set +e
    
    rm "${temp_file_list}"
    
    # 复制 .config 和其他必要文件
    cp .config "${hdr_path}/"
    cp Module.symvers "${hdr_path}/" 2>/dev/null || true
    
    echo "Kernel headers installed successfully"
}

# 安装 libc 开发头文件
install_libc_dev(){
    echo "=========================================="
    echo "Installing libc Development Headers"
    echo "=========================================="
    
    cd "${WORKSPACE}/linux"
    mkdir -p "${WORKSPACE}/deb-data/libc-dev/usr"
    
    ${MAKE} ARCH=${ARCH} \
        CROSS_COMPILE=${KERNEL_GCC} \
        headers_install \
        INSTALL_HDR_PATH="${WORKSPACE}/deb-data/libc-dev/usr" || {
        echo "ERROR: libc-dev installation failed"
        exit 1
    }
    
    echo "libc-dev headers installed successfully"
}

# 生成 Debian 包控制文件
gen_debian_files(){
    echo "=========================================="
    echo "Generating Debian Package Control Files"
    echo "=========================================="
    
    KERNEL_VER=$(ls "${WORKSPACE}/deb-data/image/lib/modules/" | head -1)
    DEB_DATA_PATH="${WORKSPACE}/deb-data"
    BSP_VERSION="1.0.0"
    
    # DTB 包
    echo "Generating DTB package files..."
    DTB_PATH="${DEB_DATA_PATH}/dtb"
    mkdir -p "${DTB_PATH}/DEBIAN"
    gen_dtb_control "${DTB_PATH}/DEBIAN/control" \
        "${BSP_VERSION}" \
        "${PKG_NAME}" \
        "${ARCH}" \
        "${KERNEL_VER}" \
        "$(du -sk ${DTB_PATH} | cut -f1)"
    gen_dtb_postinst "${DTB_PATH}/DEBIAN/postinst" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_dtb_preinst "${DTB_PATH}/DEBIAN/preinst" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_changelog "${DTB_PATH}/DEBIAN/changelog" \
        "dtb" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_md5 "${DTB_PATH}/DEBIAN/md5sums" \
        "${DTB_PATH}"
    
    # Image 包
    echo "Generating Image package files..."
    IMAGE_PATH="${DEB_DATA_PATH}/image"
    mkdir -p "${IMAGE_PATH}/DEBIAN"
    gen_image_control "${IMAGE_PATH}/DEBIAN/control" \
        "${BSP_VERSION}" \
        "${PKG_NAME}" \
        "${ARCH}" \
        "${KERNEL_VER}" \
        "$(du -sk ${IMAGE_PATH} | cut -f1)"
    gen_image_postinst "${IMAGE_PATH}/DEBIAN/postinst" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_image_postrm "${IMAGE_PATH}/DEBIAN/postrm" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_image_preinst "${IMAGE_PATH}/DEBIAN/preinst" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_image_prerm "${IMAGE_PATH}/DEBIAN/prerm" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_changelog "${IMAGE_PATH}/DEBIAN/changelog" \
        "image" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_md5 "${IMAGE_PATH}/DEBIAN/md5sums" \
        "${IMAGE_PATH}"
    
    # Headers 包
    echo "Generating Headers package files..."
    HEADERS_PATH="${DEB_DATA_PATH}/headers"
    mkdir -p "${HEADERS_PATH}/DEBIAN"
    gen_headers_control "${HEADERS_PATH}/DEBIAN/control" \
        "${BSP_VERSION}" \
        "${PKG_NAME}" \
        "${ARCH}" \
        "${KERNEL_VER}" \
        "$(du -sk ${HEADERS_PATH} | cut -f1)"
    gen_headers_postinst "${HEADERS_PATH}/DEBIAN/postinst" \
        "${PKG_NAME}" \
        "${ARCH}" \
        "${KERNEL_VER}"
    gen_headers_preinst "${HEADERS_PATH}/DEBIAN/preinst" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_headers_prerm "${HEADERS_PATH}/DEBIAN/prerm" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_changelog "${HEADERS_PATH}/DEBIAN/changelog" \
        "headers" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_md5 "${HEADERS_PATH}/DEBIAN/md5sums" \
        "${HEADERS_PATH}"
    
    # libc-dev 包
    echo "Generating libc-dev package files..."
    LIBC_DEV_PATH="${DEB_DATA_PATH}/libc-dev"
    mkdir -p "${LIBC_DEV_PATH}/DEBIAN"
    gen_libc_dev_control "${LIBC_DEV_PATH}/DEBIAN/control" \
        "${BSP_VERSION}" \
        "${PKG_NAME}" \
        "${ARCH}" \
        "${KERNEL_VER}" \
        "$(du -sk ${LIBC_DEV_PATH} | cut -f1)"
    gen_changelog "${LIBC_DEV_PATH}/DEBIAN/changelog" \
        "libc-dev" \
        "${PKG_NAME}" \
        "${KERNEL_VER}"
    gen_md5 "${LIBC_DEV_PATH}/DEBIAN/md5sums" \
        "${LIBC_DEV_PATH}"
}

# 生成包文档
gen_package_docs(){
    echo "=========================================="
    echo "Generating Package Documentation"
    echo "=========================================="
    
    DEB_DATA_PATH="${WORKSPACE}/deb-data"
    
    # 为每个包创建文档目录并添加 copyright
    for pkg_type in dtb image headers libc-dev; do
        PKG_DOC_PATH="${DEB_DATA_PATH}/${pkg_type}/usr/share/doc/linux-${pkg_type}-${PKG_NAME}"
        mkdir -p "${PKG_DOC_PATH}"
        gen_copyright "${PKG_DOC_PATH}/copyright"
        
        # 压缩 changelog
        if [ -f "${DEB_DATA_PATH}/${pkg_type}/DEBIAN/changelog" ]; then
            cp "${DEB_DATA_PATH}/${pkg_type}/DEBIAN/changelog" "${PKG_DOC_PATH}/"
            gzip -f "${PKG_DOC_PATH}/changelog"
        fi
    done
    
    echo "Package documentation generated"
}

# 打包 Debian 包
pack_kernel_packages(){
    echo "=========================================="
    echo "Packing Kernel Debian Packages"
    echo "=========================================="
    
    DEB_DATA_PATH="${WORKSPACE}/deb-data"
    
    # 创建输出目录
    mkdir -p "${PACKAGES_OUTPUT_PATH}"
    
    # 打包各个包
    echo "Building DTB package..."
    dpkg-deb -b "${DEB_DATA_PATH}/dtb" "${PACKAGES_OUTPUT_PATH}" || {
        echo "ERROR: Failed to build DTB package"
        exit 1
    }
    
    echo "Building Image package..."
    dpkg-deb -b "${DEB_DATA_PATH}/image" "${PACKAGES_OUTPUT_PATH}" || {
        echo "ERROR: Failed to build Image package"
        exit 1
    }
    
    echo "Building Headers package..."
    dpkg-deb -b "${DEB_DATA_PATH}/headers" "${PACKAGES_OUTPUT_PATH}" || {
        echo "ERROR: Failed to build Headers package"
        exit 1
    }
    
    echo "Building libc-dev package..."
    dpkg-deb -b "${DEB_DATA_PATH}/libc-dev" "${PACKAGES_OUTPUT_PATH}" || {
        echo "ERROR: Failed to build libc-dev package"
        exit 1
    }
    
    echo "All packages built successfully"
}

# ==================== Main Script ====================

echo "=========================================="
echo "BSP Kernel Build Tool"
echo "=========================================="
echo "Started at: $(date)"
echo ""

WORKSPACE=$(pwd)

init_params
parse_args "$@" || show_help $?

# 加载配置文件
TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${TOOL_DIR}/.." && pwd)"
CONFIG_DIR="${BASE_DIR}/configs/board"

CONFIG_FILE="${CONFIG_DIR}/${BOARD}.conf"
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "ERROR: Config file not found: ${CONFIG_FILE}"
    exit 1
fi

echo "Loading configuration: ${BOARD}"
source "${CONFIG_FILE}"

TARGET_BOARD="${TARGET_BOARD:-${BOARD_NAME:-${BOARD}}}"

echo "Configuration:"
echo "  Board: ${BOARD_NAME}"
echo "  Architecture: ${ARCH}"
echo "  Cross-compiler: ${KERNEL_GCC}"
echo "  Kernel defconfig: ${KERNEL_DEFCONFIG}"
echo "  Target board: ${TARGET_BOARD}"
echo ""

# 生成包名
kconfig_name=${KERNEL_DEFCONFIG%_defconfig}
PKG_NAME=${kconfig_name//_/-}
PACKAGES_OUTPUT_PATH="${WORKSPACE}/${BOARD}-kernel-pkgs"

# 设置 MAKE 命令
MAKE="make"
if [ "${USE_CCACHE}" == "yes" ];then
    # 更严格的 ccache 检查：确保命令真正可执行
    if command -v ccache &> /dev/null && ccache --version &> /dev/null; then
        echo "✓ Using ccache for compilation"
        MAKE="ccache ${MAKE}"
    else
        echo ""
        echo "=========================================="
        echo "⚠ WARNING: ccache not available"
        echo "=========================================="
        echo "ccache not found or not executable."
        echo "Compilation will proceed WITHOUT ccache (slower builds)."
        echo ""
        echo "To install ccache (recommended):"
        echo "  sudo apt-get update && sudo apt-get install -y ccache"
        echo ""
        echo "To disable this warning, use: -e no"
        echo "=========================================="
        echo ""
        USE_CCACHE=no
    fi
fi

# 加载 Debian 包生成函数
source "${TOOL_DIR}/lib/kernel-deb.sh"

# 执行构建流程
set -e  # 遇到错误立即退出

# 1. 应用补丁（如果有）
if [ "${LINUX_PATHDIR}" != "none" ];then
    patch_kernel "${LINUX_PATHDIR}" "${WORKSPACE}/linux"
fi

# 2. 部署板级 DTS（如果 configs/target 中提供）
deploy_kernel_dts

# 3. 编译内核
compile_linux

# 4. 安装各个组件
install_dtb
install_image_modules
install_headers
install_libc_dev

# 5. 生成 Debian 包控制文件
gen_debian_files
gen_package_docs

# 6. 打包成 .deb
pack_kernel_packages

# 7. 创建完成标记
echo "${KERNEL_DEFCONFIG}" > "${PACKAGES_OUTPUT_PATH}/.done"

echo ""
echo "=========================================="
echo "Kernel Build Completed Successfully!"
echo "=========================================="
echo "Output directory: ${PACKAGES_OUTPUT_PATH}"
echo "Packages:"
ls -lh "${PACKAGES_OUTPUT_PATH}"/*.deb 2>/dev/null || echo "  (No .deb files found)"
echo ""
echo "Completed at: $(date)"
