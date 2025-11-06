#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# Build RootFS Tool
# Build Ubuntu/Debian root filesystem

__usage="
Usage: build-rootfs [OPTIONS]
Build Ubuntu/Debian root filesystem.
Must run as root user.

Options: 
  -m, --mirror MIRROR_URL          Mirror URL (default: auto-detect).
  -r, --rootfs ROOTFS_DIR          Rootfs directory name (default: rootfs).
  -v, --version OS_VERSION         OS version: jammy, bookworm, etc.
  -b, --board BOARD                Target board name.
  -t, --type ROOTFS_TYPE           Rootfs type: cli, xfce, gnome, kde, lxqt.
  -h, --help                       Show help.

Supported OS Versions:
  Ubuntu: jammy (22.04), noble (24.04)
  Debian: bookworm (12), trixie (13)

Examples:
  sudo ./build-rootfs.sh -b example -v jammy -t cli
  sudo ./build-rootfs.sh -b example -v bookworm -t xfce -m https://mirrors.ustc.edu.cn/ubuntu-ports
"

show_help()
{
    echo "$__usage"
    exit $1
}

init_params() {
    BOARD=example
    ROOTFS=rootfs
    VERSION=jammy
    TYPE=cli
    MIRROR=""
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
        elif [ "x$1" == "x-m" -o "x$1" == "x--mirror" ]; then
            MIRROR=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-r" -o "x$1" == "x--rootfs" ]; then
            ROOTFS=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-v" -o "x$1" == "x--version" ]; then
            VERSION=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-b" -o "x$1" == "x--board" ]; then
            BOARD=`echo $2`
            shift
            shift
        elif [ "x$1" == "x-t" -o "x$1" == "x--type" ]; then
            TYPE=`echo $2`
            shift
            shift
        else
            echo "ERROR: Unknown parameter: $1"
            return 2
        fi
    done
}

# 卸载所有挂载点
umount_all(){
    set +e
    if grep -q "${ROOTFS}/dev " /proc/mounts ; then
        umount -l ${ROOTFS}/dev
    fi
    if grep -q "${ROOTFS}/proc " /proc/mounts ; then
        umount -l ${ROOTFS}/proc
    fi
    if grep -q "${ROOTFS}/sys " /proc/mounts ; then
        umount -l ${ROOTFS}/sys
    fi
    set -e
}

