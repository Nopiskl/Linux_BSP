# BSP_T527 交互式构建指南

## 🎯 交互式构建模式

BSP_T527 现在支持像 AvaotaOS 一样的完整交互式构建模式，包括 RootFS 相关的所有选项！

## 🚀 快速开始

### 启动交互式构建

```bash
cd /home/nopiskl/T527/BSP/BSP_T527
sudo ./build.sh
```

不带任何参数运行即可进入交互式模式。

## 📋 交互式选项流程

### 1. 选择板卡 (Select Target Board)

```
┌─────────────────────────────────────┐
│ Choose target board:                │
├─────────────────────────────────────┤
│ example         example              │
│ (your boards...)                    │
└─────────────────────────────────────┘
```

### 2. 选择内核目标 (Select Kernel Target)

```
┌─────────────────────────────────────┐
│ Select kernel target:                │
├─────────────────────────────────────┤
│ linux-5.15     linux-5.15 Branch    │
│ linux-6.1      linux-6.1 Branch     │
└─────────────────────────────────────┘
```

### 3. 内核配置 (Kernel menuconfig)

```
┌─────────────────────────────────────┐
│ Run menuconfig?                      │
├─────────────────────────────────────┤
│ no             No                    │
│ yes            Yes                   │
└─────────────────────────────────────┘
```

### 4. 构建模式 (Build Mode)

```
┌─────────────────────────────────────┐
│ Build kernel only?                   │
├─────────────────────────────────────┤
│ no             No                    │
│ yes            Yes                   │
└─────────────────────────────────────┘
```

### 5. 源码管理 (Source Management)

```
┌─────────────────────────────────────┐
│ Use local sources?                   │
├─────────────────────────────────────┤
│ yes            Yes (默认)           │
│ no             No                    │
└─────────────────────────────────────┘
```

### 6. 编译加速 (Use ccache)

```
┌─────────────────────────────────────┐
│ Use ccache?                          │
├─────────────────────────────────────┤
│ yes            Yes (推荐)           │
│ no             No                    │
└─────────────────────────────────────┘
```

### 7. 清理构建 (Clean Build)

```
┌─────────────────────────────────────┐
│ Clean output directory?              │
├─────────────────────────────────────┤
│ no             No (默认)            │
│ yes            Yes                   │
└─────────────────────────────────────┘
```

### 8. ✨ 构建 RootFS (Build RootFS) - 新增！

```
┌─────────────────────────────────────┐
│ Build root filesystem?               │
├─────────────────────────────────────┤
│ no             Skip RootFS build     │
│ yes            Build RootFS          │
└─────────────────────────────────────┘
```

### 9. ✨ 选择发行版 (Linux Distribution) - 新增！

如果选择构建 RootFS，将显示：

```
┌──────────────────────────────────────────────────┐
│ Select distribution version:                     │
├──────────────────────────────────────────────────┤
│ ubuntu/focal      Ubuntu 20.04 LTS (Focal)      │
│ ubuntu/jammy      Ubuntu 22.04 LTS (Jammy) ⭐   │
│ ubuntu/noble      Ubuntu 24.04 LTS (Noble)      │
│ debian/bullseye   Debian 11 (Bullseye)          │
│ debian/bookworm   Debian 12 (Bookworm) ⭐       │
│ debian/trixie     Debian 13 (Trixie - Testing)  │
└──────────────────────────────────────────────────┘
```

### 10. ✨ 选择系统类型 (System Type) - 新增！

```
┌──────────────────────────────────────────────┐
│ Select rootfs type:                          │
├──────────────────────────────────────────────┤
│ cli          Console/CLI (Minimal, ~500MB)   │
│ xfce         XFCE Desktop (Lightweight, ~2GB)│
│ gnome        GNOME Desktop (Full, ~4GB)      │
│ kde          KDE Plasma (Modern, ~4GB)       │
│ lxqt         LXQt Desktop (Ultra-light, ~1.5GB)│
└──────────────────────────────────────────────┘
```

### 11. ✨ 选择 APT 镜像源 (APT Mirror) - 新增！

```
┌────────────────────────────────────────────────┐
│ Select APT mirror source:                      │
├────────────────────────────────────────────────┤
│ auto        Auto-detect (use official mirror)  │
│ ustc        USTC Mirror (China) ⭐             │
│ tuna        Tsinghua Mirror (China)            │
│ aliyun      Aliyun Mirror (China)              │
│ huawei      Huawei Mirror (China)              │
│ official    Official Mirror (International)    │
│ custom      Custom URL (will prompt)           │
└────────────────────────────────────────────────┘
```

