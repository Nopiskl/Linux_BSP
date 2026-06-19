# Bootloader Build Guide

This document describes how to build bootloader using `build-boot.sh`.

## Quick Start

```bash
# 1. Configure board
cp configs/board/mainline_soc-example.conf configs/board/myboard.conf
nano configs/board/myboard.conf

# 2. Get sources
./tools/get-sources.sh -b myboard

# 3. Build bootloader
./tools/build-boot.sh -b myboard

# 4. Check output
ls -lh bootloader-myboard/
```

## Command Options

```bash
./tools/build-boot.sh [OPTIONS]

Options:
  -b, --board BOARD         Board name (required)
  -m, --menuconfig          Run U-Boot menuconfig (yes/no)
  -e, --ccache             Use ccache for faster build (yes/no)
  -h, --help               Show help
```

## Supported Platforms

### Mainline U-Boot (mainline-uboot)

For ARM64 SoC platforms using the mainline U-Boot + ATF flow.

**Configuration example:**

```bash
# Bootloader type
BL_CONFIG="mainline-uboot"

# U-Boot configuration
UBOOT_REPO="https://github.com/u-boot/u-boot.git"
UBOOT_BRANCH="master"
UBOOT_DEFCONFIG="sun50i_defconfig"

# ATF configuration
ATF_REPO="https://github.com/ARM-software/arm-trusted-firmware.git"
ATF_BRANCH="master"
ATF_PLAT="sun50i_h616"        # H616/H6/A64 etc.
ATF_DEBUG="1"

```

**Output files:**
- `u-boot-sunxi-with-spl.bin` - Complete image (SPL + ATF + U-Boot)
- `u-boot.bin` - U-Boot proper
- `u-boot.dtb` - Device tree blob
- `bl31.bin` - ATF BL31
- `boot.scr` - Boot script

**Flash method:**

```bash
sudo dd if=bootloader-myboard/u-boot-sunxi-with-spl.bin \
        of=/dev/sdX \
        bs=1024 \
        seek=8 \
        conv=fsync
```

### Rockchip (rockchip-uboot)

For Rockchip RK3588/RK3568/RK3399 SoCs.

**Configuration example:**

```bash
# Bootloader type
BL_CONFIG="rockchip-uboot"

# U-Boot configuration
UBOOT_REPO="https://github.com/rockchip-linux/u-boot.git"
UBOOT_BRANCH="master"
UBOOT_DEFCONFIG="rk3588_defconfig"

# RKBIN configuration
RKBIN_REPO="https://github.com/rockchip-linux/rkbin.git"
RKBIN_BRANCH_HASH=""          # Optional: specific commit

# BL31/TEE/DDR paths (in rkbin repository)
BL31_PATH="bin/rk35/rk3588_bl31_v1.40.elf"
TEE_PATH="bin/rk35/rk3588_bl32_v1.12.bin"
DDRBIN_PATH="bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2736MHz_v1.11.bin"

```

**Output files:**
- `idbloader.img` - SPL + DDR init
- `u-boot.itb` - U-Boot + ATF + DTB
- `boot.scr` - Boot script

**Flash method:**

```bash
# Flash idbloader.img (from sector 64)
sudo dd if=bootloader-myboard/idbloader.img \
        of=/dev/sdX \
        seek=64 \
        conv=fsync

# Flash u-boot.itb (from sector 16384)
sudo dd if=bootloader-myboard/u-boot.itb \
        of=/dev/sdX \
        seek=16384 \
        conv=fsync
```

## Configuration Management

### Defconfig Priority

Build script searches for configuration in this order:

1. `configs/target/${TARGET_BOARD}/uboot_defconfig` - Board defconfig override if non-empty
2. `u-boot/configs/${UBOOT_DEFCONFIG}` - Defconfig from U-Boot source
3. `${WORKSPACE}/uboot_user_defconfig` - Saved from menuconfig
4. `u-boot/.config` - Existing .config

### Device Tree (DTS) Handling Logic

Build script uses a flexible DTS handling strategy:

**Deploy only when a target DTS override exists and is non-empty:**

1. `configs/target/${TARGET_BOARD}/uboot.dts` - U-Boot specific DTS override if non-empty
2. `u-boot/dts/upstream/src/${UBOOT_ARCH}/${UBOOT_DTS}.dts` - Mainline U-Boot source DTS
3. `u-boot/arch/arm/dts/${UBOOT_DTS}.dts` - Older/vendor U-Boot source DTS

**If the target DTS is missing or empty:**

- The build falls back to the DTS already present in the U-Boot source tree.
- No export-based DTS override is used.

### Using menuconfig

```bash
# Run menuconfig
./tools/build-boot.sh -b myboard -m yes

# Configuration is automatically saved to ${WORKSPACE}/uboot_user_defconfig
# This configuration is used only when target and source defconfigs are unavailable
```

### Custom Configuration

**Method 1: Export from menuconfig**

```bash
# 1. Run menuconfig
./tools/build-boot.sh -b myboard -m yes

# 2. Export as defconfig
cd output/mainline-uboot  # or rockchip-uboot
make savedefconfig

# 3. Save to project
cp defconfig ../../BSP_T527/configs/target/myboard/uboot_defconfig
```

**Method 2: Use complete .config**

```bash
# Copy complete configuration
cp output/mainline-uboot/.config \
   configs/target/myboard/uboot_defconfig
```


## Patch Management

### Patch Directory Structure

```
patches/uboot/myboard/
├── patches/           # .patch files
│   ├── 001-xxx.patch
│   └── 002-yyy.patch
└── files/            # Additional files
    └── board/...
```

### Creating Patches

```bash
cd output/mainline-uboot

# Make changes and commit
git add .
git commit -m "Add custom board support"

# Generate patch
git format-patch -1

# Move to project
mv 0001-*.patch ../../BSP_T527/patches/uboot/myboard/patches/
```

### Enable Patches

Set in board configuration:

```bash
BL_PATCHDIR="myboard"
```

## FAQ

### Q: Can't find defconfig?

Check configuration name:

```bash
# List available defconfigs
cd output/mainline-uboot
ls configs/ | grep defconfig
```

### Q: ATF build failed?

Check platform configuration matches SoC:

```bash
# Allwinner platforms
ATF_PLAT="sun50i_h616"   # H616/H618
ATF_PLAT="sun50i_h6"     # H6
ATF_PLAT="sun50i_a64"    # A64
```

### Q: Rockchip build failed?

Check RKBIN paths are correct:

```bash
# Check rkbin directory structure
cd output/rkbin
find bin -name "rk3588*"

# Update paths in configuration
BL31_PATH="bin/rk35/rk3588_bl31_xxx.elf"
```

## Advanced Usage

### Use ccache for Faster Build

```bash
# Install ccache
sudo apt-get install ccache

# Build with ccache
./tools/build-boot.sh -b myboard -e yes
```

### Batch Build Multiple Boards

```bash
#!/bin/bash
for board in board1 board2 board3; do
    ./tools/build-boot.sh -b ${board} -e yes
done
```

## Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install \
    build-essential \
    device-tree-compiler \
    u-boot-tools \
    flex bison \
    libssl-dev bc \
    gcc-aarch64-linux-gnu

# Optional
sudo apt-get install ccache
```

## References

- [U-Boot Documentation](https://www.denx.de/wiki/U-Boot)
- [ATF Documentation](https://trustedfirmware-a.readthedocs.io/)
- [Rockchip U-Boot](https://github.com/rockchip-linux/u-boot)
- [Board Configuration](Board-Configuration.md)
