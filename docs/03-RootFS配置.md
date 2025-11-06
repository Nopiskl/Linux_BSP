# 🗂️ RootFS 配置指南

详细的根文件系统配置和定制说明。

## 📋 目录

- [RootFS 结构](#rootfs-结构)
- [软件包管理](#软件包管理)
- [系统配置](#系统配置)
- [自定义服务](#自定义服务)
- [镜像源配置](#镜像源配置)
- [高级定制](#高级定制)

---

## 📁 RootFS 结构

### 目录组织

```
rootfs/
├── ubuntu/                    # Ubuntu 发行版配置
│   ├── focal/                # 20.04
│   ├── jammy/                # 22.04
│   └── noble/                # 24.04
│       ├── packages/         # 软件包列表
│       │   ├── base.list    # 基础包
│       │   ├── cli.list     # CLI 额外包
│       │   ├── xfce.list    # XFCE 桌面包
│       │   ├── gnome.list   # GNOME 桌面包
│       │   ├── kde.list     # KDE 桌面包
│       │   └── lxqt.list    # LXQt 桌面包
│       └── apt-sources/      # APT 源配置
│           └── sources.list
│
├── debian/                    # Debian 发行版配置
│   ├── bullseye/             # Debian 11
│   ├── bookworm/             # Debian 12
│   └── trixie/               # Debian Testing
│       └── (同 Ubuntu 结构)
│
└── overlays/                  # 系统叠加层
    ├── common/               # 通用配置文件
    │   ├── etc/
    │   ├── usr/
    │   └── ...
    └── services/             # 系统服务
        ├── init-resize/      # 首次启动自动扩展分区
        └── ...
```

---

## 📦 软件包管理

### 软件包列表文件

每个发行版版本都有自己的软件包列表，位于 `packages/` 目录：

#### base.list - 基础软件包

所有系统类型都会安装的核心包。

```bash
vim rootfs/ubuntu/jammy/packages/base.list
```

**默认包含：**
```
# 系统基础
systemd
systemd-sysv
udev
kmod
sudo

# 网络工具
net-tools
iputils-ping
iproute2
ifupdown
dhcpcd5

# 文本编辑
nano
vim-tiny

# 系统工具
wget
curl
ca-certificates
tzdata
locales

# 必要库
libc6
libssl3
```

#### cli.list - CLI 额外包

命令行系统的额外工具。

```bash
vim rootfs/ubuntu/jammy/packages/cli.list
```

**推荐添加：**
```
# 系统监控
htop
iotop
lsof

# 开发工具
git
build-essential
python3
python3-pip

# 文件管理
rsync
tree
unzip
zip

# 网络工具
openssh-server
openssh-client
```

#### xfce.list - XFCE 桌面包

轻量级桌面环境。

```bash
vim rootfs/ubuntu/jammy/packages/xfce.list
```

**包含内容：**
```
# XFCE 核心
xfce4
xfce4-goodies
xfce4-terminal

# 显示管理器
lightdm
lightdm-gtk-greeter

# 应用程序
firefox-esr
thunar
mousepad
xarchiver

# 字体
fonts-wqy-zenhei
fonts-wqy-microhei
```

#### gnome.list - GNOME 桌面包

完整的现代桌面环境。

```bash
vim rootfs/ubuntu/jammy/packages/gnome.list
```

**包含内容：**
```
# GNOME 核心
gnome-core
gnome-session
gnome-terminal
gdm3

# 办公套件
libreoffice
libreoffice-l10n-zh-cn

# 多媒体
rhythmbox
totem
eog

# 浏览器
firefox
```

### 添加自定义软件包

#### 方法 1：编辑列表文件

```bash
# 1. 编辑对应的包列表
vim rootfs/ubuntu/jammy/packages/cli.list

# 2. 添加包名（每行一个）
docker.io
nodejs
nginx

# 3. 保存后重新构建
sudo ./build.sh -b example -v ubuntu/jammy -t cli -r yes
```

#### 方法 2：使用脚本批量添加

```bash
# 创建自定义包列表
cat >> rootfs/ubuntu/jammy/packages/cli.list << 'EOF'
# 容器工具
docker.io
docker-compose

# Web 服务
nginx
apache2

# 数据库
mariadb-server
redis-server

# 开发语言
nodejs
npm
golang-go
EOF

# 重新构建
sudo ./build.sh -b example -v ubuntu/jammy -t cli -r yes
```

### 删除不需要的软件包

```bash
# 编辑列表文件
vim rootfs/ubuntu/jammy/packages/base.list

# 注释掉不需要的包（添加 # 号）
# vim-tiny      # 如果不需要 vim
# wget          # 如果只用 curl

# 或直接删除对应行
```

### 查找可用软件包

```bash
# Ubuntu
apt-cache search <package-name>

# 示例：搜索 Python 相关包
apt-cache search python3 | grep python3-

# 查看包详情
apt-cache show <package-name>
```

---

## ⚙️ 系统配置

### 配置文件叠加层

`overlays/` 目录中的文件会在构建时复制到 RootFS 中。

#### 结构示例

```
overlays/
└── common/
    ├── etc/
    │   ├── hostname              # 主机名
    │   ├── hosts                 # hosts 文件
    │   ├── fstab                 # 文件系统表
    │   ├── network/
    │   │   └── interfaces        # 网络配置
    │   └── systemd/
    │       └── system/
    │           └── custom.service
    ├── usr/
    │   └── local/
    │       └── bin/
    │           └── custom-script.sh
    └── root/
        └── .bashrc               # root 用户配置
```

### 常用配置示例

#### 1. 设置主机名

```bash
# 创建 hostname 文件
mkdir -p rootfs/overlays/common/etc
echo "t527-board" > rootfs/overlays/common/etc/hostname
```

#### 2. 配置静态 IP

```bash
# 创建网络配置
mkdir -p rootfs/overlays/common/etc/network

cat > rootfs/overlays/common/etc/network/interfaces << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 114.114.114.114
EOF
```

#### 3. 配置自动挂载

```bash
# 编辑 fstab
cat > rootfs/overlays/common/etc/fstab << 'EOF'
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
/dev/mmcblk0p1  /boot           vfat    defaults        0       2
/dev/mmcblk0p2  /               ext4    defaults        0       1
tmpfs           /tmp            tmpfs   defaults        0       0
EOF
```

#### 4. 添加用户配置

```bash
# 创建用户配置脚本
mkdir -p rootfs/overlays/common/usr/local/bin

cat > rootfs/overlays/common/usr/local/bin/setup-user.sh << 'EOF'
#!/bin/bash
# 创建默认用户
useradd -m -G sudo -s /bin/bash user
echo "user:password" | chpasswd
EOF

chmod +x rootfs/overlays/common/usr/local/bin/setup-user.sh
```

#### 5. 配置时区和语言

```bash
# 创建配置脚本
cat > rootfs/overlays/common/usr/local/bin/setup-locale.sh << 'EOF'
#!/bin/bash
# 设置时区
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 设置语言
locale-gen zh_CN.UTF-8
update-locale LANG=zh_CN.UTF-8
EOF

chmod +x rootfs/overlays/common/usr/local/bin/setup-locale.sh
```

---

## 🔧 自定义服务

### 创建 Systemd 服务

项目已包含 `init-resize` 服务作为示例，用于首次启动时自动扩展根分区。

#### 位置

```
rootfs/overlays/services/init-resize/
├── init-resize.sh              # 脚本
└── init-resize.service         # Systemd 单元文件
```

#### 服务脚本示例

```bash
# rootfs/overlays/services/init-resize/init-resize.sh
#!/bin/bash

# 首次启动扩展根分区
resize_rootfs() {
    ROOT_PART=$(findmnt -n -o SOURCE /)
    ROOT_DEV=$(lsblk -no pkname ${ROOT_PART})
    
    # 扩展分区
    growpart /dev/${ROOT_DEV} 2
    resize2fs ${ROOT_PART}
    
    # 禁用服务
    systemctl disable init-resize
}

resize_rootfs
```

#### Systemd 单元文件

```ini
# rootfs/overlays/services/init-resize/init-resize.service
[Unit]
Description=Resize root filesystem on first boot
After=local-fs.target
Before=basic.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/init-resize.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

### 添加新服务

#### 1. 创建服务目录

```bash
mkdir -p rootfs/overlays/services/my-service
```

#### 2. 创建服务脚本

```bash
cat > rootfs/overlays/services/my-service/my-service.sh << 'EOF'
#!/bin/bash
# 你的服务逻辑
echo "Service started at $(date)" >> /var/log/my-service.log
EOF

chmod +x rootfs/overlays/services/my-service/my-service.sh
```

#### 3. 创建 Systemd 单元

```bash
cat > rootfs/overlays/services/my-service/my-service.service << 'EOF'
[Unit]
Description=My Custom Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/my-service.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
```

#### 4. 在构建脚本中注册服务

编辑 `tools/build-rootfs.sh`，在 `setup_firstrun()` 函数中添加：

```bash
# 安装自定义服务
if [ -d "${OVERLAY_BASE}/services/my-service" ]; then
    cp "${OVERLAY_BASE}/services/my-service/my-service.sh" \
       "${ROOTFS}/usr/local/bin/"
    chmod +x "${ROOTFS}/usr/local/bin/my-service.sh"
    
    cp "${OVERLAY_BASE}/services/my-service/my-service.service" \
       "${ROOTFS}/etc/systemd/system/"
    
    chroot ${ROOTFS} systemctl enable my-service
fi
```

---

## 🌐 镜像源配置

### APT 源文件

#### Ubuntu 源

```bash
# rootfs/ubuntu/jammy/apt-sources/sources.list
deb http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse
```

#### Debian 源

```bash
# rootfs/debian/bookworm/apt-sources/sources.list
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
```

### 使用国内镜像

#### 阿里云镜像（推荐）

**Ubuntu:**
```bash
deb http://mirrors.aliyun.com/ubuntu-ports jammy main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports jammy-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu-ports jammy-security main restricted universe multiverse
```

**Debian:**
```bash
deb http://mirrors.aliyun.com/debian bookworm main contrib non-free non-free-firmware
deb http://mirrors.aliyun.com/debian bookworm-updates main contrib non-free non-free-firmware
deb http://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free non-free-firmware
```

#### 清华镜像

**Ubuntu:**
```bash
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports jammy main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports jammy-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports jammy-security main restricted universe multiverse
```

#### 中科大镜像

**Ubuntu:**
```bash
deb https://mirrors.ustc.edu.cn/ubuntu-ports jammy main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu-ports jammy-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu-ports jammy-security main restricted universe multiverse
```

---

## 🎨 高级定制

### 自定义内核模块

```bash
# 1. 在 overlays 中准备内核模块
mkdir -p rootfs/overlays/common/lib/modules

# 2. 复制自定义模块
cp your-module.ko rootfs/overlays/common/lib/modules/

# 3. 创建加载配置
echo "your-module" > rootfs/overlays/common/etc/modules-load.d/custom.conf
```

### 预装 Docker

```bash
# 1. 添加 Docker 到包列表
echo "docker.io" >> rootfs/ubuntu/jammy/packages/cli.list

# 2. 配置 Docker 服务自启动
mkdir -p rootfs/overlays/common/etc/systemd/system/multi-user.target.wants
ln -s /lib/systemd/system/docker.service \
      rootfs/overlays/common/etc/systemd/system/multi-user.target.wants/
```

### 添加自定义仓库

```bash
# 1. 添加 GPG 密钥
mkdir -p rootfs/overlays/common/usr/share/keyrings

# 2. 添加源列表
cat > rootfs/overlays/common/etc/apt/sources.list.d/custom.list << 'EOF'
deb [signed-by=/usr/share/keyrings/custom.gpg] https://custom-repo.com/ubuntu jammy main
EOF
```

### 修改默认配置

```bash
# 修改 SSH 配置
mkdir -p rootfs/overlays/common/etc/ssh
cat > rootfs/overlays/common/etc/ssh/sshd_config.d/custom.conf << 'EOF'
PermitRootLogin yes
PasswordAuthentication yes
EOF

# 修改 sudo 配置
mkdir -p rootfs/overlays/common/etc/sudoers.d
echo "user ALL=(ALL) NOPASSWD:ALL" > rootfs/overlays/common/etc/sudoers.d/user
chmod 0440 rootfs/overlays/common/etc/sudoers.d/user
```

### 清理不需要的文件

在 `tools/build-rootfs.sh` 的 `clean_rootfs()` 函数中添加：

```bash
# 清理文档
rm -rf ${ROOTFS}/usr/share/doc/*
rm -rf ${ROOTFS}/usr/share/man/*

# 清理缓存
rm -rf ${ROOTFS}/var/cache/apt/*
rm -rf ${ROOTFS}/tmp/*

# 清理日志
rm -rf ${ROOTFS}/var/log/*
```

---

## 🧪 测试和验证

### 检查软件包列表

```bash
# 验证包列表语法
cat rootfs/ubuntu/jammy/packages/base.list | grep -v "^#" | grep -v "^$"
```

### 验证 Overlay 文件

```bash
# 检查文件权限
find rootfs/overlays -type f -ls

# 检查脚本语法
for script in $(find rootfs/overlays -name "*.sh"); do
    bash -n "$script" && echo "✓ $script" || echo "✗ $script"
done
```

### 构建测试

```bash
# 构建并验证
sudo ./build.sh -b example -v ubuntu/jammy -t cli -r yes

# 检查构建产物
tar -tzf output/rootfs-ubuntu-jammy-cli.tar.gz | head -20
```

---

## 📊 配置对比

| 系统类型 | 软件包数量 | 磁盘占用 | 构建时间 | 适用场景 |
|---------|----------|---------|---------|---------|
| CLI | ~300 | ~500MB | 30-45分钟 | 服务器、嵌入式 |
| XFCE | ~800 | ~2GB | 45-60分钟 | 轻量桌面、开发 |
| GNOME | ~1200 | ~4GB | 60-90分钟 | 完整桌面体验 |
| KDE | ~1000 | ~4GB | 60-90分钟 | 现代化界面 |
| LXQt | ~600 | ~1.5GB | 40-50分钟 | 低性能设备 |

---

## 📖 相关文档

- 📘 [构建指南](./02-构建指南.md) - 完整构建流程
- 📗 [常见问题](./04-常见问题.md) - 问题排查
- 📙 [目录结构](./05-目录结构.md) - 项目文件说明

---

## 💡 最佳实践

1. **模块化管理** - 将配置按功能分类到不同文件
2. **版本控制** - 使用 Git 跟踪配置变更
3. **充分测试** - 修改后及时构建验证
4. **文档记录** - 记录自定义配置的目的和用法
5. **备份重要** - 保留工作配置的备份

---

## 🎉 开始定制

现在你可以根据需求定制自己的 RootFS 了！

**建议步骤：**
1. 从 CLI 系统开始
2. 添加必要的软件包
3. 配置网络和服务
4. 测试验证功能
5. 构建最终系统

---

<div align="center">

**作者：Nopiskl** | [返回文档中心](./README.md)

</div>
