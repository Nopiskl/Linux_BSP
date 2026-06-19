# Kernel Configuration Guide

Kernel configuration overrides are located in `configs/target/<target-board>/`.

## Configuration Search Order

Build system searches for kernel configuration in this order:

1. `configs/target/${TARGET_BOARD}/kernel_defconfig` - Board defconfig override if non-empty
2. `arch/${ARCH}/configs/${KERNEL_DEFCONFIG}` - Kernel source configuration
3. `output/user_defconfig` - Configuration saved by menuconfig
4. `.config` - Existing configuration in kernel source

## Quick Start

### Method 1: Use Kernel Default Configuration

```bash
# configs/board/myboard.conf
KERNEL_DEFCONFIG="sun55i_t527_bsp_defconfig"

# Build
./build.sh -b myboard
```

### Method 2: Custom Configuration (Recommended)

```bash
# 1. Enter kernel source
cd output/linux

# 2. Load base configuration and customize
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- sun55i_t527_bsp_defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig

# 3. Save as minimal configuration
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- savedefconfig

# 4. Copy to target directory
cp defconfig ../../configs/target/myboard/kernel_defconfig

# 5. Update board configuration
# configs/board/myboard.conf
TARGET_BOARD="myboard"
KERNEL_DEFCONFIG="defconfig"

# 6. Build
cd ../..
./build.sh -b myboard
```

### Method 3: Use menuconfig for Temporary Adjustment

```bash
# Build with menuconfig enabled
./build.sh -b example -k yes

# Clear temporary configuration
rm output/user_defconfig
```

## Device Tree Configuration

Kernel device tree overrides are located at `configs/target/<target-board>/kernel.dts`.

### Basic Usage

```bash
# 1. Create device tree file
# configs/target/myboard/kernel.dts
/dts-v1/;

/ {
    model = "My Board";
    compatible = "vendor,myboard";
    
    memory@40000000 {
        device_type = "memory";
        reg = <0x0 0x40000000 0x0 0x80000000>;
    };
};

# 2. Specify in board configuration (without .dts suffix)
TARGET_BOARD="myboard"
KERNEL_DTS="myboard"

# 3. Build
./build.sh -b myboard
```
