# BSP_T527 - T527 Board Support Package

全功能的 T527 开发板支持包，提供完整的 Linux 内核、引导加载器和根文件系统构建解决方案。

## ✨ 特性

- 🎯 **交互式构建** - 友好的菜单式界面，新手友好
- 🌍 **多发行版支持** - Ubuntu (20.04/22.04/24.04) + Debian (11/12/Testing)
- 🖥️ **灵活的系统类型** - CLI、XFCE、GNOME、KDE、LXQt
- 🚀 **国内镜像加速** - USTC、清华、阿里云、华为云
- 📦 **一键打包** - 自动生成 .deb 包和系统镜像
- 🔧 **高度可定制** - 支持自定义软件包、配置和服务

## 🚀 快速开始

### 安装依赖

```bash
sudo apt-get update && sudo apt-get install -y \
    dialog gcc-aarch64-linux-gnu mmdebstrap \
    debootstrap qemu-user-static
```

### 启动构建

```bash
# 交互式构建（推荐）
sudo ./build.sh

# 命令行构建
sudo ./build.sh \
  --board t527_dev \
  --distro-version ubuntu/jammy \
  --rootfs-type cli \
  --build-rootfs yes
```

## 📚 完整文档

**详细文档位于 [`docs/`](./docs/) 目录：**

| 文档 | 说明 |
|------|------|
| [**快速开始**](./docs/00-快速开始.md) | ⭐ 5分钟快速上手 |
| [环境配置](./docs/01-环境配置.md) | 依赖安装和环境准备 |
| [构建指南](./docs/02-构建指南.md) | 详细的构建流程 |
| [RootFS 配置](./docs/03-RootFS配置.md) | 根文件系统定制 |
| [常见问题](./docs/04-常见问题.md) | 问题排查和解决方案 |
| [目录结构](./docs/05-目录结构.md) | 项目文件组织说明 |

**📖 建议阅读顺序：**
1. [快速开始](./docs/00-快速开始.md) - 了解基本使用
2. [环境配置](./docs/01-环境配置.md) - 准备构建环境
3. [构建指南](./docs/02-构建指南.md) - 执行构建

## 📦 构建产物

```
output/
├── packages/           # Debian 软件包 (.deb)
├── rootfs/            # 根文件系统目录
├── linux/             # 内核源码和构建产物
├── boot/              # 引导加载器
└── *.tar.gz           # 打包的系统镜像
```

## 🎯 支持的配置

### 发行版

| 类型 | 版本 | 推荐 |
|------|------|------|
| Ubuntu | 20.04 Focal, 22.04 Jammy, 24.04 Noble | Jammy ⭐ |
| Debian | 11 Bullseye, 12 Bookworm, Testing Trixie | Bookworm ⭐ |

### 系统类型

| 类型 | 说明 | 磁盘占用 | 构建时间 |
|------|------|---------|----------|
| CLI | 命令行界面 | ~500MB | 30-45分钟 |
| XFCE | 轻量桌面 | ~2GB | 45-60分钟 |
| GNOME | 完整桌面 | ~4GB | 60-90分钟 |
| KDE | 现代桌面 | ~4GB | 60-90分钟 |
| LXQt | 超轻桌面 | ~1.5GB | 40-50分钟 |

## 🔧 使用示例

### 仅构建内核

```bash
sudo ./build.sh --board t527_dev --kernel linux-6.1 --build-rootfs no
```

### 构建最小系统

```bash
sudo ./build.sh \
  --board t527_dev \
  --distro-version ubuntu/jammy \
  --rootfs-type cli \
  --apt-mirror https://mirrors.aliyun.com/ubuntu-ports \
  --build-rootfs yes
```

### 构建桌面系统

```bash
sudo ./build.sh \
  --board t527_dev \
  --distro-version ubuntu/jammy \
  --rootfs-type xfce \
  --apt-mirror https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports \
  --build-rootfs yes
```

## 💡 项目结构

```
BSP_T527/
├── build.sh           # 主构建脚本
├── configs/           # 板级配置文件
├── tools/             # 构建工具脚本
│   ├── get-sources.sh
│   ├── build-kernel.sh
│   ├── build-rootfs.sh
│   └── build-boot.sh
├── rootfs/            # RootFS 配置
│   ├── ubuntu/
│   ├── debian/
│   └── overlays/
├── output/            # 构建输出（自动生成）
└── docs/              # 完整文档
```

## 📋 系统要求

- **操作系统：** Ubuntu 20.04+ 或 Debian 11+
- **CPU：** 双核或更多（推荐四核）
- **内存：** 4GB 或更多（推荐 8GB）
- **磁盘空间：** 20GB 或更多（推荐 50GB）
- **权限：** Root 权限（使用 sudo）

## ❓ 常见问题

### DNS 解析失败

```bash
# 配置 DNS
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/dns.conf > /dev/null << 'EOF'
[Resolve]
DNS=8.8.8.8 114.114.114.114
FallbackDNS=223.5.5.5 223.6.6.6
EOF
sudo systemctl restart systemd-resolved
```

### 构建速度慢

- 使用国内镜像源（aliyun、tuna、ustc）
- 增加系统交换空间
- 使用 `-j$(nproc)` 并行编译

### 磁盘空间不足

```bash
# 清理旧的构建产物
rm -rf output/

# 清理 APT 缓存
sudo apt-get clean
```

**更多问题？** 查看 [常见问题文档](./docs/04-常见问题.md)

## 🛠️ 高级使用

### 自定义内核配置

```bash
cd output/linux
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig
cd ../..
sudo ./build.sh --board t527_dev --build-rootfs no
```

### 添加自定义软件包

```bash
# 编辑包列表
vim rootfs/ubuntu/jammy/packages/base.list

# 添加包名
echo "vim" >> rootfs/ubuntu/jammy/packages/base.list
echo "htop" >> rootfs/ubuntu/jammy/packages/base.list

# 重新构建
sudo ./build.sh --board t527_dev --build-rootfs yes
```

### 查看帮助信息

```bash
# 主脚本
./build.sh --help

# RootFS 构建
./tools/build-rootfs.sh --help

# 内核构建
./tools/build-kernel.sh --help
```

## 📞 获取帮助

1. 查看 [完整文档](./docs/)
2. 查看 [常见问题](./docs/04-常见问题.md)
3. 提交 Issue 到项目仓库

## 📄 许可证

请参考项目许可证文件。

## 🙏 致谢

本项目参考了 [AvaotaOS](https://github.com/AvaotaSBC/AvaotaOS) 的设计思路和实现方式。

---

**开始使用：** [📖 查看快速开始指南](./docs/00-快速开始.md)
