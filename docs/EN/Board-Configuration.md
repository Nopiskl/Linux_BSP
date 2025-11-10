# Board Configuration Guide

Board configuration files are located in `configs/board/` directory.

## Quick Start

```bash
# 1. Copy template
cp configs/board/example.conf configs/board/myboard.conf

# 2. Edit configuration
nano configs/board/myboard.conf

# 3. Build
./build.sh -b myboard
```

## Required Configuration

### Basic Information

```bash
BOARD_NAME="myboard"              # Board name
ARCH="arm64"                      # arm64 or arm
KERNEL_GCC="aarch64-linux-gnu-"   # ARM64: aarch64-linux-gnu-
                                  # ARM32: arm-linux-gnueabihf-
```

### Kernel Configuration

```bash
# Kernel repository
LINUX_REPO="https://github.com/torvalds/linux.git"

# Kernel version
LINUX_BRANCH="v6.1"

# Configuration file
LINUX_CONFIG="defconfig"

# Patch directory (usually "none")
LINUX_PATHDIR="none"
```

Common kernel versions:
- `v6.1` - LTS long-term support (Recommended)
- `v6.6` - Latest LTS

### Bootloader Configuration

#### Method 1: Using Supported Bootloaders

```bash
# Allwinner SyterKit
BL_CONFIG="sunxi-syterkit"
SYTERKIT_REPO="https://github.com/YuzukiHD/SyterKit.git"
SYTERKIT_BRANCH="master"

# Or Allwinner U-Boot
BL_CONFIG="sunxi-uboot"
UBOOT_REPO="https://github.com/u-boot/u-boot.git"
UBOOT_BRANCH="master"

# Or Rockchip U-Boot
BL_CONFIG="rockchip-uboot"
UBOOT_REPO="https://github.com/rockchip-linux/u-boot.git"
UBOOT_BRANCH="master"
```

#### Method 2: Custom Bootloader

```bash
BL_CONFIG="custom"
```

For detailed configuration and examples, see complete documentation in `configs/board/example.conf`.

