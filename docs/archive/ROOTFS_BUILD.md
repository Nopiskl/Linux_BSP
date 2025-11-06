# RootFS 构建指南

本文档说明如何使用 BSP_T527 框架构建根文件系统。

## 快速开始

### 1. 准备环境

```bash
# 安装依赖
sudo apt-get update
sudo apt-get install -y \
    debootstrap \
    mmdebstrap \
    qemu-user-static \
    binfmt-support

# 验证安装
which mmdebstrap
```

### 2. 构建最小系统（CLI）

```bash
cd /home/nopiskl/T527/BSP/BSP_T527/output

# 使用默认配置（Ubuntu 22.04 Jammy）
sudo bash ../tools/build-rootfs.sh -b example -v jammy -t cli

# 使用国内镜像加速（推荐）
sudo bash ../tools/build-rootfs.sh -b example -v jammy -t cli \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

### 3. 构建桌面系统（可选）

需要先创建桌面包列表：

```bash
# 创建 XFCE 包列表
cat > os/jammy/xfce-packages.list <<EOF
xfce4 xfce4-goodies xfce4-terminal lightdm lightdm-gtk-greeter \
firefox-esr thunar-archive-plugin xarchiver network-manager-gnome \
pulseaudio pavucontrol gvfs-backends
EOF

# 构建 XFCE 桌面系统
sudo bash ../tools/build-rootfs.sh -b example -v jammy -t xfce \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

## 构建选项详解

### 命令行参数

| 参数 | 简写 | 说明 | 示例 |
|------|------|------|------|
| `--board` | `-b` | 板型名称 | `-b example` |
| `--version` | `-v` | OS 版本 | `-v jammy` |
| `--type` | `-t` | 系统类型 | `-t cli` |
| `--mirror` | `-m` | 镜像源 URL | `-m https://...` |
| `--rootfs` | `-r` | 输出目录名 | `-r rootfs` |
| `--help` | `-h` | 显示帮助 | `-h` |

### 支持的 OS 版本

#### Ubuntu

| 版本代号 | Ubuntu 版本 | 架构支持 | 推荐度 |
|----------|-------------|----------|--------|
| `jammy` | 22.04 LTS | arm64, armhf | ⭐⭐⭐⭐⭐ |
| `noble` | 24.04 LTS | arm64, armhf | ⭐⭐⭐⭐ |
| `focal` | 20.04 LTS | arm64, armhf | ⭐⭐⭐ |

#### Debian

| 版本代号 | Debian 版本 | 架构支持 | 推荐度 |
|----------|-------------|----------|--------|
| `bookworm` | 12 | arm64, armhf | ⭐⭐⭐⭐⭐ |
| `trixie` | 13 (testing) | arm64, armhf | ⭐⭐⭐ |
| `bullseye` | 11 | arm64, armhf | ⭐⭐⭐ |

### 系统类型

| 类型 | 说明 | 大小（约） | 用途 |
|------|------|-----------|------|
| `cli` | 命令行界面 | 500MB | 服务器、嵌入式 |
| `xfce` | XFCE 桌面 | 2-3GB | 轻量桌面 |
| `gnome` | GNOME 桌面 | 4-5GB | 完整桌面体验 |
| `kde` | KDE Plasma | 4-5GB | 现代桌面 |
| `lxqt` | LXQt 桌面 | 1-2GB | 超轻量桌面 |

## 镜像源配置

### 中国大陆镜像（推荐）

#### Ubuntu Ports

```bash
# 清华大学
-m https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports

# 中国科学技术大学
-m https://mirrors.ustc.edu.cn/ubuntu-ports

# 阿里云
-m https://mirrors.aliyun.com/ubuntu-ports

# 华为云
-m https://mirrors.huaweicloud.com/ubuntu-ports
```

#### Debian

```bash
# 清华大学
-m https://mirrors.tuna.tsinghua.edu.cn/debian

# 中国科学技术大学
-m https://mirrors.ustc.edu.cn/debian

# 阿里云
-m https://mirrors.aliyun.com/debian
```

### 国际镜像

```bash
# Ubuntu 官方
-m http://ports.ubuntu.com/ubuntu-ports

# Debian 官方
-m http://deb.debian.org/debian
```

## 高级配置

### 自定义包列表

#### 添加基础包

编辑 `os/jammy/base-packages.list`：

```bash
nano os/jammy/base-packages.list

# 在文件末尾添加需要的包
vim git python3 python3-pip nodejs npm docker.io
```

#### 创建自定义配置

```bash
# 复制并修改
cp os/jammy/base-packages.list os/jammy/base-packages-custom.list
nano os/jammy/base-packages-custom.list
```

修改脚本使用自定义列表：
```bash
BASE_PKGS_FILE="${BASE_DIR}/os/${VERSION}/base-packages-custom.list"
```

### 预安装内核包

在构建脚本中添加内核包安装：

```bash
# 在 setup_firstrun() 之前添加
install_kernel_packages(){
    local kernel_pkg_dir="${WORKSPACE}/example-kernel-pkgs"
    
    if [ -d "${kernel_pkg_dir}" ]; then
        echo "Installing kernel packages..."
        for deb in ${kernel_pkg_dir}/*.deb; do
            cp "${deb}" ${ROOTFS}/tmp/
            chroot ${ROOTFS} dpkg -i /tmp/$(basename ${deb})
            rm ${ROOTFS}/tmp/$(basename ${deb})
        done
    fi
}
```

### 配置用户和密码

在构建脚本的 `setup_hostname_fstab()` 后添加：

