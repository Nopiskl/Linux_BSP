# 交互式构建指南

## 🎯 新功能

BSP_T527 现在支持像 AvaotaOS 一样的交互式构建界面！

## 🚀 使用方法

### 方式 1: 交互式构建（推荐）

只需运行构建脚本，不带任何参数：

```bash
cd /home/nopiskl/T527/BSP/BSP_T527
sudo ./build.sh
```

系统会引导您通过一系列对话框选择：

#### 1️⃣ 选择目标板卡
```
┌─[ Select Target ]─────────────────────┐
│ Choose target board:                  │
│ ┌────────────────────────────────────┐│
│ │ example                   example  ││
│ │ (其他板卡配置...)                   ││
│ └────────────────────────────────────┘│
└───────────────────────────────────────┘
```

#### 2️⃣ 选择内核配置
```
┌─[ Kernel Configure ]──────────────────┐
│ Run kernel menuconfig?                │
│ ┌────────────────────────────────────┐│
│ │ no     Don't run menuconfig        ││
│ │ yes    Run menuconfig              ││
│ └────────────────────────────────────┘│
└───────────────────────────────────────┘
```

#### 3️⃣ 选择是否仅构建内核
```
┌─[ Build Mode ]────────────────────────┐
│ Build kernel only?                    │
│ ┌────────────────────────────────────┐│
│ │ no     Build all components        ││
│ │ yes    Only build kernel           ││
│ └────────────────────────────────────┘│
└───────────────────────────────────────┘
```

#### 4️⃣ 选择是否使用 ccache
```
┌─[ Compilation ]───────────────────────┐
│ Use ccache?                           │
│ ┌────────────────────────────────────┐│
│ │ no     Don't use ccache            ││
│ │ yes    Use ccache (faster)         ││
│ └────────────────────────────────────┘│
└───────────────────────────────────────┘
```

#### 5️⃣ 选择是否清理输出目录
```
┌─[ Clean Build ]───────────────────────┐
│ Clean output directory?               │
│ ┌────────────────────────────────────┐│
│ │ no     Keep existing files         ││
│ │ yes    Clean before build          ││
│ └────────────────────────────────────┘│
└───────────────────────────────────────┘
```

#### 6️⃣ **🆕 选择是否构建 RootFS**
```
┌─[ Build RootFS ]──────────────────────┐
│ Build root filesystem?                │
│ ┌────────────────────────────────────┐│
│ │ no     Kernel and bootloader only  ││
│ │ yes    Build complete system       ││
│ └────────────────────────────────────┘│
└───────────────────────────────────────┘
```

#### 7️⃣ **🆕 选择 Linux 发行版**（如果选择构建 RootFS）
```
┌─[ System Distribution ]───────────────┐
│ Select Linux distribution:            │
│ ┌────────────────────────────────────┐│
│ │ ubuntu/focal     Ubuntu 20.04 LTS  ││
│ │ ubuntu/jammy     Ubuntu 22.04 LTS ⭐││
│ │ ubuntu/noble     Ubuntu 24.04 LTS  ││
│ │ debian/bullseye  Debian 11         ││
│ │ debian/bookworm  Debian 12 ⭐      ││
│ │ debian/trixie    Debian 13 (Test)  ││
│ └────────────────────────────────────┘│
└───────────────────────────────────────┘
```

#### 8️⃣ **🆕 选择系统类型**
```
┌─[ System Type ]───────────────────────┐
│ Select rootfs type:                   │
│ ┌────────────────────────────────────┐│
│ │ cli      Console/CLI (~500MB)      ││
│ │ xfce     XFCE Desktop (~2GB)       ││
│ │ gnome    GNOME Desktop (~4GB)      ││
│ │ kde      KDE Plasma (~4GB)         ││
│ │ lxqt     LXQt Desktop (~1.5GB)     ││
│ └────────────────────────────────────┘│
└───────────────────────────────────────┘
```