# 运行 debootstrap/mmdebstrap 创建基础系统
run_debootstrap(){
    echo "=========================================="
    echo "Running Debootstrap"
    echo "=========================================="
    
    # 首先解析发行版路径 (ubuntu/jammy 或 debian/bookworm)
    if [[ "${VERSION}" == *"/"* ]]; then
        DISTRO_TYPE=$(echo ${VERSION} | cut -d'/' -f1)
        DISTRO_VERSION=$(echo ${VERSION} | cut -d'/' -f2)
    else
        # 向后兼容：自动检测发行版类型
        if [[ "${VERSION}" == "jammy" || "${VERSION}" == "focal" || "${VERSION}" == "noble" ]]; then
            DISTRO_TYPE="ubuntu"
            DISTRO_VERSION="${VERSION}"
        elif [[ "${VERSION}" == "bullseye" || "${VERSION}" == "bookworm" || "${VERSION}" == "trixie" ]]; then
            DISTRO_TYPE="debian"
            DISTRO_VERSION="${VERSION}"
        else
            echo "ERROR: Unknown version: ${VERSION}"
            echo "Use format: ubuntu/jammy or debian/bookworm"
            exit 1
        fi
    fi
    
    # 根据发行版类型设置源列表组件
    if [[ "${DISTRO_TYPE}" == "ubuntu" ]]; then
        LIST="main multiverse restricted universe"
    elif [[ "${DISTRO_TYPE}" == "debian" ]]; then
        LIST="main contrib non-free non-free-firmware"
    else
        echo "ERROR: Unsupported distribution type: ${DISTRO_TYPE}"
        echo "Supported: ubuntu, debian"
        exit 1
    fi
    
    # 设置默认镜像源（如果未指定）
    if [ -z "${MIRROR}" ]; then
        if [[ "${DISTRO_TYPE}" == "ubuntu" ]]; then
            MIRROR="http://ports.ubuntu.com/ubuntu-ports"
        elif [[ "${DISTRO_TYPE}" == "debian" ]]; then
            MIRROR="http://deb.debian.org/debian"
        fi
        echo "Using default mirror: ${MIRROR}"
    fi
    
    # 读取包列表
    BASE_PKGS_FILE="${BASE_DIR}/rootfs/${DISTRO_TYPE}/${DISTRO_VERSION}/packages/base.list"
    if [ ! -f "${BASE_PKGS_FILE}" ]; then
        echo "ERROR: Base packages list not found: ${BASE_PKGS_FILE}"
        echo "Available distributions:"
        ls -1 "${BASE_DIR}/rootfs/"*/*"/packages/base.list" 2>/dev/null | sed 's|.*/rootfs/||;s|/packages/base.list||' || echo "  (none)"
        exit 1
    fi
    
    BASE_PKGS=$(cat "${BASE_PKGS_FILE}")
    EXT_PKGS=""
    
    # 如果是桌面版本，添加桌面包
    if [ "${TYPE}" != "cli" ];then
        echo "Building desktop rootfs (${TYPE})..."
        EXT_PKGS_FILE="${BASE_DIR}/rootfs/${DISTRO_TYPE}/${DISTRO_VERSION}/packages/desktop-${TYPE}.list"
        if [ -f "${EXT_PKGS_FILE}" ]; then
            EXT_PKGS=$(cat "${EXT_PKGS_FILE}")
        else
            echo "WARNING: Desktop packages list not found: ${EXT_PKGS_FILE}"
            echo "         Falling back to CLI only"
        fi
    fi
    
    PACKAGES="${BASE_PKGS} ${EXT_PKGS}"
    
    echo ""
    echo "Build Configuration:"
    echo "  Host Architecture: ${HOST_ARCH}"
    echo "  Target Architecture: ${ARCH}"
    echo "  Distribution: ${DISTRO_TYPE}/${DISTRO_VERSION}"
    echo "  Rootfs Type: ${TYPE}"
    echo "  Components: ${LIST}"
    echo "  Mirror: ${MIRROR}"
    echo "  Base Packages: $(echo ${BASE_PKGS} | wc -w) packages"
    if [ -n "${EXT_PKGS}" ]; then
        echo "  Desktop Packages: $(echo ${EXT_PKGS} | wc -w) packages"
    fi
    echo ""
    
    # 清理旧的 rootfs
    if [ -d "${ROOTFS}" ];then
        echo "Removing old rootfs directory..."
        rm -rf "${ROOTFS}"
    fi
    mkdir -p "${ROOTFS}"
    
    # 使用 mmdebstrap 创建基础系统
    echo "Creating base system (this may take a while)..."
    
    if [ "${ARCH}" == "arm64" ];then
        mmdebstrap --architectures=arm64 \
            --include="${PACKAGES}" \
            ${DISTRO_VERSION} ${ROOTFS} \
            "deb ${MIRROR} ${DISTRO_VERSION} ${LIST}" \
            "deb ${MIRROR} ${DISTRO_VERSION}-updates ${LIST}"
    elif [ "${ARCH}" == "arm" ];then
        mmdebstrap --architectures=armhf \
            --include="${PACKAGES}" \
            ${DISTRO_VERSION} ${ROOTFS} \
            "deb ${MIRROR} ${DISTRO_VERSION} ${LIST}" \
            "deb ${MIRROR} ${DISTRO_VERSION}-updates ${LIST}"
    else
        echo "ERROR: Unsupported architecture: ${ARCH}"
        exit 2
    fi
    
    echo "Base system created successfully"
}

# 准备 APT 源列表
prepare_apt_sources(){
    echo "=========================================="
    echo "Configuring APT Sources"
    echo "=========================================="
    
    APT_SOURCES_DIR="${BASE_DIR}/rootfs/${DISTRO_TYPE}/${DISTRO_VERSION}/apt-sources"
    
    if [ "${DISTRO_TYPE}" == "ubuntu" ]; then
        if [[ "${DISTRO_VERSION}" == "focal" || "${DISTRO_VERSION}" == "jammy" ]]; then
            # 使用传统 sources.list
            APT_LIST="${APT_SOURCES_DIR}/sources.list"
            if [ -f "${APT_LIST}" ]; then
                cat "${APT_LIST}" > ${ROOTFS}/etc/apt/sources.list
                sed -i "s|http://ports.ubuntu.com/ubuntu-ports|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list
            else
                echo "WARNING: APT sources list not found: ${APT_LIST}"
            fi
        elif [ "${DISTRO_VERSION}" == "noble" ]; then
            # 使用 DEB822 格式
            echo "# Ubuntu sources have moved to /etc/apt/sources.list.d/ubuntu.sources" > ${ROOTFS}/etc/apt/sources.list
            APT_SOURCES="${APT_SOURCES_DIR}/ubuntu.sources"
            if [ -f "${APT_SOURCES}" ]; then
                cat "${APT_SOURCES}" > ${ROOTFS}/etc/apt/sources.list.d/ubuntu.sources
                sed -i "s|http://ports.ubuntu.com/ubuntu-ports|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list.d/ubuntu.sources
            fi
        fi
    elif [ "${DISTRO_TYPE}" == "debian" ]; then
        # Debian 统一使用 DEB822 格式
        rm -f ${ROOTFS}/etc/apt/sources.list
        APT_SOURCES="${APT_SOURCES_DIR}/debian.sources"
        if [ -f "${APT_SOURCES}" ]; then
            cat "${APT_SOURCES}" > ${ROOTFS}/etc/apt/sources.list.d/debian.sources
            sed -i "s|http://deb.debian.org/debian|${MIRROR}|g" ${ROOTFS}/etc/apt/sources.list.d/debian.sources
            sed -i "s|VERSION|${DISTRO_VERSION}|g" ${ROOTFS}/etc/apt/sources.list.d/debian.sources
        fi
    fi
    
    echo "APT sources configured"
}

