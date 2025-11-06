# RootFS 构建快速开始

## 🚀 5 分钟快速构建

### 步骤 1: 安装依赖（仅需一次）

```bash
sudo apt-get update
sudo apt-get install -y mmdebstrap debootstrap qemu-user-static
```

### 步骤 2: 构建根文件系统

```bash
cd /home/nopiskl/T527/BSP/BSP_T527/output

# 使用国内镜像（推荐）
sudo bash ../tools/build-rootfs.sh \
    -b example \
    -v jammy \
    -t cli \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

### 步骤 3: 等待完成

构建时间：约 10-30 分钟（取决于网络速度）

输出文件：`rootfs-jammy-cli.tar.gz` (约 500MB)

## 📋 完整构建示例

### Ubuntu 22.04 最小系统

```bash
cd output
sudo bash ../tools/build-rootfs.sh -b example -v jammy -t cli \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

### Debian 12 最小系统

```bash
cd output
sudo bash ../tools/build-rootfs.sh -b example -v bookworm -t cli \
    -m https://mirrors.ustc.edu.cn/debian
```

## 🎯 使用不同镜像源

### 清华大学镜像

```bash
# Ubuntu
-m https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports

# Debian
-m https://mirrors.tuna.tsinghua.edu.cn/debian
```

### 中科大镜像

```bash
# Ubuntu
-m https://mirrors.ustc.edu.cn/ubuntu-ports

# Debian
-m https://mirrors.ustc.edu.cn/debian
```

### 阿里云镜像

```bash
# Ubuntu
-m https://mirrors.aliyun.com/ubuntu-ports

# Debian
-m https://mirrors.aliyun.com/debian
```

## ⚠️ 常见问题

### Q1: mmdebstrap: command not found

```bash
sudo apt-get install mmdebstrap
```

### Q2: Permission denied

必须使用 `sudo` 运行：

```bash
sudo bash ../tools/build-rootfs.sh -b example -v jammy -t cli
```

### Q3: 网络连接失败

使用国内镜像源：

```bash
-m https://mirrors.ustc.edu.cn/ubuntu-ports
```

### Q4: 磁盘空间不足

需要至少 10GB 可用空间。清理旧文件：

```bash
rm -rf output/rootfs-*
sudo apt-get clean
```

## 📖 详细文档

- [完整构建指南](ROOTFS_BUILD.md)
- [工具使用说明](tools/README.md)
- [OS 配置文档](os/README.md)

## 🎉 构建成功后

输出文件可用于：

1. 刷写到 SD 卡
2. 打包为系统镜像
3. 部署到目标设备

示例使用：

```bash
# 解压到 SD 卡第二分区
sudo mount /dev/sdX2 /mnt
sudo tar -xzvf rootfs-jammy-cli.tar.gz -C /mnt/
sudo umount /mnt
```

