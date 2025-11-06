# RootFS 配置目录

此目录包含所有 Linux 发行版的配置文件、包列表和系统覆盖文件。

## 📁 目录结构

```
rootfs/
├── ubuntu/                    # Ubuntu 发行版
│   ├── focal/                 # Ubuntu 20.04 LTS
│   │   ├── packages/
│   │   │   └── base.list     # 基础包列表
│   │   └── apt-sources/
│   │       └── sources.list   # APT 源配置
│   ├── jammy/                 # Ubuntu 22.04 LTS ⭐推荐
│   │   ├── packages/
│   │   │   └── base.list
│   │   └── apt-sources/
│   │       └── sources.list
│   └── noble/                 # Ubuntu 24.04 LTS
│       ├── packages/
│       │   └── base.list
│       └── apt-sources/
│           └── ubuntu.sources # DEB822 格式
│
├── debian/                    # Debian 发行版
│   ├── bullseye/              # Debian 11
│   │   ├── packages/
│   │   │   └── base.list
│   │   └── apt-sources/
│   │       └── debian.sources
│   ├── bookworm/              # Debian 12 ⭐推荐
│   │   ├── packages/
│   │   │   └── base.list
│   │   └── apt-sources/
│   │       └── debian.sources
│   └── trixie/                # Debian 13 (Testing)
│       ├── packages/
│       │   └── base.list
│       └── apt-sources/
│           └── debian.sources
│
├── overlays/                  # 系统覆盖文件
│   ├── common/                # 通用配置（所有发行版）
│   │   ├── etc/              # 系统配置文件
│   │   ├── usr/              # 用户程序
│   │   └── opt/              # 可选软件
│   └── services/              # 系统服务
│       └── init-resize/       # 首次启动分区扩展
│           ├── init-resize.sh
│           └── init-resize.service
│
├── scripts/                   # 辅助脚本
│   └── (预留)
│
├── distro-info.yaml          # 发行版信息
└── README.md                  # 本文件
```

## 🎯 支持的发行版

### Ubuntu (推荐用于嵌入式开发)

| 版本 | 代号 | 发布日期 | LTS | EOL | 推荐 |
|------|------|----------|-----|-----|------|
| 20.04 | Focal | 2020-04 | ✅ | 2025-04 | ⚪ |
| 22.04 | Jammy | 2022-04 | ✅ | 2027-04 | ⭐⭐⭐ |
| 24.04 | Noble | 2024-04 | ✅ | 2029-04 | ⭐⭐ |

**架构支持**: ARM64 (aarch64), ARM32 (armhf)

**推荐理由**:
- ⭐⭐⭐ Jammy (22.04): 稳定、包全、文档丰富，最适合生产环境
- ⭐⭐ Noble (24.04): 最新 LTS，更新的软件包
- ⚪ Focal (20.04): 较旧但稳定，即将 EOL

### Debian (推荐用于服务器)

| 版本 | 代号 | 发布日期 | 状态 | EOL | 推荐 |
|------|------|----------|------|-----|------|
| 11 | Bullseye | 2021-08 | Stable | 2026-06 | ⚪ |
| 12 | Bookworm | 2023-06 | Stable | 2028-06 | ⭐⭐⭐ |
| 13 | Trixie | TBD | Testing | - | ⚪ |

**架构支持**: ARM64 (arm64), ARM32 (armhf)

**推荐理由**:
- ⭐⭐⭐ Bookworm (12): 当前稳定版，长期支持
- ⚪ Bullseye (11): 较旧但稳定
- ⚪ Trixie (13): 测试版，不建议生产环境

## 📦 包列表说明

### base.list - 基础系统包

每个发行版的 `packages/base.list` 包含最小可用系统所需的包。

**包分类**:

1. **系统核心** (必需)
   - `init`, `systemd`, `systemd-resolved`
   - `sudo`, `rsyslog`, `cron`

2. **网络工具**
   - `network-manager`, `openssh-server`
   - `netplan.io`, `wireless-tools`, `wpasupplicant`

3. **硬件工具**
   - `device-tree-compiler`, `u-boot-tools`
   - `i2c-tools`, `mmc-utils`, `gpiod`

4. **开发工具** (可选，但推荐)
   - `build-essential`, `git`, `flex`, `bison`
   - `gcc`, `make`, `autoconf`

5. **系统工具**
   - `htop`, `nano`, `rsync`, `wget`, `curl`
   - `parted`, `fdisk`, `dosfstools`

### desktop.list - 桌面环境包（可扩展）

可以为每个发行版添加桌面包列表：

```bash
# 示例：创建 XFCE 桌面包列表
cat > rootfs/ubuntu/jammy/packages/desktop-xfce.list <<EOF
xfce4 xfce4-goodies lightdm firefox
EOF
```

## 🔧 APT 源配置

### Ubuntu 源格式

**Focal/Jammy** (传统 sources.list):
```
deb http://ports.ubuntu.com/ubuntu-ports jammy main universe
deb http://ports.ubuntu.com/ubuntu-ports jammy-updates main universe
```

**Noble** (DEB822 格式):
```
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports
Suites: noble noble-updates
Components: main restricted universe multiverse
```

### Debian 源格式

统一使用 DEB822 格式 (`debian.sources`):
```
Types: deb
URIs: http://deb.debian.org/debian
Suites: bookworm bookworm-updates
Components: main contrib non-free non-free-firmware
```

### 镜像源替换

构建时可以指定镜像源：