```bash
# 创建默认用户
setup_users(){
    echo "Creating users..."
    
    # 创建普通用户
    chroot ${ROOTFS} useradd -m -s /bin/bash bsp
    echo "bsp:bsp123" | chroot ${ROOTFS} chpasswd
    chroot ${ROOTFS} usermod -aG sudo bsp
    
    # 设置 root 密码
    echo "root:root123" | chroot ${ROOTFS} chpasswd
    
    echo "Users created:"
    echo "  User: bsp / Password: bsp123"
    echo "  Root: root / Password: root123"
}
```

### 启用/禁用服务

```bash
# 在 chroot 环境中操作
setup_services(){
    echo "Configuring services..."
    
    # 启用服务
    chroot ${ROOTFS} systemctl enable ssh
    chroot ${ROOTFS} systemctl enable network-manager
    
    # 禁用不需要的服务
    chroot ${ROOTFS} systemctl disable bluetooth
    chroot ${ROOTFS} systemctl mask snapd
}
```

### 添加自定义脚本

创建 post-install 脚本：

```bash
cat > target/scripts/post-install.sh <<'EOF'
#!/bin/bash
# 自定义配置脚本

# 设置时区
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 配置语言
echo "LANG=zh_CN.UTF-8" > /etc/default/locale

# 添加自定义配置
echo "Custom configuration completed"
EOF

chmod +x target/scripts/post-install.sh
```

在构建脚本中调用：

```bash
# 复制并执行
cp target/scripts/post-install.sh ${ROOTFS}/tmp/
chroot ${ROOTFS} /tmp/post-install.sh
rm ${ROOTFS}/tmp/post-install.sh
```

## 构建流程详解

### 完整构建过程

```
1. run_debootstrap()
   ├─ 检测 OS 版本和架构
   ├─ 读取包列表
   ├─ 调用 mmdebstrap 创建基础系统
   └─ 安装基础包和桌面包

2. prepare_apt_sources()
   ├─ 配置 APT 源列表
   └─ 替换镜像 URL

3. setup_mount_resolv()
   ├─ 挂载 /dev, /proc, /sys
   └─ 复制 resolv.conf

4. setup_dhcp()
   └─ 板级网络配置（从 board.conf 覆盖）

5. setup_firstrun()
   ├─ 安装分区扩展服务
   └─ 配置 SSH

6. clean_rootfs()
   ├─ 清理 APT 缓存
   └─ 删除 QEMU 静态文件

7. setup_hostname_fstab()
   ├─ 设置主机名
   ├─ 配置 /etc/hosts
   ├─ 配置 fstab
   └─ 添加 sudo 权限

8. umount_all()
   └─ 卸载所有挂载点

9. 打包
   ├─ 重命名目录
   ├─ 创建 tar.gz
   └─ 清理临时文件
```

### 首次启动流程

系统首次启动时会自动：

1. **分区扩展** (`init-resize.service`)
   - 检测磁盘剩余空间
   - 扩展根分区到磁盘末尾
   - 调整文件系统大小
   - 禁用自身服务

2. **网络配置**
   - NetworkManager 自动启动
   - 尝试 DHCP 获取 IP

3. **SSH 服务**
   - 自动生成 host keys
   - 开启远程登录

## 输出文件

构建成功后生成：

```
output/
└── rootfs-jammy-cli.tar.gz    # 约 500MB (CLI) 或 2-5GB (桌面)
```

### 解压和使用

```bash
# 解压到目标设备
sudo tar -xzvf rootfs-jammy-cli.tar.gz -C /mnt/rootfs/

# 或解压到镜像
sudo mount /dev/sdX2 /mnt
sudo tar -xzvf rootfs-jammy-cli.tar.gz -C /mnt/
sudo umount /mnt
```

## 故障排除

### mmdebstrap: command not found

```bash
sudo apt-get install mmdebstrap
```

### Cannot find /usr/bin/qemu-aarch64-static

```bash
sudo apt-get install qemu-user-static binfmt-support
```

### E: Failed to fetch packages

**问题**: 网络连接或镜像源问题

**解决方案**:
1. 检查网络连接
2. 使用国内镜像源
3. 临时禁用代理: `unset http_proxy https_proxy`

### Space not enough

**问题**: 磁盘空间不足

**解决方案**:
1. 清理不需要的文件: `sudo apt-get clean`
2. 删除旧的构建: `rm -rf output/rootfs-*`
3. 增加磁盘空间

### Permission denied

**问题**: 权限不足

**解决方案**:
```bash
# 必须使用 sudo
sudo bash ../tools/build-rootfs.sh -b example -v jammy -t cli
```

## 性能优化

### 使用本地缓存

```bash
# 创建 APT 缓存目录
sudo mkdir -p /var/cache/apt-build

# 配置 mmdebstrap 使用缓存
export APT_CACHE=/var/cache/apt-build
```

### 并行下载

编辑 `/etc/apt/apt.conf.d/99parallel`:

```
Acquire::Queue-Mode "host";
Acquire::http::Pipeline-Depth "5";
```

### 减小镜像大小

删除不必要的包：

```bash
# 在 clean_rootfs() 中添加
chroot ${ROOTFS} apt-get autoremove --purge -y
chroot ${ROOTFS} apt-get clean
rm -rf ${ROOTFS}/usr/share/doc/*
rm -rf ${ROOTFS}/usr/share/man/*
rm -rf ${ROOTFS}/var/log/*
```

## 参考资料

- [Debootstrap 文档](https://wiki.debian.org/Debootstrap)
- [mmdebstrap 手册](https://manpages.debian.org/mmdebstrap)
- [Ubuntu Ports](https://wiki.ubuntu.com/ARM)
- [Debian ARM](https://www.debian.org/ports/arm/)

## 下一步

构建完成后，可以：

1. [打包为镜像](PACK.md)
2. [刷写到 SD 卡](FLASH.md)
3. [配置网络和服务](CONFIG.md)

