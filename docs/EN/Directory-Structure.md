# Directory Structure

```
BSP_T527/
├── README.md              # Project documentation (Bilingual)
├── build.sh               # Main build script
│
├── configs/               # Configuration directory
│   ├── board/             # Board configurations
│   │   ├── mainline_soc-example.conf   # Mainline SoC example configuration
│   │   └── *.conf         # Other board configs
│   │
│   └── target/            # Per-board Linux/U-Boot overrides
│       ├── orangepi-zero3/
│       │   ├── kernel.dts
│       │   ├── kernel_defconfig
│       │   ├── uboot.dts
│       │   └── uboot_defconfig
│       └── dshanpi-a1/
│           ├── kernel.dts
│           ├── kernel_defconfig
│           ├── uboot.dts
│           └── uboot_defconfig
│
├── tools/                 # Build tool scripts
│   ├── get-sources.sh     # Fetch source code
│   ├── build-kernel.sh    # Compile kernel
│   ├── build-boot.sh      # Compile bootloader
│   ├── build-rootfs.sh    # Build RootFS
│   └── lib/               # Tool libraries
│       └── kernel-deb.sh  # Kernel deb packaging
│
├── rootfs/                # RootFS configuration
│   ├── ubuntu/            # Ubuntu distributions
│   │   ├── focal/         # 20.04
│   │   ├── jammy/         # 22.04
│   │   └── noble/         # 24.04
│   ├── debian/            # Debian distributions
│   │   ├── bullseye/      # 11
│   │   ├── bookworm/      # 12
│   │   └── trixie/        # Testing
│   ├── overlays/          # System overlay files
│   │   ├── common/        # Common configuration
│   │   └── services/      # System services
│   └── distro-info.yaml   # Distribution information
│
├── docs/                  # Documentation directory
│   ├── CN/                # Chinese documentation
│   │   ├── 快速开始.md
│   │   ├── 板型配置.md
│   │   ├── 内核配置.md
│   │   ├── RootFS配置.md
│   │   ├── 常见问题.md
│   │   └── 目录结构.md
│   └── EN/                # English documentation
│       ├── Quick-Start.md
│       ├── Board-Configuration.md
│       ├── Kernel-Configuration.md
│       ├── RootFS-Configuration.md
│       ├── FAQ.md
│       └── Directory-Structure.md
│
└── output/                # Build output (auto-generated)
    ├── linux/             # Kernel source
    ├── bootloader-*/      # Bootloader artifacts
    ├── *-kernel-pkgs/     # Kernel deb packages
    ├── rootfs-*.tar.gz    # RootFS tarball
    └── user_defconfig     # User config (saved by menuconfig)
```

## Main Files

### Top Level Files

- `README.md` - Project documentation, bilingual version
- `build.sh` - Main build script, unified entry

### configs/ Configuration Directory

#### configs/board/

Board configuration files, each file defines complete configuration for a board.

Contains:
- Basic information (board name, architecture)
- Kernel configuration (repository, branch, config file)
- Bootloader configuration
- Device tree configuration
- Boot arguments

#### configs/target/<target-board>/

Per-board Linux and U-Boot overrides.

- `kernel.dts` - Kernel DTS override
- `kernel_defconfig` - Kernel defconfig override
- `uboot.dts` - U-Boot DTS override
- `uboot_defconfig` - U-Boot defconfig override
- Empty files are ignored and the build falls back to the source tree

### tools/ Tools Directory

Collection of build tool scripts.

### rootfs/ RootFS Configuration

Root filesystem configuration and overlay files.

### docs/ Documentation Directory

Complete project documentation in Chinese and English.

### output/ Build Output

Build process output directory (auto-generated).

## Configuration Search Mechanism

### Kernel Configuration Search Order

1. `configs/target/${TARGET_BOARD}/kernel_defconfig`
2. `arch/${ARCH}/configs/${KERNEL_DEFCONFIG}`
3. `output/user_defconfig`
4. `.config` (kernel source directory)

### Device Tree Search Order

1. `configs/target/${TARGET_BOARD}/kernel.dts`
2. `arch/${ARCH}/boot/dts/${KERNEL_DTS}.dts`