```bash
# Ubuntu 清华镜像
-m https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports

# Debian 中科大镜像
-m https://mirrors.ustc.edu.cn/debian
```

## 🎨 Overlays 系统

`overlays/` 目录用于存放系统覆盖文件，会在构建时复制到 rootfs。

### common/ - 通用配置

所有发行版通用的配置文件：

```
overlays/common/
├── etc/
│   ├── sysctl.d/          # 内核参数
│   ├── udev/rules.d/      # 设备规则
│   └── profile.d/         # Shell 环境
├── usr/
│   ├── local/bin/         # 自定义脚本
│   └── share/            # 共享资源
└── opt/                   # 可选软件
```

**使用方法**:
```bash
# 添加自定义脚本
cat > overlays/common/usr/local/bin/my-script.sh <<EOF
#!/bin/bash
echo "Hello BSP"
EOF
chmod +x overlays/common/usr/local/bin/my-script.sh
```

### services/ - 系统服务

SystemD 服务配置：

```
overlays/services/
├── init-resize/           # 首次启动分区扩展
│   ├── init-resize.sh     # 扩展脚本
│   └── init-resize.service # SystemD 服务
├── custom-service/        # 自定义服务
│   ├── custom.sh
│   └── custom.service
└── ...
```

**添加新服务**:
```bash
# 1. 创建服务目录
mkdir -p overlays/services/my-service

# 2. 创建服务脚本
cat > overlays/services/my-service/my-service.sh <<'EOF'
#!/bin/bash
# Your service logic
EOF

# 3. 创建 SystemD 单元
cat > overlays/services/my-service/my-service.service <<'EOF'
[Unit]
Description=My Custom Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/my-service.sh

[Install]
WantedBy=multi-user.target
EOF

# 4. 在构建脚本中启用服务
```

## 🔨 自定义配置

### 添加新发行版

1. **创建目录结构**:
```bash
mkdir -p rootfs/ubuntu/oracular/{packages,apt-sources}
```

2. **创建包列表**:
```bash
cat > rootfs/ubuntu/oracular/packages/base.list <<EOF
# 复制并修改其他版本的包列表
EOF
```

3. **配置 APT 源**:
```bash
cat > rootfs/ubuntu/oracular/apt-sources/sources.list <<EOF
deb http://ports.ubuntu.com/ubuntu-ports oracular main universe
EOF
```

4. **更新 distro-info.yaml**

5. **更新构建脚本** (`tools/build-rootfs.sh`)

### 修改包列表

直接编辑对应的 `base.list` 文件：

```bash
# 添加包
echo "vim neovim tmux" >> rootfs/ubuntu/jammy/packages/base.list

# 或完全自定义
nano rootfs/ubuntu/jammy/packages/base.list
```

### 板级特定配置

为特定板卡添加配置：

```bash
# 创建板级覆盖
mkdir -p overlays/boards/t527

# 添加板级文件
cat > overlays/boards/t527/etc/network/interfaces <<EOF
# T527 specific network config
EOF
```

## 📊 版本对比

| 特性 | Ubuntu | Debian | 推荐 |
|------|--------|--------|------|
| 包数量 | 更多 | 适中 | Ubuntu |
| 稳定性 | 稳定 | 非常稳定 | Debian |
| 更新频率 | 快 | 慢 | Ubuntu |
| ARM 支持 | 优秀 | 优秀 | 平手 |
| 文档 | 丰富 | 丰富 | 平手 |
| 嵌入式 | 适合 | 很适合 | Debian |
| 桌面 | 很适合 | 适合 | Ubuntu |

**选择建议**:
- **嵌入式设备**: Debian Bookworm
- **开发环境**: Ubuntu Jammy
- **最新软件**: Ubuntu Noble
- **超长期支持**: Debian Bookworm

## 🚀 使用方法

### 构建根文件系统

```bash
cd /path/to/BSP_T527/output

# Ubuntu 22.04
sudo bash ../tools/build-rootfs.sh -b example -v ubuntu/jammy -t cli

# Debian 12
sudo bash ../tools/build-rootfs.sh -b example -v debian/bookworm -t cli
```

### 使用镜像源

```bash
# 中国镜像
sudo bash ../tools/build-rootfs.sh \
    -b example \
    -v ubuntu/jammy \
    -t cli \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

## 📖 相关文档

- [构建详细指南](../ROOTFS_BUILD.md)
- [快速开始](../QUICKSTART_ROOTFS.md)
- [工具使用](../tools/README.md)
- [发行版信息](distro-info.yaml)

## 🐛 故障排除

### 包依赖问题

检查包列表中的包名是否正确，是否在目标发行版中可用：

```bash
# 搜索包
apt-cache search package-name

# 查看包信息
apt-cache show package-name
```

### APT 源无法访问

使用国内镜像或检查网络：

```bash
# 测试镜像
ping mirrors.ustc.edu.cn

# 测试 HTTPS
curl -I https://mirrors.ustc.edu.cn/ubuntu-ports/
```

### 架构不匹配

确保选择的包支持目标架构 (arm64/armhf)。

## 🔄 迁移指南

### 从旧版本 (os/) 迁移

旧结构：
```
os/jammy/base-packages.list
```

新结构：
```
rootfs/ubuntu/jammy/packages/base.list
```

更新构建脚本中的路径即可。

---

**更新日期**: 2025-11-06
**维护**: BSP_T527 Project
**许可**: GPL-3.0

