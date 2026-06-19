# BSP_T527 - Board Support Package

[中文](./README-CN.md)

A comprehensive Board Support Package for building Linux kernel, bootloader, and root filesystem.

## Quick Start

```bash
# Install dependencies
sudo apt-get update && sudo apt-get install -y \
    dialog gcc-aarch64-linux-gnu mmdebstrap debootstrap qemu-user-static

# Interactive build (Recommended)
sudo ./build.sh

# Command line build
sudo ./build.sh --board example --distro-version ubuntu/jammy \
    --rootfs-type cli --build-rootfs yes
```

## Documentation

All documentation is in the [docs/](./docs/) directory:

- **[Quick Start](./docs/EN/Quick-Start.md)** - Get started in 5 minutes
- **[Board Configuration](./docs/EN/Board-Configuration.md)** - Board setup guide
- **[Kernel Configuration](./docs/EN/Kernel-Configuration.md)** - Kernel and device tree
- **[RootFS Configuration](./docs/EN/RootFS-Configuration.md)** - Root filesystem
- **[FAQ](./docs/EN/FAQ.md)** - Troubleshooting
- **[Directory Structure](./docs/EN/Directory-Structure.md)** - Project organization

## Features

- Interactive build interface
- Multiple distributions: Ubuntu (20.04/22.04/24.04), Debian (11/12)
- Multiple desktop environments: CLI, XFCE, GNOME, KDE, LXQt
- China mirror support: USTC, Tsinghua, Aliyun, Huawei
- Automated package generation (.deb)
- Highly configurable

## System Requirements

- OS: Ubuntu 20.04+ or Debian 11+
- CPU: Dual-core or more (Quad-core recommended)
- RAM: 4GB+ (8GB recommended)
- Disk: 20GB+ (50GB recommended)
- Root access required (sudo)

## Supported Distributions

**Ubuntu:** 20.04 (Focal), 22.04 (Jammy - Recommended), 24.04 (Noble)
**Debian:** 11 (Bullseye), 12 (Bookworm - Recommended), Testing (Trixie)

## Project Structure

```text
BSP_T527/
├── build.sh           # Main build script
├── configs/           # Board configurations
│   ├── board/         # Board config files
│   └── target/        # Per-board Linux/U-Boot overrides
├── tools/             # Build tools
├── rootfs/            # RootFS configurations
├── docs/              # Documentation (CN & EN)
│   ├── CN/            # Chinese docs
│   └── EN/            # English docs
└── output/            # Build output (auto-generated)
```

## Examples

Build kernel only:

```bash
sudo ./build.sh --board example --kernel-only yes
```

Build minimal system:

```bash
sudo ./build.sh --board example --distro-version ubuntu/jammy \
    --rootfs-type cli --apt-mirror https://mirrors.aliyun.com/ubuntu-ports
```

Build desktop system:

```bash
sudo ./build.sh --board example --distro-version ubuntu/jammy \
    --rootfs-type xfce --build-rootfs yes
```

## License

See project license file.

## Acknowledgments

This project is inspired by [AvaotaOS](https://github.com/AvaotaSBC/AvaotaOS).
