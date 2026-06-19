# Bootloader 构建说明

本文档介绍如何使用 `build-boot.sh` 构建 Bootloader。

## 快速开始

```bash
# 1. 配置板型
cp configs/board/mainline_soc-example.conf configs/board/myboard.conf
nano configs/board/myboard.conf

# 2. 获取源码
./tools/get-sources.sh -b myboard

# 3. 构建 Bootloader
./tools/build-boot.sh -b myboard

# 4. 查看输出
ls -lh bootloader-myboard/
```

## 命令参数

```bash
./tools/build-boot.sh [OPTIONS]

选项：
  -b, --board BOARD         板型名称（必需）
  -m, --menuconfig          运行 U-Boot menuconfig (yes/no)
  -e, --ccache             使用 ccache 加速编译 (yes/no)
  -h, --help               显示帮助
```

## 支持的平台

### Mainline U-Boot (mainline-uboot)

适用于使用主线 U-Boot + ATF 流程的 ARM64 SoC 平台。

**配置示例：**

```bash
# 架构配置
ARCH="arm64"                   # 内核架构
UBOOT_ARCH="arm64"             # U-Boot 架构
ATF_ARCH=""                    # ATF 架构（不设置）

# 工具链配置
KERNEL_GCC="aarch64-linux-gnu-"    # 内核工具链
UBOOT_GCC="aarch64-linux-gnu-"     # U-Boot 工具链
ATF_GCC="aarch64-linux-gnu-"       # ATF 工具链

# Bootloader 类型
BL_CONFIG="mainline-uboot"

# U-Boot 配置
UBOOT_REPO="https://github.com/u-boot/u-boot.git"
UBOOT_BRANCH="master"
UBOOT_DEFCONFIG="sun50i_defconfig"

# ATF 配置
ATF_REPO="https://github.com/ARM-software/arm-trusted-firmware.git"
ATF_BRANCH="master"
ATF_PLAT="sun50i_h616"        # H616/H6/A64 等
ATF_DEBUG="1"

```

**输出文件：**
- `u-boot-sunxi-with-spl.bin` - 完整镜像（SPL + ATF + U-Boot）
- `u-boot.bin` - U-Boot proper
- `u-boot.dtb` - 设备树
- `bl31.bin` - ATF BL31
- `boot.scr` - 启动脚本

**烧录方法：**

```bash
sudo dd if=bootloader-myboard/u-boot-sunxi-with-spl.bin \
        of=/dev/sdX \
        bs=1024 \
        seek=8 \
        conv=fsync
```

### Rockchip (rockchip-uboot)

适用于 Rockchip RK3588/RK3568/RK3399 等芯片。

**配置示例：**

```bash
# 架构配置
ARCH="arm64"                   # 内核架构
UBOOT_ARCH=""                  # U-Boot 架构（RK 平台与内核相同，不设置）
ATF_ARCH=""                    # ATF 架构（不设置）

# 工具链配置
KERNEL_GCC="aarch64-linux-gnu-"    # 内核工具链
UBOOT_GCC="aarch64-linux-gnu-"     # U-Boot 工具链
ATF_GCC="aarch64-linux-gnu-"       # ATF 工具链

# Bootloader 类型
BL_CONFIG="rockchip-uboot"

# U-Boot 配置
UBOOT_REPO="https://github.com/rockchip-linux/u-boot.git"
UBOOT_BRANCH="master"
UBOOT_DEFCONFIG="rk3588_defconfig"

# RKBIN 配置
RKBIN_REPO="https://github.com/rockchip-linux/rkbin.git"
RKBIN_BRANCH_HASH=""          # 可选：指定特定commit

# BL31/TEE/DDR 路径（在 rkbin 仓库中）
BL31_PATH="bin/rk35/rk3588_bl31_v1.40.elf"
TEE_PATH="bin/rk35/rk3588_bl32_v1.12.bin"
DDRBIN_PATH="bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2736MHz_v1.11.bin"

```

**输出文件：**
- `idbloader.img` - SPL + DDR 初始化
- `u-boot.itb` - U-Boot + ATF + 设备树
- `boot.scr` - 启动脚本

**烧录方法：**

```bash
# 烧录 idbloader.img（从 64 扇区开始）
sudo dd if=bootloader-myboard/idbloader.img \
        of=/dev/sdX \
        seek=64 \
        conv=fsync

# 烧录 u-boot.itb（从 16384 扇区开始）
sudo dd if=bootloader-myboard/u-boot.itb \
        of=/dev/sdX \
        seek=16384 \
        conv=fsync
```

## 架构与工具链配置

### 架构配置说明

BSP 支持为不同组件设置独立的架构：

```bash
ARCH="arm64"           # 内核架构
UBOOT_ARCH="arm64"     # U-Boot 架构
ATF_ARCH=""            # ATF 架构（通常不需要设置）
```

**关键点：**
- **ARM64 主线方案**：内核和 U-Boot 通常都是 `arm64`
- **Rockchip 平台**：内核和 U-Boot 通常都是 `arm64`
- 未设置时自动回退：`UBOOT_ARCH → ARCH`，`ATF_ARCH → UBOOT_ARCH`

### 工具链配置说明

支持为不同组件使用独立的工具链：

```bash
KERNEL_GCC="aarch64-linux-gnu-"    # 内核工具链
UBOOT_GCC="aarch64-linux-gnu-"     # U-Boot 工具链
ATF_GCC="aarch64-linux-gnu-"       # ATF 工具链
```