### 12. GitHub 镜像 (GitHub Mirror)

如果选择从远程获取源码：

```
┌─────────────────────────────────────┐
│ Use GitHub mirror?                   │
├─────────────────────────────────────┤
│ no             No                    │
│ yes            Yes                   │
└─────────────────────────────────────┘
```

如果选择 yes，还会提示输入镜像 URL。

## 💡 交互式构建示例

### 示例 1: 完整系统构建（内核 + RootFS）

```bash
sudo ./build.sh
```

选择流程：
1. Board: `example`
2. Kernel target: `linux-5.15`
3. Menuconfig: `no`
4. Kernel only: `no`
5. Use local: `yes`
6. Ccache: `yes`
7. Clean: `no`
8. **Build RootFS: `yes`** ✨
9. **Distribution: `ubuntu/jammy`** ✨
10. **RootFS type: `cli`** ✨
11. **APT Mirror: `ustc`** ✨
12. GitHub mirror: `no`

### 示例 2: 仅构建内核

```bash
sudo ./build.sh
```

选择流程：
1. Board: `example`
2. Kernel target: `linux-5.15`
3. Menuconfig: `no`
4. **Kernel only: `yes`** 
   (选择 yes 后，将跳过 RootFS 相关选项)
5. Use local: `yes`
6. Ccache: `yes`
7. Clean: `no`
8. GitHub mirror: `no`

### 示例 3: 桌面系统构建

```bash
sudo ./build.sh
```

选择流程：
1. Board: `example`
2. Kernel only: `no`
3. **Build RootFS: `yes`**
4. **Distribution: `ubuntu/jammy`**
5. **RootFS type: `xfce`** ✨ 选择桌面环境
6. **APT Mirror: `ustc`**

## 📊 构建配置总结

完成所有选择后，系统会显示配置总结：

```
+-------[ Build Config ]--------
| Board=example
| Arch=arm64
| Menuconfig=no
| Target=linux-5.15
| Local=yes
| Mirror=no
| KernelOnly=no
| Ccache=yes
| Clean=no
| LinuxRepo=https://github.com/AvaotaSBC/linux.git
| LinuxBranch=linux-5.15
| LinuxConfig=sun55i_t527_bsp_defconfig
+-------[ RootFS Config ]-------
| BuildRootFS=yes
| Distro=ubuntu/jammy
| Type=cli
| APT Mirror=https://mirrors.ustc.edu.cn/ubuntu-ports
+-------------------------------
Next time run:
sudo ./build.sh -b example -k no -g linux-5.15 -l yes -i no -o no -e yes -c no -r yes -v ubuntu/jammy -t cli -m "https://mirrors.ustc.edu.cn/ubuntu-ports"
-------------------------------
```

## 🎯 命令行参数模式

如果不想使用交互式模式，可以直接使用命令行参数：

### 完整系统构建

```bash
sudo ./build.sh \
    -b example \
    -k no \
    -l yes \
    -e yes \
    -o no \
    -r yes \
    -v ubuntu/jammy \
    -t cli \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

### 仅内核构建

```bash
sudo ./build.sh \
    -b example \
    -k no \
    -l yes \
    -e yes \
    -o yes
```

### 桌面系统构建

```bash
sudo ./build.sh \
    -b example \
    -r yes \
    -v ubuntu/jammy \
    -t xfce \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

## 📋 参数说明

| 参数 | 长格式 | 说明 | 默认值 |
|------|--------|------|--------|
| `-b` | `--board` | 板卡名称 | none |
| `-k` | `--menuconfig` | 运行内核menuconfig | no |
| `-g` | `--target` | 内核目标/分支 | bsp |
| `-l` | `--local` | 使用本地源码 | yes |
| `-i` | `--mirror` | GitHub镜像URL | no |
| `-e` | `--ccache` | 使用ccache | yes |
| `-o` | `--kernel-only` | 仅构建内核 | no |
| `-c` | `--clean` | 清理输出目录 | no |
| `-r` | `--build-rootfs` | 构建根文件系统 | none |
| `-v` | `--distro-version` | 发行版版本 | none |
| `-t` | `--rootfs-type` | 根文件系统类型 | none |
| `-m` | `--apt-mirror` | APT镜像URL | none |
| `-h` | `--help` | 显示帮助 | - |

