# RootFS 配置说明

RootFS 配置文件位于 `rootfs/` 目录。

## 支持的发行版

### Ubuntu

- 20.04 (Focal) - 支持到 2025-04
- 22.04 (Jammy) - 支持到 2027-04（推荐）
- 24.04 (Noble) - 支持到 2029-04

架构：ARM64 (aarch64), ARM32 (armhf)

### Debian

- 11 (Bullseye) - 支持到 2026-06
- 12 (Bookworm) - 支持到 2028-06（推荐）
- 13 (Trixie) - 测试版

架构：ARM64 (arm64), ARM32 (armhf)

## 快速构建

```bash
cd /path/to/BSP_T527/output

# Ubuntu 22.04
sudo bash ../tools/build-rootfs.sh -b example -v ubuntu/jammy -t cli

# Debian 12
sudo bash ../tools/build-rootfs.sh -b example -v debian/bookworm -t cli

# 使用镜像源
sudo bash ../tools/build-rootfs.sh \
    -b example \
    -v ubuntu/jammy \
    -t cli \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

## 系统类型

- CLI - 命令行界面（约 500MB，30-45 分钟）
- XFCE - 轻量桌面（约 2GB，45-60 分钟）
- GNOME - 完整桌面（约 4GB，60-90 分钟）
- KDE - 现代桌面（约 4GB，60-90 分钟）
- LXQt - 超轻桌面（约 1.5GB，40-50 分钟）

## 目录结构

```
rootfs/
├── ubuntu/                 # Ubuntu 发行版
│   ├── focal/
│   ├── jammy/
│   └── noble/
├── debian/                 # Debian 发行版
│   ├── bullseye/
│   ├── bookworm/
│   └── trixie/
├── overlays/               # 系统覆盖文件
│   ├── common/             # 通用配置
│   └── services/           # 系统服务
└── distro-info.yaml       # 发行版信息
```

## 包列表管理

每个发行版的 `packages/base.list` 包含基础系统包。

### 修改包列表

```bash
# 添加包
echo "vim neovim tmux" >> rootfs/ubuntu/jammy/packages/base.list

# 或直接编辑
nano rootfs/ubuntu/jammy/packages/base.list
```

### 包分类

1. 系统核心 - init, systemd, sudo
2. 网络工具 - network-manager, openssh-server
3. 硬件工具 - device-tree-compiler, u-boot-tools
4. 开发工具 - build-essential, git, gcc（可选）
5. 系统工具 - htop, nano, wget, curl

## APT 镜像源

### 使用镜像源

```bash
# Ubuntu 清华镜像
-m https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports

# Debian 中科大镜像
-m https://mirrors.ustc.edu.cn/debian

# Aliyun 镜像
-m https://mirrors.aliyun.com/ubuntu-ports
```

### Ubuntu 源格式

传统格式（Focal/Jammy）：
```
deb http://ports.ubuntu.com/ubuntu-ports jammy main universe
deb http://ports.ubuntu.com/ubuntu-ports jammy-updates main universe
```

DEB822 格式（Noble）：
```
Types: deb
URIs: http://ports.ubuntu.com/ubuntu-ports
Suites: noble noble-updates
Components: main restricted universe multiverse
```

### Debian 源格式

DEB822 格式：
```
Types: deb
URIs: http://deb.debian.org/debian
Suites: bookworm bookworm-updates
Components: main contrib non-free non-free-firmware
```

## Overlays 系统

`overlays/` 目录的文件会在构建时复制到 rootfs。

### common/ - 通用配置

所有发行版通用的配置：

```
overlays/common/
├── etc/
│   ├── sysctl.d/          # 内核参数
│   ├── udev/rules.d/      # 设备规则
│   └── profile.d/         # Shell 环境
├── usr/local/bin/         # 自定义脚本
└── opt/                   # 可选软件
```

添加自定义脚本：

```bash
cat > rootfs/overlays/common/usr/local/bin/my-script.sh <<EOF
#!/bin/bash
echo "Hello BSP"
EOF
chmod +x rootfs/overlays/common/usr/local/bin/my-script.sh
```

### services/ - 系统服务

SystemD 服务配置：

```
overlays/services/
├── init-resize/           # 首次启动分区扩展
│   ├── init-resize.sh
│   └── init-resize.service
└── custom-service/        # 自定义服务
    ├── custom.sh
    └── custom.service
```

添加新服务：

```bash
# 1. 创建服务目录
mkdir -p rootfs/overlays/services/my-service

# 2. 创建服务脚本
cat > rootfs/overlays/services/my-service/my-service.sh <<'EOF'
#!/bin/bash
# Service logic
EOF
chmod +x rootfs/overlays/services/my-service/my-service.sh

# 3. 创建 SystemD 单元
cat > rootfs/overlays/services/my-service/my-service.service <<'EOF'
[Unit]
Description=My Custom Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/my-service.sh

[Install]
WantedBy=multi-user.target
EOF
```

## 添加新发行版

```bash
# 1. 创建目录
mkdir -p rootfs/ubuntu/oracular/{packages,apt-sources}

# 2. 创建包列表
cp rootfs/ubuntu/jammy/packages/base.list \
   rootfs/ubuntu/oracular/packages/base.list

# 3. 配置 APT 源
cat > rootfs/ubuntu/oracular/apt-sources/sources.list <<EOF
deb http://ports.ubuntu.com/ubuntu-ports oracular main universe
EOF

# 4. 更新 distro-info.yaml 和构建脚本
```

## 发行版选择建议

Ubuntu vs Debian：

- 包数量：Ubuntu 更多
- 稳定性：Debian 更稳定
- 更新频率：Ubuntu 更快
- 嵌入式：Debian 更适合
- 桌面：Ubuntu 更适合

推荐：
- 嵌入式设备：Debian Bookworm
- 开发环境：Ubuntu Jammy
- 最新软件：Ubuntu Noble
- 长期支持：Debian Bookworm

## 故障排除

### 包依赖问题

```bash
# 搜索包
apt-cache search package-name

# 查看包信息
apt-cache show package-name
```

### APT 源无法访问

使用国内镜像：

```bash
# 测试镜像
ping mirrors.ustc.edu.cn

# 测试 HTTPS
curl -I https://mirrors.ustc.edu.cn/ubuntu-ports/
```

### 架构不匹配

确保包支持目标架构（arm64/armhf）。

