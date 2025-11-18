# Bootloader Build Guide

This document describes how to build bootloader using `build-boot.sh`.

## Quick Start

```bash
# 1. Configure board
cp configs/board/example.conf configs/board/myboard.conf
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

### Allwinner (sunxi-uboot)

For Allwinner H6/H616/H618/A64/T527 SoCs.

**Configuration example:**

```bash
# Bootloader type
BL_CONFIG="sunxi-uboot"

# U-Boot configuration
UBOOT_REPO="https://github.com/u-boot/u-boot.git"
UBOOT_BRANCH="master"
BL_CONF="sun50i_defconfig"

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
BL_CONF="rk3588_defconfig"

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

1. `${WORKSPACE}/uboot_user_defconfig` - Saved from menuconfig
2. `configs/target/defconfig/uboot/${BL_CONF}` - Custom defconfig
3. `configs/target/defconfig/uboot/${BL_CONF}.config` - Custom .config
4. `u-boot/configs/${BL_CONF}` - Defconfig from U-Boot source
5. `u-boot/.config` - Existing .config

### Device Tree (DTS) Handling Logic

Build script uses a flexible DTS handling strategy:

**Deploy only when custom DTS is found:**

1. `configs/target/dts/uboot/${DEVICE_DTS}.dts` - U-Boot specific DTS
2. `configs/target/dts/uboot/${DEVICE_DTS}.dtsi` - U-Boot specific DTSI

**If no custom DTS exists:**

- Check if DTS exists in U-Boot source tree
- Check if kernel DTS exists (hint only, no forced copy)
- **Let U-Boot use default behavior** (some SDKs auto-reuse kernel DTS)

**Note:** Some SDKs automatically read from kernel DTS directory when building U-Boot, so manual copying is not required. The script does not force handling all cases, but lets U-Boot's build system handle it naturally

### Using menuconfig

```bash
# Run menuconfig
./tools/build-boot.sh -b myboard -m yes

# Configuration is automatically saved to ${WORKSPACE}/uboot_user_defconfig
# Next build will use this configuration
```

### Custom Configuration

**Method 1: Export from menuconfig**

```bash
# 1. Run menuconfig
./tools/build-boot.sh -b myboard -m yes

# 2. Export as defconfig
cd output/sunxi-uboot  # or rockchip-uboot
make savedefconfig

# 3. Save to project
cp defconfig ../../BSP_T527/configs/target/defconfig/uboot/myboard_defconfig
```

**Method 2: Use complete .config**

```bash
# Copy complete configuration
cp output/sunxi-uboot/.config \
   configs/target/defconfig/uboot/myboard.config
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
cd output/sunxi-uboot

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
cd output/sunxi-uboot
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