## 🔍 构建流程

### 完整构建流程

```
1. Checking sources (获取源码)
   └─ 自动下载或使用本地源码

2. Building bootloader (构建引导加载程序)
   └─ 编译 U-Boot/SyterKit

3. Building kernel (构建内核)
   ├─ 编译内核
   ├─ 生成 DTB
   ├─ 打包模块
   └─ 生成 .deb 包
       ├─ linux-image-*.deb
       ├─ linux-headers-*.deb
       ├─ linux-dtb-*.deb
       └─ linux-libc-dev-*.deb

4. Building RootFS (构建根文件系统) ✨ 新增
   ├─ 运行 debootstrap
   ├─ 配置 APT 源
   ├─ 安装基础包
   ├─ 配置系统服务
   ├─ 清理和优化
   └─ 打包 tar.gz
       └─ rootfs-jammy-cli.tar.gz
```

## 📦 输出文件

构建完成后，输出目录结构：

```
output/
├── linux/                        # 内核源码
├── bootloader-example/          # Bootloader文件
├── example-kernel-pkgs/         # 内核包
│   ├── linux-image-*.deb
│   ├── linux-headers-*.deb
│   ├── linux-dtb-*.deb
│   └── linux-libc-dev-*.deb
└── rootfs-jammy-cli.tar.gz     # RootFS 打包 ✨
```

## 💡 使用技巧

### 1. 快速重新构建

如果源码已存在，使用本地源码可以大大加快构建速度：

```bash
# 使用本地源码（推荐）
-l yes
```

### 2. 使用 ccache 加速编译

启用 ccache 可以在重新编译时节省大量时间：

```bash
# 启用 ccache（推荐）
-e yes
```

### 3. 使用国内镜像

中国大陆用户建议使用国内镜像源：

```bash
# GitHub 镜像
-i https://mirror.ghproxy.com

# APT 镜像
-m https://mirrors.ustc.edu.cn/ubuntu-ports  # Ubuntu
-m https://mirrors.ustc.edu.cn/debian        # Debian
```

### 4. 分步构建

可以分别构建内核和 RootFS：

```bash
# 步骤 1: 仅构建内核
sudo ./build.sh -b example -o yes -e yes

# 步骤 2: 仅构建 RootFS
cd output
sudo bash ../tools/build-rootfs.sh -b example -v ubuntu/jammy -t cli
```

## 🎓 对比 AvaotaOS

BSP_T527 的交互式界面参考了 AvaotaOS 的设计，提供相似的用户体验：

| 特性 | AvaotaOS | BSP_T527 | 说明 |
|------|----------|----------|------|
| 交互式选择 | ✅ | ✅ | Dialog 界面 |
| 板卡选择 | ✅ | ✅ | 自动扫描配置文件 |
| 发行版选择 | ✅ | ✅ | Ubuntu/Debian |
| 系统类型 | ✅ | ✅ | CLI/Desktop |
| 镜像源选择 | ✅ | ✅ | 国内/国际镜像 |
| 内核配置 | ✅ | ✅ | menuconfig |
| 命令行模式 | ✅ | ✅ | 支持参数 |

## 🐛 故障排除

### dialog 未安装

```bash
ERROR: 'dialog' command not found.
Install with: sudo apt-get install dialog
```

解决：
```bash
sudo apt-get install dialog
```

### 权限不足

```bash
ERROR: This script must be run as root
```

解决：
```bash
sudo ./build.sh
```

### RootFS 构建失败

检查：
1. 网络连接是否正常
2. 磁盘空间是否足够（至少10GB）
3. 是否安装了必要工具（mmdebstrap）

```bash
sudo apt-get install mmdebstrap debootstrap qemu-user-static
```

## 📚 相关文档

- [RootFS 构建详细指南](ROOTFS_BUILD.md)
- [RootFS 快速开始](QUICKSTART_ROOTFS.md)
- [RootFS 配置说明](rootfs/README.md)
- [迁移指南](MIGRATION.md)
- [最终结构](FINAL_STRUCTURE.md)

---

**更新日期**: 2025-11-06
**版本**: v2.0
**特性**: 完整交互式构建支持