# 设置挂载点和 resolv.conf
setup_mount_resolv(){
    echo "=========================================="
    echo "Setting Up Mount Points"
    echo "=========================================="
    
    mount --bind /dev ${ROOTFS}/dev
    mount -t proc /proc ${ROOTFS}/proc
    mount -t sysfs /sys ${ROOTFS}/sys
    
    cp -b /etc/resolv.conf ${ROOTFS}/etc/resolv.conf
    
    echo "Mount points configured"
}

# 设置网络（从板级配置调用）
setup_dhcp(){
    echo "Setting up network configuration..."
    # 此函数将在 board.conf 中被覆盖
}

# 设置首次启动服务
setup_firstrun(){
    echo "=========================================="
    echo "Configuring First Boot Services"
    echo "=========================================="
    
    # 复制首次启动脚本
    INIT_RESIZE_SCRIPT="${BASE_DIR}/rootfs/overlays/services/init-resize/init-resize.sh"
    INIT_RESIZE_SERVICE="${BASE_DIR}/rootfs/overlays/services/init-resize/init-resize.service"
    
    if [ -f "${INIT_RESIZE_SCRIPT}" ]; then
        cp "${INIT_RESIZE_SCRIPT}" ${ROOTFS}/usr/local/bin/
        chmod +x ${ROOTFS}/usr/local/bin/init-resize.sh
    fi
    
    if [ -f "${INIT_RESIZE_SERVICE}" ]; then
        cp "${INIT_RESIZE_SERVICE}" ${ROOTFS}/etc/systemd/system/
        chroot ${ROOTFS} systemctl enable init-resize.service
    fi
    
    # 允许 root SSH 登录
    sed -i "s|#PermitRootLogin prohibit-password|PermitRootLogin yes|g" ${ROOTFS}/etc/ssh/sshd_config
    
    echo "First boot services configured"
}

# 清理 rootfs
clean_rootfs(){
    echo "=========================================="
    echo "Cleaning RootFS"
    echo "=========================================="
    
    chroot ${ROOTFS} apt clean
    
    # 删除 QEMU 静态二进制（如果是交叉编译）
    if [ "$HOST_ARCH" != "$ARCH" ];then
        if [ "${ARCH}" == "arm64" ];then
            rm -f ${ROOTFS}/usr/bin/qemu-aarch64-static
        elif [ "${ARCH}" == "arm" ];then
            rm -f ${ROOTFS}/usr/bin/qemu-arm-static
        fi
    fi
    
    echo "RootFS cleaned"
}

# 设置主机名和 fstab
setup_hostname_fstab(){
    echo "=========================================="
    echo "Configuring Hostname and Fstab"
    echo "=========================================="
    
    # 设置 hostname
    echo "${BOARD_NAME}" > ${ROOTFS}/etc/hostname
    
    # 设置 hosts
    echo "127.0.0.1       localhost" > ${ROOTFS}/etc/hosts
    echo "127.0.1.1       ${BOARD_NAME}" >> ${ROOTFS}/etc/hosts
    
    # 添加默认用户 sudo 权限
    echo "bsp ALL=(ALL) NOPASSWD: ALL" > ${ROOTFS}/etc/sudoers.d/010_bsp-nopassword
    chmod 0440 ${ROOTFS}/etc/sudoers.d/010_bsp-nopassword
    
    # 设置 fstab
    cat > ${ROOTFS}/etc/fstab <<EOF
# /etc/fstab: static file system information.
#
# <file system>   <mount point>   <type>  <options>       <dump>  <pass>
LABEL=boot        /boot           vfat    defaults          0       2
LABEL=rootfs      /               ext4    defaults,noatime  0       1
tmpfs             /tmp            tmpfs   defaults,nosuid   0       0
EOF
    
    echo "Hostname: ${BOARD_NAME}"
    echo "Fstab configured"
}

