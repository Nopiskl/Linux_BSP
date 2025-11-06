# 完整构建指南

本指南详细介绍 BSP_T527 的构建系统、所有参数选项和高级用法。

## 📖 目录
- [构建系统概述](#构建系统概述)
- [命令行参数](#命令行参数)
- [构建流程详解](#构建流程详解)
- [支持的配置](#支持的配置)
- [高级用法](#高级用法)

---

## 构建系统概述

BSP_T527 使用模块化的构建系统，支持：
- ✅ 交互式和命令行两种构建模式
- ✅ 内核编译和 Debian 包生成
- ✅ 多发行版 RootFS 构建
- ✅ 自动源码获取和更新
- ✅ 灵活的镜像源配置

### 构建脚本组织

```
BSP_T527/
├── build.sh              # 主构建脚本
├── tools/
│   ├── get-sources.sh    # 源码下载
│   ├── build-kernel.sh   # 内核编译
│   ├── build-rootfs.sh   # RootFS 构建
│   └── build-boot.sh     # Bootloader 构建
└── configs/
    └── *.conf            # 板级配置文件
```

---

## 命令行参数

### 基本参数

| 参数 | 说明 | 必需 | 默认值 | 示例 |
|------|------|------|--------|------|
| `-b, --board` | 板卡配置 | 是 | 无 | `t527_dev` |
| `-h, --help` | 显示帮助 | 否 | - | - |

### 内核相关参数

| 参数 | 说明 | 默认值 | 示例 |
|------|------|--------|------|
| `--kernel-only` | 仅构建内核 | - | `--kernel-only` |
| `--kernel-config` | 内核配置操作 | none | `menuconfig`/`defconfig` |

### RootFS 相关参数

| 参数 | 说明 | 默认值 | 可选值 |
|------|------|--------|--------|
| `--build-rootfs` | 是否构建 RootFS | `no` | `yes`/`no` |
| `--distro-version` | 发行版版本 | 无 | `ubuntu/jammy`, `debian/bookworm` 等 |
| `--rootfs-type` | RootFS 类型 | `cli` | `cli`/`xfce`/`gnome`/`kde`/`lxqt` |
| `--apt-mirror` | APT 镜像源 | 官方源 | URL 或留空 |

---

## 构建流程详解

### 阶段 1: 参数解析
- 解析命令行参数或启动交互界面
- 加载板级配置文件
- 验证参数有效性

### 阶段 2: 获取源码
```bash
tools/get-sources.sh
```
功能：
- 克隆或更新 Linux 内核仓库
- 克隆或更新 Bootloader 仓库
- 自动处理分支切换

### 阶段 3: 编译内核
```bash
tools/build-kernel.sh
```
流程：
1. 应用默认配置 (`defconfig`)
2. 可选：运行 `menuconfig` 手动配置
3. 编译内核 (`make -j$(nproc)`)
4. 生成设备树 (DTB)
5. 打包 Debian 包：
   - `linux-image-*.deb` - 内核和模块
   - `linux-headers-*.deb` - 头文件
   - `linux-dtb-*.deb` - 设备树

### 阶段 4: 构建 RootFS（可选）
```bash
tools/build-rootfs.sh
```
流程：
1. 使用 `mmdebstrap` 创建基础系统
2. 配置 APT 源
3. 安装系统服务（init-resize 等）
4. 配置网络和主机名
5. 清理和打包

### 阶段 5: 输出产物
所有构建产物保存到 `output/` 目录。

---

## 支持的配置

### 板卡配置

当前支持的板卡：

| 板卡名称 | 配置文件 | 架构 | 说明 |
|---------|---------|------|------|
| T527 开发板 | `t527_dev.conf` | ARM64 | 全志 T527 SoC |

### 发行版支持

#### Ubuntu 系列

| 版本 | 代号 | 参数值 | 推荐 | 说明 |
|------|------|--------|------|------|
| 20.04 LTS | Focal Fossa | `ubuntu/focal` | | 长期支持 |
| 22.04 LTS | Jammy Jellyfish | `ubuntu/jammy` | ⭐ | 推荐使用 |
| 24.04 LTS | Noble Numbat | `ubuntu/noble` | | 最新 LTS |

#### Debian 系列

| 版本 | 代号 | 参数值 | 推荐 | 说明 |
|------|------|--------|------|------|
| 11 | Bullseye | `debian/bullseye` | | 稳定版 |
| 12 | Bookworm | `debian/bookworm` | ⭐ | 推荐使用 |
| 13 | Trixie | `debian/trixie` | | 测试版 |

### RootFS 类型

| 类型 | 描述 | 大小 | 适用场景 |
|------|------|------|----------|
| `cli` | 命令行最小化系统 | ~500MB | 服务器、嵌入式 |
| `xfce` | XFCE 轻量桌面 | ~2GB | 资源受限设备 |
| `gnome` | GNOME 完整桌面 | ~4GB | 桌面体验 |
| `kde` | KDE Plasma 桌面 | ~4GB | 现代化桌面 |
| `lxqt` | LXQt 超轻量桌面 | ~1.5GB | 低功耗设备 |

### 镜像源配置

#### 中国大陆镜像（推荐）

| 镜像 | Ubuntu URL | Debian URL |
|------|-----------|-----------|
| 阿里云 | `https://mirrors.aliyun.com/ubuntu-ports` | `https://mirrors.aliyun.com/debian` |
| 清华大学 | `https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports` | `https://mirrors.tuna.tsinghua.edu.cn/debian` |
| 中科大 | `https://mirrors.ustc.edu.cn/ubuntu-ports` | `https://mirrors.ustc.edu.cn/debian` |
| 华为云 | `https://mirrors.huaweicloud.com/ubuntu-ports` | `https://mirrors.huaweicloud.com/debian` |

#### 官方镜像

| 发行版 | 官方源 |
|-------|--------|
| Ubuntu | `http://ports.ubuntu.com/ubuntu-ports` |
| Debian | `http://deb.debian.org/debian` |

---

## 高级用法

### 示例 1: 构建最小化 CLI 系统

```bash
sudo ./build.sh \
  --board t527_dev \
  --distro-version ubuntu/jammy \
  --rootfs-type cli \
  --build-rootfs yes
```

### 示例 2: 构建 XFCE 桌面系统

```bash
sudo ./build.sh \
  --board t527_dev \
  --distro-version debian/bookworm \
  --rootfs-type xfce \
  --apt-mirror https://mirrors.tuna.tsinghua.edu.cn/debian \
  --build-rootfs yes
```

### 示例 3: 仅编译内核并配置

```bash
sudo ./build.sh \
  --board t527_dev \
  --kernel-config menuconfig \
  --kernel-only
```

### 示例 4: 完整构建（内核 + GNOME 桌面）

```bash
sudo ./build.sh \
  --board t527_dev \
  --distro-version ubuntu/noble \
  --rootfs-type gnome \
  --apt-mirror https://mirrors.aliyun.com/ubuntu-ports \
  --build-rootfs yes
```

### 示例 5: 交互式构建

```bash
# 不带任何参数，启动交互界面
sudo ./build.sh
```

---

## 环境变量

可以通过环境变量覆盖默认行为：

```bash
# 设置并行编译线程数
export MAKE_JOBS=8

# 设置输出目录
export OUTPUT_DIR=/path/to/output

# 执行构建
sudo -E ./build.sh --board t527_dev
```

---

## 构建选项组合建议

### 场景 1: 快速测试
```bash
# 最小化系统，最快构建
--distro-version ubuntu/jammy \
--rootfs-type cli \
--apt-mirror https://mirrors.aliyun.com/ubuntu-ports
```

### 场景 2: 开发环境
```bash
# 带开发工具的 CLI 系统
--distro-version debian/bookworm \
--rootfs-type cli \
--apt-mirror https://mirrors.ustc.edu.cn/debian
```

### 场景 3: 桌面体验
```bash
# 轻量级桌面，平衡性能和功能
--distro-version ubuntu/jammy \
--rootfs-type xfce \
--apt-mirror https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports
```

### 场景 4: 完整桌面系统
```bash
# 完整的 GNOME 桌面体验
--distro-version ubuntu/noble \
--rootfs-type gnome \
--apt-mirror https://mirrors.aliyun.com/ubuntu-ports
```

---

## 故障排查

### 查看构建日志

构建过程中的所有输出都会显示在终端。如需保存日志：

```bash
sudo ./build.sh --board t527_dev 2>&1 | tee build.log
```

### 调试模式

启用详细输出：

```bash
# 在脚本开头添加调试
bash -x ./build.sh --board t527_dev
```

### 分步构建

可以单独运行各个构建阶段：

```bash
# 仅获取源码
sudo ./tools/get-sources.sh

# 仅编译内核
cd output/linux
sudo ../../tools/build-kernel.sh

# 仅构建 RootFS
sudo ./tools/build-rootfs.sh -b t527_dev -v ubuntu/jammy -t cli
```

---

## 下一步

- 📖 [RootFS 配置指南](ROOTFS_CONFIG.md) - 定制您的系统
- 📖 [常见问题](FAQ.md) - 解决常见问题
- 📖 [目录结构说明](DIRECTORY_STRUCTURE.md) - 了解项目组织

---

**提示**: 首次构建建议使用交互式模式，熟悉流程后再使用命令行参数。

