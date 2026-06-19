# BSP_T527 - 板级支持包

[English](./README.md)

完整的 BSP 构建系统，支持 Linux 内核、引导加载器和根文件系统构建。

## 快速开始

```bash
# 安装依赖
sudo apt-get update && sudo apt-get install -y \
    dialog gcc-aarch64-linux-gnu mmdebstrap debootstrap qemu-user-static

# 交互式构建（推荐）
sudo ./build.sh

# 命令行构建
sudo ./build.sh --board example --distro-version ubuntu/jammy \
    --rootfs-type cli --build-rootfs yes
```

## 文档

所有文档位于 [docs/](./docs/) 目录：

- **[快速开始](./docs/CN/快速开始.md)** - 5分钟上手
- **[板型配置](./docs/CN/板型配置.md)** - 板型设置指南
- **[内核配置](./docs/CN/内核配置.md)** - 内核和设备树
- **[RootFS配置](./docs/CN/RootFS配置.md)** - 根文件系统
- **[常见问题](./docs/CN/常见问题.md)** - 问题排查
- **[目录结构](./docs/CN/目录结构.md)** - 项目组织

## 特性

- 交互式构建界面
- 多发行版支持：Ubuntu (20.04/22.04/24.04), Debian (11/12)
- 多桌面环境：CLI, XFCE, GNOME, KDE, LXQt
- 国内镜像加速：中科大、清华、阿里云、华为云
- 自动生成 .deb 软件包
- 高度可配置

## 系统要求

- 操作系统：Ubuntu 20.04+ 或 Debian 11+
- CPU：双核或更多（推荐四核）
- 内存：4GB+（推荐 8GB）
- 磁盘：20GB+（推荐 50GB）
- 需要 root 权限（sudo）

## 支持的发行版

**Ubuntu:** 20.04 (Focal), 22.04 (Jammy - 推荐), 24.04 (Noble)
**Debian:** 11 (Bullseye), 12 (Bookworm - 推荐), Testing (Trixie)

## 项目结构

```text
BSP_T527/
├── build.sh           # 主构建脚本
├── configs/           # 板级配置
│   ├── board/         # 板型配置文件
│   └── target/        # 板级 Linux/U-Boot 覆盖文件
├── tools/             # 构建工具
├── rootfs/            # RootFS 配置
├── docs/              # 文档（中英文）
│   ├── CN/            # 中文文档
│   └── EN/            # 英文文档
└── output/            # 构建输出（自动生成）
```

## 使用示例

仅构建内核：

```bash
sudo ./build.sh --board example --kernel-only yes
```

构建最小系统：

```bash
sudo ./build.sh --board example --distro-version ubuntu/jammy \
    --rootfs-type cli --apt-mirror https://mirrors.aliyun.com/ubuntu-ports
```

构建桌面系统：

```bash
sudo ./build.sh --board example --distro-version ubuntu/jammy \
    --rootfs-type xfce --build-rootfs yes
```

## 许可证

请参考项目许可证文件。

## 致谢

本项目参考了 [AvaotaOS](https://github.com/AvaotaSBC/AvaotaOS)。
