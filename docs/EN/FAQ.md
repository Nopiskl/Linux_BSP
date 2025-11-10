# FAQ - Frequently Asked Questions

## Build Issues

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

### Missing ccache

ccache is optional but speeds up compilation.

```bash
# Install ccache
sudo apt-get install -y ccache

# Or disable ccache
./build.sh -b example -e no
```

### Permission Denied

Build requires root access:

```bash
sudo ./build.sh -b example
```

## Configuration Issues

### Configuration File Not Found

```bash
# Check configuration files
ls -l configs/board/

# View available boards
./build.sh -b none  # Lists available boards
```

### Kernel Configuration Not Taking Effect

Check for temporary configuration:

```bash
# Delete temporary configuration
rm output/user_defconfig

# Rebuild
./build.sh -b example
```

## Network Issues

### Slow GitHub Access

Use mirror:

```bash
./build.sh -b example -i https://mirror.ghproxy.com
```

### Slow APT Sources

Use domestic mirrors:

```bash
# Aliyun
-m https://mirrors.aliyun.com/ubuntu-ports

# Tsinghua
-m https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports

# USTC
-m https://mirrors.ustc.edu.cn/ubuntu-ports
```

## Performance Issues

### Slow Build Speed

1. Use domestic mirror sources
2. Enable ccache (enabled by default)
3. Increase system swap space
4. Use parallel compilation

```bash
# View CPU cores
nproc

# Compilation automatically uses -j$(nproc)
```

### Insufficient Memory

```bash
# Increase swap space
sudo dd if=/dev/zero of=/swapfile bs=1G count=4
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Permanent mount
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

### Insufficient Disk Space

```bash
# Clean build artifacts
rm -rf output/

# Clean APT cache
sudo apt-get clean

# Clean kernel source (if not needed)
rm -rf output/linux
```

## Getting Help

1. Check complete documentation
2. Review FAQ
3. Submit issue to project repository
4. Check relevant logs and error messages