#### 9️⃣ **🆕 选择 APT 镜像源**
```
┌─[ APT Mirror ]────────────────────────┐
│ Select APT mirror source:             │
│ ┌────────────────────────────────────┐│
│ │ auto      Auto-detect (official)   ││
│ │ ustc      USTC (中科大)            ││
│ │ tuna      Tsinghua (清华)          ││
│ │ aliyun    Aliyun (阿里云)          ││
│ │ huawei    Huawei (华为)            ││
│ │ official  Official (国际)          ││
│ │ custom    Custom URL                ││
│ └────────────────────────────────────┘│
└───────────────────────────────────────┘
```

### 方式 2: 命令行参数

如果您已经知道要构建什么，可以直接使用命令行参数：

#### 仅构建内核
```bash
sudo ./build.sh -b example -k no -l yes -e yes
```

#### 构建内核 + Ubuntu 22.04 CLI
```bash
sudo ./build.sh \
    -b example \
    -k no \
    -l yes \
    -e yes \
    -r yes \
    -v ubuntu/jammy \
    -t cli \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

#### 构建内核 + Debian 12 XFCE 桌面
```bash
sudo ./build.sh \
    -b example \
    -k no \
    -l yes \
    -e yes \
    -r yes \
    -v debian/bookworm \
    -t xfce \
    -m https://mirrors.ustc.edu.cn/debian
```

#### 完整参数示例
```bash
sudo ./build.sh \
    -b example              # 板卡名称
    -k no                   # 不运行 menuconfig
    -g bsp                  # 内核目标
    -l yes                  # 使用本地源
    -i no                   # GitHub 镜像
    -e yes                  # 使用 ccache
    -o no                   # 不仅构建内核
    -c no                   # 不清理
    -r yes                  # 构建 RootFS
    -v ubuntu/jammy         # Ubuntu 22.04
    -t cli                  # CLI 类型
    -m https://mirrors.ustc.edu.cn/ubuntu-ports  # USTC 镜像
```

## 📋 参数说明

| 参数 | 简写 | 说明 | 示例 |
|------|------|------|------|
| `--board` | `-b` | 板卡名称 | `-b example` |
| `--menuconfig` | `-k` | 运行 menuconfig | `-k yes` |
| `--target` | `-g` | 内核目标 | `-g bsp` |
| `--local` | `-l` | 使用本地源 | `-l yes` |
| `--mirror` | `-i` | GitHub 镜像 | `-i https://...` |
| `--ccache` | `-e` | 使用 ccache | `-e yes` |
| `--kernel-only` | `-o` | 仅构建内核 | `-o yes` |
| `--clean` | `-c` | 清理输出 | `-c yes` |
| **`--build-rootfs`** | **`-r`** | **构建 RootFS** | **`-r yes`** |
| **`--distro-version`** | **`-v`** | **发行版版本** | **`-v ubuntu/jammy`** |
| **`--rootfs-type`** | **`-t`** | **RootFS 类型** | **`-t cli`** |
| **`--apt-mirror`** | **`-m`** | **APT 镜像** | **`-m https://...`** |

## 🎨 构建配置显示

运行构建后，会显示完整配置：

```
+-------[ Build Config ]--------
| Board=example
| Arch=arm64
| Menuconfig=no
| Target=bsp
| Local=yes
| Mirror=no
| KernelOnly=no
| Ccache=yes
| Clean=no
| LinuxRepo=https://github.com/AvaotaSBC/linux.git
| LinuxBranch=linux-5.15
| LinuxConfig=sun55i_t527_bsp_defconfig
+-------------------------------
+-------[ RootFS Config ]-------
| BuildRootFS=yes
| Distro=ubuntu/jammy
| Type=cli
| APT Mirror=https://mirrors.ustc.edu.cn/ubuntu-ports
+-------------------------------
Next time run:
sudo ./build.sh -b example -k no -g bsp -l yes -i no -o no -e yes -c no -r yes -v ubuntu/jammy -t cli -m "https://mirrors.ustc.edu.cn/ubuntu-ports"
-------------------------------
```

## 📦 构建输出

