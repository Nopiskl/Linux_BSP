# RootFS Configuration Guide

RootFS configuration files are located in `rootfs/` directory.

## Supported Distributions

### Ubuntu

- 20.04 (Focal) - Supported until 2025-04
- 22.04 (Jammy) - Supported until 2027-04 (Recommended)
- 24.04 (Noble) - Supported until 2029-04

Architectures: ARM64 (aarch64), ARM32 (armhf)

### Debian

- 11 (Bullseye) - Supported until 2026-06
- 12 (Bookworm) - Supported until 2028-06 (Recommended)
- 13 (Trixie) - Testing version

Architectures: ARM64 (arm64), ARM32 (armhf)

## Quick Build

```bash
cd /path/to/BSP_T527/output

# Ubuntu 22.04
sudo bash ../tools/build-rootfs.sh -b example -v ubuntu/jammy -t cli

# Debian 12
sudo bash ../tools/build-rootfs.sh -b example -v debian/bookworm -t cli

# Using mirror source
sudo bash ../tools/build-rootfs.sh \
    -b example \
    -v ubuntu/jammy \
    -t cli \
    -m https://mirrors.ustc.edu.cn/ubuntu-ports
```

## System Types

- CLI - Command-line interface (~500MB, 30-45 min)
- XFCE - Lightweight desktop (~2GB, 45-60 min)
- GNOME - Full-featured desktop (~4GB, 60-90 min)
- KDE - Modern desktop (~4GB, 60-90 min)
- LXQt - Ultra-light desktop (~1.5GB, 40-50 min)

## Package Management

Each distribution's `packages/base.list` contains base system packages.

### Modify Package List

```bash
# Add packages
echo "vim neovim tmux" >> rootfs/ubuntu/jammy/packages/base.list

# Or edit directly
nano rootfs/ubuntu/jammy/packages/base.list
```

## APT Mirror Sources

### Using Mirrors

```bash
# Ubuntu Tsinghua mirror
-m https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports

# Debian USTC mirror
-m https://mirrors.ustc.edu.cn/debian

# Aliyun mirror
-m https://mirrors.aliyun.com/ubuntu-ports
```

## Overlays System

Files in `rootfs/overlays/` directory will be copied to rootfs during build.

### Add Custom Script

```bash
cat > rootfs/overlays/common/usr/local/bin/my-script.sh <<EOF
#!/bin/bash
echo "Hello BSP"
EOF
chmod +x rootfs/overlays/common/usr/local/bin/my-script.sh
```

### Add SystemD Service

```bash
# 1. Create service directory
mkdir -p rootfs/overlays/services/my-service

# 2. Create service script and unit file
# See CN/RootFS配置.md for details
```

## Distribution Selection Guide

Recommendations:
- Embedded devices: Debian Bookworm
- Development environment: Ubuntu Jammy
- Latest software: Ubuntu Noble
- Long-term support: Debian Bookworm

