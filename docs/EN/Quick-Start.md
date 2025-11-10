# Quick Start

This guide helps you get started with BSP_T527 in 5 minutes.

## System Requirements

- Ubuntu 20.04+ or Debian 11+
- 4GB+ RAM (8GB recommended)
- 20GB+ disk space (50GB recommended)
- Root access (sudo)

## Install Dependencies

```bash
sudo apt-get update && sudo apt-get install -y \
    dialog \
    gcc-aarch64-linux-gnu \
    gcc-arm-linux-gnueabihf \
    mmdebstrap \
    debootstrap \
    qemu-user-static \
    binfmt-support \
    build-essential \
    git \
    bc \
    bison \
    flex \
    libssl-dev \
    libncurses-dev \
    kmod
```

## Quick Build

### Method 1: Interactive Build (Recommended)

```bash
cd /path/to/BSP_T527
sudo ./build.sh
```

Follow prompts to select:
1. Board
2. Kernel target
3. Run menuconfig or not
4. Build mode (full/kernel-only)
5. Build RootFS or not
6. Distribution (Ubuntu/Debian)
7. System type (CLI/XFCE/GNOME, etc.)
8. APT mirror source

### Method 2: Command-line Build

Build kernel only:
```bash
sudo ./build.sh -b example -o yes
```

Build complete system (CLI):
```bash
sudo ./build.sh \
    -b example \
    -r yes \
    -v ubuntu/jammy \
    -t cli \
    -m https://mirrors.aliyun.com/ubuntu-ports
```

Build desktop system (XFCE):
```bash
sudo ./build.sh \
    -b example \
    -r yes \
    -v ubuntu/jammy \
    -t xfce \
    -m https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports
```

## Build Output

```
output/
├── bootloader-example/         # Bootloader files
├── example-kernel-pkgs/        # Kernel .deb packages
├── linux/                      # Kernel source
└── rootfs-*.tar.gz            # RootFS tarball (if built)
```

## Common Issues

### DNS Resolution Failed

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d
sudo tee /etc/systemd/resolved.conf.d/dns.conf > /dev/null << 'EOF'
[Resolve]
DNS=8.8.8.8 114.114.114.114
FallbackDNS=223.5.5.5 223.6.6.6
EOF
sudo systemctl restart systemd-resolved
```

### Missing Toolchain

```bash
sudo apt-get install -y gcc-aarch64-linux-gnu gcc-arm-linux-gnueabihf
```

### Disk Space Insufficient

```bash
# Clean build artifacts
rm -rf output/

# Clean APT cache
sudo apt-get clean
```

## Next Steps

- See [Board Configuration](./Board-Configuration.md)
- See [Kernel Configuration](./Kernel-Configuration.md)
- See [RootFS Configuration](./RootFS-Configuration.md)
- See [FAQ](./FAQ.md)