### 仅内核构建
```
output/
├── linux/                          # 内核源码
└── example-kernel-pkgs/           # 内核包
    ├── linux-image-*.deb          # 内核镜像
    ├── linux-headers-*.deb        # 内核头文件
    ├── linux-dtb-*.deb            # 设备树
    └── linux-libc-dev-*.deb       # C 库开发
```

### 完整系统构建
```
output/
├── linux/                          # 内核源码
├── example-kernel-pkgs/           # 内核包
│   ├── linux-image-*.deb
│   ├── linux-headers-*.deb
│   ├── linux-dtb-*.deb
│   └── linux-libc-dev-*.deb
├── bootloader-example/            # Bootloader
└── rootfs-jammy-cli.tar.gz       # RootFS 打包 (~500MB)
```

## 🔍 构建摘要

构建完成后显示摘要：

```
==========================================
Build Summary
==========================================
✓ Bootloader: /path/to/output/bootloader-example
✓ Kernel packages: /path/to/output/example-kernel-pkgs
  -rw-r--r-- linux-dtb-sun55i-t527-bsp_1.0.0_arm64.deb (86K)
  -rw-r--r-- linux-headers-sun55i-t527-bsp_1.0.0_arm64.deb (17M)
  -rw-r--r-- linux-image-sun55i-t527-bsp_1.0.0_arm64.deb (28M)
  -rw-r--r-- linux-libc-dev-sun55i-t527-bsp_1.0.0_arm64.deb (1.2M)
✓ RootFS tarball: /path/to/output/rootfs-jammy-cli.tar.gz
  -rw-r--r-- rootfs-jammy-cli.tar.gz (480M)

Build completed successfully!
Output: /path/to/output
```

## 💡 使用技巧

### 1. 首次构建
```bash
# 使用交互式界面
sudo ./build.sh

# 选择:
# - Board: example
# - Menuconfig: no
# - Kernel Only: no
# - ccache: yes
# - Clean: no
# - Build RootFS: yes
# - Distro: ubuntu/jammy
# - Type: cli
# - Mirror: ustc
```

### 2. 快速重构建
```bash
# 系统会提示"Next time run"命令，直接复制使用
sudo ./build.sh -b example -k no -g bsp -l yes -i no -o no -e yes -c no -r yes -v ubuntu/jammy -t cli -m "https://mirrors.ustc.edu.cn/ubuntu-ports"
```

### 3. 仅更新 RootFS
```bash
# 如果内核已构建，可以只构建 RootFS
cd output
sudo bash ../tools/build-rootfs.sh -b example -v ubuntu/jammy -t cli -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

### 4. 测试不同发行版
```bash
# Ubuntu 22.04
sudo ./build.sh -b example -r yes -v ubuntu/jammy -t cli

# Debian 12
sudo ./build.sh -b example -r yes -v debian/bookworm -t cli

# Ubuntu 24.04
sudo ./build.sh -b example -r yes -v ubuntu/noble -t cli
```

## 🐛 故障排除

### 问题：dialog 命令未找到

```bash
sudo apt-get install dialog
```

### 问题：权限不足

必须使用 `sudo` 运行：

```bash
sudo ./build.sh
```

### 问题：RootFS 构建失败

检查依赖：

```bash
sudo apt-get install mmdebstrap debootstrap qemu-user-static
```

### 问题：镜像源连接失败

尝试其他镜像源或使用官方源。

## 📚 相关文档

- [RootFS 构建详细指南](ROOTFS_BUILD.md)
- [快速开始](QUICKSTART_ROOTFS.md)
- [RootFS 配置说明](rootfs/README.md)
- [工具使用文档](tools/README.md)

## 🎉 总结

现在 BSP_T527 提供了：

✅ **像 AvaotaOS 一样的交互式界面**
✅ **完整的 RootFS 构建支持**
✅ **6 个 Linux 发行版可选**
✅ **5 种系统类型（CLI + 4 种桌面）**
✅ **智能镜像源选择**
✅ **命令行和交互式两种方式**

开始构建您的定制 Linux 系统吧！🚀

---

**更新日期**: 2025-11-06
**版本**: v2.0
**状态**: ✅ 生产就绪

