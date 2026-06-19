# Target Board Overrides

This directory stores optional per-board overrides for Linux and U-Boot.

Each board has one directory named by `TARGET_BOARD` in its board config:

```text
configs/target/<target-board>/
├── kernel.dts
├── kernel_defconfig
├── uboot.dts
└── uboot_defconfig
```

The files are optional and may be empty. The build scripts first check whether
the target file exists, then use it only when it is non-empty. Empty files mean
"use the DTS/defconfig from the Linux or U-Boot source tree".

## Board Config Variables

In `configs/board/<board>.conf`, set these variables:

```bash
BOARD_NAME="myboard"
TARGET_BOARD="myboard"

KERNEL_DTS="vendor/kernel-board"
KERNEL_DEFCONFIG="defconfig"

UBOOT_DTS="vendor/uboot-board"
UBOOT_DEFCONFIG="myboard_defconfig"
```

`KERNEL_DTS`, `UBOOT_DTS`, `KERNEL_DEFCONFIG`, and `UBOOT_DEFCONFIG` are
fallback targets from the Linux or U-Boot source tree. The SDK automatically
checks `configs/target/${TARGET_BOARD}/` first, so board configs do not need to
name the target override files explicitly.

## Kernel Files

`kernel.dts` is copied to:

```text
linux/arch/${ARCH}/boot/dts/${KERNEL_DTS}.dts
```

`kernel_defconfig` is used before the kernel source defconfig. When it is empty,
the build falls back to:

```text
linux/arch/${ARCH}/configs/${KERNEL_DEFCONFIG}
```

## U-Boot Files

`uboot.dts` is copied to the matching U-Boot source DTS path. Mainline U-Boot
may store upstream DTS files under:

```text
${BL_CONFIG}/dts/upstream/src/${UBOOT_ARCH}/${UBOOT_DTS}.dts
```

Older or vendor U-Boot trees may use:

```text
${BL_CONFIG}/arch/arm/dts/${UBOOT_DTS}.dts
```

`uboot_defconfig` is used before the U-Boot source defconfig. When it is empty,
the build falls back to:

```text
${BL_CONFIG}/configs/${UBOOT_DEFCONFIG}
```

## Existing Boards

The current board override directories are:

```text
configs/target/orangepi-zero3/
configs/target/dshanpi-a1/
```