# ==================== Main Script ====================

# 检查是否为 root 用户
if [ "$(id -u)" != "0" ]; then
    echo "ERROR: This script must be run as root"
    echo "Please use: sudo $0 $@"
    exit 1
fi

echo "=========================================="
echo "BSP RootFS Build Tool"
echo "=========================================="
echo "Started at: $(date)"
echo ""

HOST_ARCH=$(arch)
WORKSPACE=$(pwd)

init_params
parse_args "$@" || show_help $?

# 加载配置文件
TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${TOOL_DIR}/.." && pwd)"
CONFIG_DIR="${BASE_DIR}/configs"

CONFIG_FILE="${CONFIG_DIR}/${BOARD}.conf"
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "ERROR: Config file not found: ${CONFIG_FILE}"
    exit 1
fi

echo "Loading configuration: ${BOARD}"
source "${CONFIG_FILE}"

# 自动检测镜像源（如果未指定）
if [ -z "${MIRROR}" ]; then
    if [[ "${VERSION}" == "jammy" || "${VERSION}" == "noble" || "${VERSION}" == "focal" ]];then
        MIRROR="http://ports.ubuntu.com/ubuntu-ports"
    elif [[ "${VERSION}" == "bullseye" || "${VERSION}" == "bookworm" || "${VERSION}" == "trixie" ]];then
        MIRROR="http://deb.debian.org/debian"
    fi
fi

echo "Configuration:"
echo "  Board: ${BOARD_NAME}"
echo "  Architecture: ${ARCH}"
echo "  OS Version: ${VERSION}"
echo "  Rootfs Type: ${TYPE}"
echo "  Mirror: ${MIRROR}"
echo "  Workspace: ${WORKSPACE}"
echo ""

# 加载辅助函数库
if [ -f "${TOOL_DIR}/lib/rootfs/rootfs-deb.sh" ]; then
    source "${TOOL_DIR}/lib/rootfs/rootfs-deb.sh"
fi

# 检查依赖
echo "Checking dependencies..."
MISSING_DEPS=""
for cmd in mmdebstrap debootstrap chroot; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS $cmd"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    echo "ERROR: Missing required tools:$MISSING_DEPS"
    echo "Install with: sudo apt-get install mmdebstrap debootstrap"
    exit 1
fi

# 执行构建流程
set -e  # 遇到错误立即退出

# 注册清理函数
trap 'umount_all' EXIT

# 1. 创建基础系统
run_debootstrap

# 2. 配置 APT 源
prepare_apt_sources

# 3. 设置挂载点
setup_mount_resolv

# 4. 板级网络配置
setup_dhcp

# 5. 首次启动服务
setup_firstrun

# 6. 清理
clean_rootfs

# 7. 配置主机名和 fstab
setup_hostname_fstab

# 8. 卸载
umount_all

# 9. 重命名并打包
echo ""
echo "=========================================="
echo "Packing RootFS"
echo "=========================================="

# 构建正确的文件名（使用 distro_version 而不是完整路径）
ROOTFS_NAME="rootfs-${DISTRO_VERSION}-${TYPE}"
TARBALL_NAME="${WORKSPACE}/rootfs-${DISTRO_TYPE}-${DISTRO_VERSION}-${TYPE}.tar.gz"

echo "Renaming rootfs directory..."
mv "${ROOTFS}" "${ROOTFS_NAME}" || {
    echo "ERROR: Failed to rename rootfs directory"
    exit 1
}

echo "Creating tarball: $(basename ${TARBALL_NAME})"
pushd "${ROOTFS_NAME}" > /dev/null
tar -zcf "${TARBALL_NAME}" . || {
    echo "ERROR: Failed to create tarball"
    popd > /dev/null
    exit 1
}
popd > /dev/null

echo "Cleaning up..."
rm -rf "${ROOTFS_NAME}"

echo ""
echo "=========================================="
echo "✅ RootFS Build Completed Successfully!"
echo "=========================================="
echo "Distribution: ${DISTRO_TYPE}/${DISTRO_VERSION}"
echo "RootFS Type: ${TYPE}"
echo "Output: ${TARBALL_NAME}"
echo ""
ls -lh "${TARBALL_NAME}"
echo ""
echo "Completed at: $(date)"

