# BSP_T527 Documentation

## 文档索引 / Documentation Index

本项目提供完整的中英文文档。  
This project provides complete bilingual documentation.

---

## 中文文档 / Chinese Documentation

位于 `docs/CN/` 目录：

### 基础入门
1. [快速开始](CN/快速开始.md) - 快速上手指南
2. [板型配置](CN/板型配置.md) - 板型配置文件说明
3. [目录结构](CN/目录结构.md) - 项目目录结构说明

### 构建指南
4. [内核配置](CN/内核配置.md) - Linux 内核构建配置
5. [Bootloader构建](CN/Bootloader构建.md) - U-Boot 启动加载器构建
6. [RootFS配置](CN/RootFS配置.md) - 根文件系统构建

### 参考资料
7. [常见问题](CN/常见问题.md) - 常见问题解答

---

## English Documentation

Located in `docs/EN/` directory:

### Getting Started
1. [Quick Start](EN/Quick-Start.md) - Quick start guide
2. [Board Configuration](EN/Board-Configuration.md) - Board configuration file guide
3. [Directory Structure](EN/Directory-Structure.md) - Project directory structure

### Build Guide
4. [Kernel Configuration](EN/Kernel-Configuration.md) - Linux kernel build configuration
5. [Bootloader Build](EN/Bootloader-Build.md) - U-Boot bootloader build
6. [RootFS Configuration](EN/RootFS-Configuration.md) - Root filesystem build

### Reference
7. [FAQ](EN/FAQ.md) - Frequently asked questions

---

## 快速访问 / Quick Access

### 查看文档 / View Documentation

```bash
# 交互式文档查看器
./build.sh docs
# 或
bash docs/view-docs.sh

# 直接阅读文档
cd docs/CN && less 快速开始.md
cd docs/EN && less Quick-Start.md
```

### 快速构建 / Quick Build

```bash
# 基本构建
./build.sh -b myboard

# 查看帮助
./build.sh -h
```

---

## 支持的平台 / Supported Platforms

### Allwinner
- H6, H616, H618
- A64, A100
- T527, T507

### Rockchip
- RK3588, RK3588S
- RK3568, RK3566
- RK3399

---

## 文档组织 / Documentation Structure

```
docs/
├── README.md              # 本文件 / This file
├── view-docs.sh          # 交互式查看器 / Interactive viewer
│
├── CN/                   # 中文文档 / Chinese docs
│   ├── 快速开始.md
│   ├── 板型配置.md
│   ├── 内核配置.md
│   ├── Bootloader构建.md
│   ├── RootFS配置.md
│   ├── 常见问题.md
│   └── 目录结构.md
│
└── EN/                   # 英文文档 / English docs
    ├── Quick-Start.md
    ├── Board-Configuration.md
    ├── Kernel-Configuration.md
    ├── Bootloader-Build.md
    ├── RootFS-Configuration.md
    ├── FAQ.md
    └── Directory-Structure.md
```

---

## 主要特性 / Key Features

### 多级配置管理
- Defconfig 5级优先级查找
- DTS 灵活部署和复用
- 支持 menuconfig 交互配置

### 多厂商支持
- Allwinner (sunxi-uboot)
- Rockchip (rockchip-uboot)
- 统一的构建接口

### 开发工具
- ccache 加速编译
- 补丁管理系统
- 完善的错误提示

---

## 参考资料 / References

- [U-Boot 官方文档](https://www.denx.de/wiki/U-Boot)
- [Linux 内核文档](https://www.kernel.org/doc/)
- [ARM Trusted Firmware](https://trustedfirmware-a.readthedocs.io/)
- [Debian 根文件系统](https://www.debian.org/)
- [Ubuntu 根文件系统](https://ubuntu.com/)

---

## 获取帮助 / Get Help

### 构建问题
1. 查看对应的构建文档
2. 检查常见问题文档
3. 查看脚本的详细错误信息

### 配置问题
1. 参考 `configs/board/example.conf` 示例
2. 查看板型配置文档
3. 检查配置文件语法

---

## 贡献 / Contributing

欢迎贡献代码和文档！  
Contributions are welcome!

项目地址 / Project Repository:
- GitHub: [BSP_T527](https://github.com/your-repo/BSP_T527)

---

## 许可证 / License

GPL-3.0

---

**享受 BSP 开发！ / Happy BSP Development!**
