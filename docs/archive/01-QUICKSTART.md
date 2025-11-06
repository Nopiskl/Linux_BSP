# 🚀 快速开始指南

5分钟快速构建 T527 BSP 系统。

---

## ⚡ 一键构建（推荐）

### 步骤 1: 安装依赖

```bash
sudo apt-get update
sudo apt-get install -y \
    gcc-aarch64-linux-gnu \
    make \
    bison \
    flex \
    libssl-dev \
    bc \
    dialog \
    mmdebstrap \
    debootstrap \
    qemu-user-static
```

### 步骤 2: 进入构建目录

```bash
cd /home/nopiskl/T527/BSP/BSP_T527
```

### 步骤 3: 启动交互式构建

```bash
sudo ./build.sh
```

按照提示选择：
- 📟 **开发板**: T527 Dev Board
- 🐧 **系统版本**: Ubuntu 22.04 Jammy (推荐)
- 🖥️ **系统类型**: CLI (命令行) 或 XFCE (桌面)
- 🌐 **镜像源**: 阿里云镜像 (国内) 或官方源 (国际)

### 步骤 4: 等待构建完成

构建时间：
- ⏱️ **仅内核**: 10-20分钟
- ⏱️ **内核+RootFS**: 30-60分钟

### 步骤 5: 获取构建产物

```bash
ls -lh output/
```

输出文件：
- `linux-image-*.deb` - 内核镜像包
- `linux-headers-*.deb` - 内核头文件包
- `linux-dtb-*.deb` - 设备树包
- `rootfs-*.tar.gz` - 根文件系统 (如果构建了)

---

## 🎯 快速命令（跳过交互）

### 构建内核（不含 RootFS）

```bash
sudo ./build.sh \
  --board t527_dev \
  --build-rootfs no
```

### 构建完整系统（内核 + Ubuntu CLI）

```bash
sudo ./build.sh \
  --board t527_dev \
  --distro-version ubuntu/jammy \
  --rootfs-type cli \
  --apt-mirror https://mirrors.aliyun.com/ubuntu-ports \
  --build-rootfs yes
```

### 构建桌面系统（内核 + Ubuntu XFCE）

```bash
sudo ./build.sh \
  --board t527_dev \
  --distro-version ubuntu/jammy \
  --rootfs-type xfce \
  --apt-mirror https://mirrors.aliyun.com/ubuntu-ports \
  --build-rootfs yes
```

---

## 🔍 验证构建

### 检查内核包

```bash
dpkg -c output/linux-image-*.deb | head
```

### 检查 RootFS

```bash
tar -tzf output/rootfs-*.tar.gz | head -20
```

---

## 📦 部署到设备

### 方法 1: 安装 Debian 包

```bash
# 复制到目标设备
scp output/*.deb user@device:/tmp/

# 在设备上安装
ssh user@device
cd /tmp
sudo dpkg -i linux-*.deb
sudo reboot
```

### 方法 2: 解压 RootFS

```bash
# 准备 SD 卡分区
sudo mkfs.ext4 /dev/sdX2  # 根分区

# 挂载并解压
sudo mount /dev/sdX2 /mnt
sudo tar -xzf output/rootfs-*.tar.gz -C /mnt
sudo umount /mnt
```

---

## ✅ 快速验证清单

- [ ] 依赖包全部安装
- [ ] 构建脚本执行无错误
- [ ] output/ 目录包含构建产物
- [ ] 内核包可以正常查看内容
- [ ] RootFS 包可以正常解压

---

## 🆘 遇到问题？

- **编译错误**: 检查是否安装了交叉编译工具链
- **网络问题**: 尝试切换镜像源或使用官方源
- **权限错误**: 确保使用 `sudo` 运行构建脚本
- **磁盘空间**: 确保至少有 10GB 可用空间

更多问题请查看 [05-常见问题](05-FAQ.md)

---

## 📚 下一步

- 📖 阅读 [构建指南](02-BUILD_GUIDE.md) 了解详细流程
- 🔧 查看 [RootFS配置](03-ROOTFS_GUIDE.md) 定制系统
- 🎓 探索 [高级配置](06-ADVANCED.md) 进行深度定制

