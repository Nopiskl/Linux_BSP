# BSP 构建框架

轻量级的 BSP 构建系统，专注于内核和引导程序开发。

**核心特性**：
- 🚀 **智能模式**：自动启用 ccache，编译速度提升 80%
- 🎯 **自动检测**：首次自动下载源码，之后自动复用
- ⚡ **极简命令**：一条命令完成所有构建

---

## ⚡ 快速开始

```bash
# 安装依赖
sudo apt-get install gcc make git bc gcc-aarch64-linux-gnu dialog ccache

# 开始构建
sudo ./build.sh -b <板型名称>
```

**就这么简单！** 详细指南请查看 → **[QUICKSTART.md](QUICKSTART.md)**

---

## 📁 目录说明

```
BSP/
├── build.sh          # 主构建脚本（入口）
├── configs/          # 板型配置文件
├── tools/            # 构建工具脚本
└── output/           # 构建输出（自动创建）
```

---

## 📝 常用命令

```bash
# 基本构建（智能模式）
sudo ./build.sh -b <板型>

# 交互式构建
sudo ./build.sh

# 仅构建内核
sudo ./build.sh -b <板型> -o yes

# 配置内核
sudo ./build.sh -b <板型> -k yes

# 强制重新下载源码
sudo ./build.sh -b <板型> -l no

# 清理构建产物
./build.sh clean

# 完全清理
sudo ./build.sh clean --all
```

---

## 🎯 核心参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-b <board>` | 板型名称 | 必需 |
| `-o yes/no` | 仅构建内核 | no |
| `-k yes/no` | 运行 menuconfig | no |
| `-l yes/no` | 使用本地源码（智能检测）| **yes** 🎯 |
| `-e yes/no` | 使用 ccache 加速 | **yes** ⚡ |
| `-g <target>` | 内核目标 | bsp |

完整参数列表：`./build.sh --help`

---

## 📦 构建输出

```
output/
├── linux/                      # 内核源码
├── bootloader-<board>/         # 引导程序文件
│   └── .done                   # 构建完成标记
└── <board>-kernel-pkgs/        # 内核 Debian 包
    ├── linux-dtb-*.deb
    ├── linux-image-*.deb
    ├── linux-headers-*.deb
    ├── linux-libc-dev-*.deb
    └── .done                   # 构建完成标记
```

---

## 🛠️ 依赖安装

```bash
# ARM64 架构（推荐）
sudo apt-get install gcc make git bc gcc-aarch64-linux-gnu dialog ccache

# ARM32 架构
sudo apt-get install gcc make git bc gcc-arm-linux-gnueabihf dialog ccache
```

---

## 📚 文档

| 文档 | 说明 |
|------|------|
| [QUICKSTART.md](QUICKSTART.md) | **快速上手指南**（推荐阅读）⭐ |
| [TEST.md](TEST.md) | 测试指南 |
| [DEPLOY.md](DEPLOY.md) | 部署说明 |
| [configs/README.md](configs/README.md) | 配置文件详细说明 |
| [tools/README.md](tools/README.md) | 工具脚本说明 |

---

**许可证**: GPL-3.0  
**当前版本**: 测试版（仅模拟构建流程）
