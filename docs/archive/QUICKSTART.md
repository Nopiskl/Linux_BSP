# BSP 快速上手指南

轻量级 BSP 构建系统，专注于内核和引导程序开发。

---

## ⚡ 快速开始

### 1. 安装依赖

```bash
cd BSP
sudo apt-get install gcc make git bc gcc-aarch64-linux-gnu dialog ccache
```

**对于 ARM32 架构**：
```bash
sudo apt-get install gcc-arm-linux-gnueabihf
```

### 2. 首次构建

```bash
# 修复换行符（如果文件来自 Windows）
./build.sh clean

# 开始构建
sudo ./build.sh -b test-board
```

**说明**：
- ✅ 自动下载源码（首次）
- ✅ 自动启用 ccache 编译缓存
- ✅ 构建 bootloader 和内核包

---

## 📦 查看结果

```bash
# 查看所有输出
ls -la output/

# 引导程序文件
ls output/bootloader-test-board/

# 内核 Debian 包
ls output/test-board-kernel-pkgs/*.deb
```

**输出文件**：
```
output/
├── linux/                      # 内核源码
├── bootloader-<board>/         # 引导程序
└── <board>-kernel-pkgs/        # 内核 .deb 包
    ├── linux-dtb-*.deb
    ├── linux-image-*.deb
    ├── linux-headers-*.deb
    └── linux-libc-dev-*.deb
```

---

## 🎯 智能模式（默认启用）

**无需手动指定参数，一切自动优化！**

### 特性

- ✅ **自动启用 ccache**：重新编译速度提升 80%
- ✅ **智能源码管理**：首次自动下载，之后自动复用
- ✅ **极简命令**：只需 `sudo ./build.sh -b <board>`

### 工作流程

```bash
# 首次构建
sudo ./build.sh -b test-board
# → 检测到没有源码 → 自动下载
# → 启用 ccache
# 时间：~40 分钟

# 修改代码后重新构建
sudo ./build.sh -b test-board -o yes
# → 检测到有源码 → 直接使用
# → 启用 ccache → 只编译修改的部分
# 时间：~5 分钟 ⚡
```

---

## 🔧 常用命令

### 基本操作

```bash
# 交互式构建（推荐新手）
sudo ./build.sh

# 命令行构建（推荐日常）
sudo ./build.sh -b test-board

# 仅构建内核（跳过 bootloader）
sudo ./build.sh -b test-board -o yes

# 配置内核（运行 menuconfig）
sudo ./build.sh -b test-board -k yes
```

### 源码管理

```bash
# 强制重新下载源码（获取最新代码）
sudo ./build.sh -b test-board -l no

# 使用本地源码（默认行为，可省略）
sudo ./build.sh -b test-board -l yes
```

### 清理操作

```bash
# 清理构建产物（保留源码）
./build.sh clean

# 完全清理（删除所有，包括源码）
sudo ./build.sh clean --all
```

---

## 📝 开发工作流

### 场景 1：初次开发

```bash
# Day 1: 首次构建
sudo ./build.sh -b myboard
# 自动下载源码 + 完整构建

# Day 2: 修改驱动代码
cd output/linux/drivers/xxx
vim my_driver.c
cd ../../..

# 重新编译（超快！）
sudo ./build.sh -b myboard -o yes
# 自动使用本地源码 + ccache 加速
```

### 场景 2：更新内核

```bash
# 获取最新上游代码
sudo ./build.sh -b myboard -l no

# 或者：完全重新开始
./build.sh clean --all
sudo ./build.sh -b myboard
```

### 场景 3：多板型开发

```bash
# 板型 A
sudo ./build.sh -b board-a

# 板型 B（复用源码，超快）
sudo ./build.sh -b board-b

# 板型 C
sudo ./build.sh -b board-c
```

---

## 🎨 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-b <board>` | 板型名称 | **必需** |
| `-o <yes/no>` | 仅构建内核 | no |
| `-k <yes/no>` | 运行 menuconfig | no |
| `-l <yes/no>` | 使用本地源码 | **yes** 🎯 |
| `-e <yes/no>` | 使用 ccache | **yes** ⚡ |
| `-g <target>` | 内核目标 | bsp |
| `-i <url>` | GitHub 镜像 | no |

**智能默认**：
- `-l yes`：自动检测，本地没有源码时自动下载
- `-e yes`：启用编译缓存，大幅提升重新编译速度

---

## 🆕 添加新板型

### 快速创建

```bash
# 1. 复制示例配置
cp configs/example.conf configs/myboard.conf

# 2. 编辑配置（至少修改这些）
nano configs/myboard.conf
```

### 必需修改的配置

```bash
BOARD_NAME="myboard"                    # 板型名称
ARCH="arm64"                           # 架构：arm64 或 arm
KERNEL_GCC="aarch64-linux-gnu-"        # 交叉编译器

case "${KERNEL_TARGET}" in
    bsp)
        LINUX_REPO="..."               # 内核仓库地址
        LINUX_BRANCH="..."             # 内核分支
        LINUX_CONFIG="..."             # defconfig 名称
        ;;
esac

BL_CONFIG="sunxi-uboot"                # bootloader 类型
UBOOT_REPO="..."                       # U-Boot 仓库
UBOOT_BRANCH="..."                     # U-Boot 分支
```

### 开始构建

```bash
sudo ./build.sh -b myboard
```

详细配置说明请查看：`configs/README.md`

---

## ❓ 常见问题

### 换行符错误

**问题**：`$'\r': 未找到命令`

**解决**：
```bash
./build.sh clean
```

### 权限错误

**问题**：`Permission denied`

**解决**：
```bash
# 使用 sudo 运行
sudo ./build.sh -b test-board

# 清理时也可能需要
sudo ./build.sh clean --all
```

### 配置文件找不到

**问题**：`Config not found`

**解决**：
```bash
# 检查配置文件是否存在
ls configs/*.conf

# 确保文件名匹配
sudo ./build.sh -b <config文件名去掉.conf>
```

### ccache 未安装

**问题**：`ccache: command not found`

**解决**：
```bash
sudo apt-get install ccache
```

### 源码下载失败

**问题**：网络问题导致下载失败

**解决**：
```bash
# 使用 GitHub 镜像
sudo ./build.sh -b test-board -i https://mirror.ghproxy.com
```

---

## 📚 更多文档

| 文档 | 说明 |
|------|------|
| `README.md` | 完整项目说明 |
| `TEST.md` | 测试指南 |
| `DEPLOY.md` | 部署说明 |
| `configs/README.md` | 配置文件详细说明 |
| `tools/README.md` | 工具脚本说明 |

---

## 🎯 总结

**最简使用**：
```bash
# 1. 安装依赖
sudo apt-get install gcc make git bc gcc-aarch64-linux-gnu dialog ccache

# 2. 构建
sudo ./build.sh -b <板型>

# 3. 完成！
```

**关键特性**：
- ✅ 智能模式：自动优化一切
- ✅ ccache：编译速度提升 80%
- ✅ 极简命令：一条命令搞定

**需要帮助**？运行 `./build.sh --help` 查看完整选项。