**回退机制：**
- `UBOOT_GCC` 未设置时使用 `KERNEL_GCC`
- `ATF_GCC` 未设置时使用 `UBOOT_GCC`

**注意：** ARM64 平台建议内核、U-Boot 和 ATF 统一使用 `aarch64-linux-gnu-` 工具链

### 典型配置示例

**主线 ARM64 SoC 板型：**
```bash
ARCH="arm64"                       # 64位内核
UBOOT_ARCH="arm64"                 # 64位 U-Boot
KERNEL_GCC="aarch64-linux-gnu-"
UBOOT_GCC="aarch64-linux-gnu-"
ATF_GCC="aarch64-linux-gnu-"
```

**Rockchip RK3588（统一架构）：**
```bash
ARCH="arm64"                       # 64位内核
UBOOT_ARCH=""                      # 不设置，自动使用 arm64
KERNEL_GCC="aarch64-linux-gnu-"
UBOOT_GCC="aarch64-linux-gnu-"
ATF_GCC="aarch64-linux-gnu-"
```

## 配置管理

### Defconfig 优先级

构建脚本按以下顺序查找配置：

1. `configs/target/${TARGET_BOARD}/uboot_defconfig` - 板级 defconfig 覆盖（非空才使用）
2. `u-boot/configs/${UBOOT_DEFCONFIG}` - U-Boot 源码中的 defconfig
3. `${WORKSPACE}/uboot_user_defconfig` - menuconfig 保存的配置
4. `u-boot/.config` - 已有的 .config

### 设备树（DTS）管理

U-Boot 设备树优先使用 `configs/target/${TARGET_BOARD}/uboot.dts`。
如果该文件不存在或为空，则回退到 U-Boot 源码中的 `UBOOT_DTS`。

**U-Boot 设备树：**
- target 覆盖：`configs/target/${TARGET_BOARD}/uboot.dts`
- 主线 U-Boot 回退位置：`output/mainline-uboot/dts/upstream/src/${UBOOT_ARCH}/${UBOOT_DTS}.dts`
- 旧版/vendor U-Boot 回退位置：`output/${BL_CONFIG}/arch/arm/dts/${UBOOT_DTS}.dts`

**内核设备树：**
- target 覆盖：`configs/target/${TARGET_BOARD}/kernel.dts`
- 源码回退位置：`output/linux/arch/${ARCH}/boot/dts/${KERNEL_DTS}.dts`

### 使用 menuconfig

```bash
# 运行 menuconfig 配置
./tools/build-boot.sh -b myboard -m yes

# 配置自动保存到 ${WORKSPACE}/uboot_user_defconfig
# 当 target 和源码 defconfig 都不可用时会使用此配置
```

### 自定义配置

**方法1：从 menuconfig 导出**

```bash
# 1. 运行 menuconfig
./tools/build-boot.sh -b myboard -m yes

# 2. 导出为 defconfig
cd output/mainline-uboot  # 或 rockchip-uboot
make savedefconfig

# 3. 保存到项目
cp defconfig ../../BSP_T527/configs/target/myboard/uboot_defconfig
```

**方法2：使用完整 .config**

```bash
# 复制完整配置
cp output/mainline-uboot/.config \
   configs/target/myboard/uboot_defconfig
```


## 补丁管理

### 补丁目录结构

```
patches/uboot/myboard/
├── patches/           # .patch 文件
│   ├── 001-xxx.patch
│   └── 002-yyy.patch
└── files/            # 额外文件
    └── board/...
```

### 创建补丁

```bash
cd output/mainline-uboot

# 进行修改并提交
git add .
git commit -m "Add custom board support"

# 生成补丁
git format-patch -1

# 移动到项目
mv 0001-*.patch ../../BSP_T527/patches/uboot/myboard/patches/
```

### 启用补丁

在板型配置中设置：

```bash
BL_PATCHDIR="myboard"
```

## 常见问题

### Q: 找不到 defconfig？

检查配置名称：

```bash
# 查看可用的 defconfig
cd output/mainline-uboot
ls configs/ | grep defconfig
```

### Q: ATF 编译失败？

检查平台配置是否与芯片匹配：

```bash
# Allwinner 平台
ATF_PLAT="sun50i_h616"   # H616/H618
ATF_PLAT="sun50i_h6"     # H6
ATF_PLAT="sun50i_a64"    # A64
```

### Q: Rockchip 构建失败？

检查 RKBIN 路径是否正确：

```bash
# 查看 rkbin 目录结构
cd output/rkbin
find bin -name "rk3588*"

# 更新配置中的路径
BL31_PATH="bin/rk35/rk3588_bl31_xxx.elf"
```

## 高级用法

### 使用 ccache 加速

```bash
# 安装 ccache
sudo apt-get install ccache

# 使用 ccache 构建
./tools/build-boot.sh -b myboard -e yes
```

### 多板型批量构建

```bash
#!/bin/bash
for board in board1 board2 board3; do
    ./tools/build-boot.sh -b ${board} -e yes
done
```

## 依赖工具

```bash
# Ubuntu/Debian
sudo apt-get install \
    build-essential \
    device-tree-compiler \
    u-boot-tools \
    flex bison \
    libssl-dev bc \
    gcc-aarch64-linux-gnu

# 可选
sudo apt-get install ccache
```

## 参考资料

- [U-Boot 官方文档](https://www.denx.de/wiki/U-Boot)
- [ATF 官方文档](https://trustedfirmware-a.readthedocs.io/)
- [Rockchip U-Boot](https://github.com/rockchip-linux/u-boot)
- [板型配置说明](板型配置.md)
