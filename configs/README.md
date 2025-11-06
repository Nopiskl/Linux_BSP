# 板型配置说明

## 📝 快速创建

**三步创建新板型配置**：

```bash
# 1. 复制模板
cp example.conf myboard.conf

# 2. 修改配置（见下方说明）
nano myboard.conf

# 3. 开始构建
sudo ../build.sh -b myboard
```

---

## 🔧 必需配置（必改）

### 1. 基本信息

```bash
BOARD_NAME="myboard"              # 你的板型名称
ARCH="arm64"                      # arm64 或 arm
KERNEL_GCC="aarch64-linux-gnu-"   # ARM64 用这个，ARM32 用 arm-linux-gnueabihf-
```

### 2. 内核配置 - 官方主线内核

```bash
# 官方 Linux 内核
LINUX_REPO="https://github.com/torvalds/linux.git"

# 内核版本（如 v6.1, v6.6）
LINUX_BRANCH="v6.6"

# 配置文件（通常用 defconfig）
LINUX_CONFIG="defconfig"

# 补丁目录（一般填 none）
LINUX_PATHDIR="none"
```

**常用内核版本**：
- `v6.1` - LTS 长期支持版本（推荐）
- `v6.6` - 最新 LTS 版本
- 查看更多版本：https://kernel.org

### 3. Bootloader 配置 - 自定义 Bootloader

```bash
# 使用自定义 Bootloader
BL_CONFIG="custom"

# 你的 Bootloader 仓库
BOOTLOADER_REPO="https://github.com/your-org/your-bootloader.git"

# 分支或标签
BOOTLOADER_BRANCH="main"

# 配置文件或编译参数
BOOTLOADER_CONFIG="your_config"

# 如果使用预编译的bootloader（可选）
# BOOTLOADER_BINARY="path/to/bootloader.bin"
```

---

## 📋 完整示例

### 典型配置示例（官方内核 + 自定义bootloader）

```bash
# 基本信息
BOARD_NAME="myboard"
ARCH="arm64"
KERNEL_GCC="aarch64-linux-gnu-"

# 内核配置 - 官方主线内核
LINUX_REPO="https://github.com/torvalds/linux.git"
LINUX_GITEE_REPO=""
LINUX_BRANCH="v6.1"              # LTS 版本
LINUX_CONFIG="defconfig"
LINUX_PATHDIR="none"

# Bootloader 配置 - 自定义实现
BL_CONFIG="custom"
# CUSTOM_BL_REPO="https://github.com/myorg/my-bootloader.git"
# CUSTOM_BL_BRANCH="main"

# 可选配置
DEVICE_DTS="myvendor/myboard"
BOOTARGS="root=LABEL=rootfs rootwait console=ttyS0,115200"

setup_dhcp(){
    echo "My board setup"
}
```

---

## ⚙️ 可选配置（一般不用改）

```bash
# 设备树文件（一般自动识别）
DEVICE_DTS="vendor/board-dts"

# 内核启动参数（默认一般够用）
BOOTARGS="root=LABEL=rootfs rootwait console=ttyS0,115200"

# setup_dhcp 函数（网络配置，一般保持默认）
setup_dhcp(){
    echo "Board setup"
}
```

---

## ❓ 常见问题

**Q: 为什么只使用官方内核？**  
A: 官方内核更稳定、支持更好、升级容易，适合大多数场景。

**Q: LINUX_CONFIG 填什么？**  
A: 通常填 `defconfig`（通用配置），或在 `arch/arm64/configs/` 目录下找到芯片对应的配置文件。

**Q: 如何选择内核版本？**  
A: 推荐使用 LTS 版本：
- `v6.1` - 长期支持到 2026 年
- `v6.6` - 最新 LTS 版本
- 查看：https://kernel.org

**Q: 自定义 Bootloader 如何配置？**  
A: 设置 `BL_CONFIG="custom"`，然后指定你的 bootloader 仓库地址和配置。

**Q: 配置文件出错怎么办？**  
A: 运行 `../build.sh clean` 修复换行符问题。

---

## 💡 配置技巧

1. **从示例开始**：复制 `example.conf` 比从头写容易
2. **参考已有配置**：看看 `test-board.conf` 的格式
3. **逐步修改**：先改基本信息，确保能构建，再调优
4. **查看日志**：构建出错时看错误信息，通常能找到配置问题

---

**需要更多帮助？** 查看 `example.conf` 中的详细注释。
