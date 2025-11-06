# BSP 构建工具

本目录包含 BSP 框架的核心构建工具。

## 工具列表

### 主要构建脚本

| 脚本 | 功能 | 说明 |
|------|------|------|
| `get-sources.sh` | 获取源代码 | 克隆内核和 bootloader 源代码 |
| `build-kernel.sh` | 构建内核 | 编译内核并生成 Debian 包 |
| `build-boot.sh` | 构建 Bootloader | 编译 U-Boot/SyterKit 等 |
| `build-rootfs.sh` | 构建根文件系统 | 使用 debootstrap 创建 rootfs |

### 辅助工具库

```
tools/lib/
├── kernel-deb.sh      # 内核 Debian 包生成函数
├── bootloader/        # Bootloader 构建库
└── rootfs/           # RootFS 辅助函数
    └── rootfs-deb.sh
```

## 使用方法

### 1. 获取源代码

```bash
cd output
sudo bash ../tools/get-sources.sh -b example

# 使用 GitHub 镜像加速
sudo bash ../tools/get-sources.sh -b example -i https://mirror.ghproxy.com
```

### 2. 构建内核

```bash
cd output
sudo bash ../tools/build-kernel.sh -b example

# 启用 menuconfig
sudo bash ../tools/build-kernel.sh -b example -k yes

# 使用 ccache 加速
sudo bash ../tools/build-kernel.sh -b example -e yes
```

生成的包：
- `linux-image-*.deb` - 内核镜像和模块
- `linux-headers-*.deb` - 内核头文件
- `linux-dtb-*.deb` - 设备树
- `linux-libc-dev-*.deb` - C 库开发头文件

### 3. 构建根文件系统

```bash
cd output
sudo bash ../tools/build-rootfs.sh -b example -v jammy -t cli

# 构建 XFCE 桌面版本
sudo bash ../tools/build-rootfs.sh -b example -v jammy -t xfce

# 使用国内镜像
sudo bash ../tools/build-rootfs.sh -b example -v jammy -t cli \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

支持的 OS 版本：
- Ubuntu: `jammy` (22.04), `noble` (24.04)
- Debian: `bookworm` (12), `trixie` (13)

支持的类型：
- `cli` - 命令行界面（最小系统）
- `xfce` - XFCE 桌面环境
- `gnome` - GNOME 桌面环境
- `kde` - KDE Plasma 桌面
- `lxqt` - LXQt 桌面环境

### 4. 构建 Bootloader

```bash
cd output
sudo bash ../tools/build-boot.sh -b example
```

## 完整构建流程

使用主构建脚本 `build.sh`：

```bash
# 交互式构建
sudo ./build.sh

# 命令行参数构建
sudo ./build.sh -b example -k no -l yes -o no -e yes -c no

# 仅构建内核
sudo ./build.sh -b example -o yes

# 清理输出目录
sudo ./build.sh clean

# 清理所有（包括源代码）
sudo ./build.sh clean --all
```

## 工具依赖

### 必需工具

```bash
# 基础工具
sudo apt-get install -y \
    build-essential \
    git \
    bc \
    bison \
    flex \
    libssl-dev \
    libncurses5-dev \
    libelf-dev

# 交叉编译工具链
sudo apt-get install -y \
    gcc-aarch64-linux-gnu \
    g++-aarch64-linux-gnu

# RootFS 构建工具
sudo apt-get install -y \
    debootstrap \
    mmdebstrap \
    qemu-user-static

# 可选工具
sudo apt-get install -y \
    ccache \
    dialog
```

### 架构支持

- **ARM64**: `gcc-aarch64-linux-gnu`
- **ARM32**: `gcc-arm-linux-gnueabihf`

## 高级用法

### 自定义内核配置

1. 运行 menuconfig：
```bash
sudo ./tools/build-kernel.sh -b example -k yes
```

2. 配置会自动保存到 `output/user_defconfig`

3. 下次构建会自动使用保存的配置

### 添加内核补丁

创建补丁目录：
```bash
mkdir -p patches/kernel/myboard/patches
```

放置补丁文件：
```bash
cp my-patch.patch patches/kernel/myboard/patches/
```

在配置文件中启用：
```bash
LINUX_PATHDIR="myboard"
```

### 自定义 RootFS

1. 修改包列表：
```bash
nano os/jammy/base-packages.list
```

2. 创建桌面环境包列表：
```bash
nano os/jammy/xfce-packages.list
```

3. 添加自定义脚本到 `target/` 目录

### 使用 ccache 加速编译

首次安装：
```bash
sudo apt-get install ccache
ccache -M 20G  # 设置缓存大小
```

启用 ccache：
```bash
sudo ./build.sh -b example -e yes
```

查看缓存统计：
```bash
ccache -s
```

## 输出文件说明

构建完成后，输出目录结构：

```
output/
├── linux/                    # 内核源代码
├── example-kernel-pkgs/      # 内核 Debian 包
│   ├── linux-image-*.deb
│   ├── linux-headers-*.deb
│   ├── linux-dtb-*.deb
│   └── linux-libc-dev-*.deb
├── bootloader-example/       # Bootloader 文件
│   ├── u-boot.bin
│   ├── boot0_sdcard.bin
│   └── ...
└── rootfs-jammy-cli.tar.gz  # 根文件系统打包
```

## 故障排除

### 权限错误

所有构建脚本需要 root 权限：
```bash
sudo ./tools/build-kernel.sh -b example
```

或修改输出目录所有权：
```bash
sudo chown -R $USER:$USER output/
```

### 编译器未找到

安装交叉编译工具链：
```bash
sudo apt-get install gcc-aarch64-linux-gnu
```

### 源代码获取失败

1. 检查网络连接
2. 使用 GitHub 镜像：
```bash
sudo ./tools/get-sources.sh -b example -i https://mirror.ghproxy.com
```

### mmdebstrap 未找到

```bash
sudo apt-get install mmdebstrap debootstrap
```

## 性能优化

### 并行编译

默认使用所有 CPU 核心（`-j$(nproc)`）

手动指定核心数：
```bash
# 修改 build-kernel.sh 中的
make -j4  # 使用 4 核
```

### ccache 配置

```bash
# 增加缓存大小
ccache -M 50G

# 清理缓存
ccache -C

# 查看统计
ccache -s
```

### 磁盘空间

建议最小空间：
- 内核构建：20GB
- RootFS 构建：10GB（CLI）/ 30GB（桌面）
- 完整构建：50GB

## 参考资料

- [内核配置指南](../configs/README.md)
- [板级配置模板](../configs/example.conf)
- [OS 配置说明](../os/README.md)
- [快速开始](../QUICKSTART.md)
