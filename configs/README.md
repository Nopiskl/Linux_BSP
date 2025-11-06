# 配置文件说明

## 配置文件格式

每个板型需要一个 `.conf` 配置文件。

## 创建新配置

```bash
cp example.conf your-board.conf
```

## 必需配置项

### 基本信息
```bash
BOARD_NAME="your-board"        # 板型名称
ARCH="arm64"                   # 架构：arm64 或 arm
KERNEL_GCC="aarch64-linux-gnu-"  # 交叉编译器前缀
```

### 内核配置
```bash
case "${KERNEL_TARGET}" in
    bsp)
        LINUX_REPO="..."       # 内核仓库
        LINUX_BRANCH="..."     # 内核分支
        LINUX_CONFIG="..."     # 内核配置文件名
        LINUX_PATHDIR="none"   # 补丁目录（可选）
        ;;
esac
```

### 引导程序配置
```bash
BL_CONFIG="sunxi-uboot"        # 类型：sunxi-uboot, sunxi-syterkit, rockchip-uboot
UBOOT_REPO="..."               # U-Boot 仓库
UBOOT_BRANCH="..."             # U-Boot 分支
BL_CONF="..."                  # U-Boot 配置文件名
```

## 示例配置

### Allwinner H616 板型

```bash
BOARD_NAME="h616-board"
ARCH="arm64"
KERNEL_GCC="aarch64-linux-gnu-"

case "${KERNEL_TARGET}" in
    bsp)
        LINUX_REPO="https://github.com/AvaotaSBC/linux.git"
        LINUX_BRANCH="linux-5.15"
        LINUX_CONFIG="sun50i_h618_bsp_defconfig"
        LINUX_PATHDIR="none"
        ;;
esac

BL_CONFIG="sunxi-uboot"
UBOOT_REPO="https://github.com/u-boot/u-boot.git"
UBOOT_BRANCH="v2023.10"
ATF_REPO="https://github.com/ARM-software/arm-trusted-firmware.git"
ATF_BRANCH="lts-v2.10.4"
BL_CONF="h616_board_defconfig"
```

### Rockchip RK3576 板型

```bash
BOARD_NAME="rk3576-board"
ARCH="arm64"
KERNEL_GCC="aarch64-linux-gnu-"

case "${KERNEL_TARGET}" in
    bsp)
        LINUX_REPO="https://github.com/your-org/linux.git"
        LINUX_BRANCH="rk-6.1"
        LINUX_CONFIG="rockchip_linux_defconfig"
        LINUX_PATHDIR="none"
        ;;
esac

BL_CONFIG="rockchip-uboot"
UBOOT_REPO="https://github.com/your-org/u-boot.git"
UBOOT_BRANCH="master"
RKBIN_REPO="https://github.com/rockchip-linux/rkbin.git"
RKBIN_BRANCH_HASH="commit-hash"
BL_CONF="rk3576_board_defconfig"
```

## 可选配置项

```bash
DEVICE_DTS="vendor/board-dts"  # 设备树路径
BOOTARGS="..."                  # 内核启动参数
KERNEL_BRANCH="bsp,mainline"    # 支持多个内核目标

# 多内核目标示例
case "${KERNEL_TARGET}" in
    bsp)
        # BSP 内核配置
        ;;
    mainline)
        # 主线内核配置
        ;;
esac
```

## 注意事项

1. **变量名称**: 使用 `KERNEL_TARGET` 而不是 `TARGET`
2. **case 语句**: 必须包含 `case "${KERNEL_TARGET}" in`
3. **换行符**: 确保使用 Unix 换行符（LF），不是 Windows（CRLF）
4. **路径**: 仓库地址必须正确可访问
