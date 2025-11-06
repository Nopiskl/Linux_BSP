# BSP 构建框架

轻量级的 BSP 构建系统，专注于内核和引导程序开发。

---

## ⚡ 快速开始

```bash
cd BSP

# 1. 安装依赖
sudo apt-get install gcc make git bc gcc-aarch64-linux-gnu dialog

# 2. 转换文件格式（首次部署必需！）
./build.sh clean

# 3. 运行构建
sudo ./build.sh
```

详细步骤请查看 → **[QUICKSTART.md](QUICKSTART.md)**

---

## 📁 目录说明

```
BSP/
├── build.sh          # 主构建脚本（入口）
├── configs/          # 板型配置文件
├── tools/            # 构建工具脚本
└── output/           # 构建输出（自动创建）
```

---

## 📝 使用说明

### 交互式模式

```bash
sudo ./build.sh
```

按提示选择配置选项。

### 命令行模式

```bash
# 基本构建
sudo ./build.sh -b test-board

# 完整选项
sudo ./build.sh -b test-board -g bsp -k no -e yes -o no -l -c no
```

### 常用命令

```bash
# 仅构建内核
sudo ./build.sh -b test-board -o yes

# 使用本地源码（二次构建）
sudo ./build.sh -b test-board -l

# 配置内核
sudo ./build.sh -b test-board -k yes

# 使用 ccache 加速
sudo ./build.sh -b test-board -e yes
```

---

## 🎯 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `-b <board>` | 板型名称 | 必需 |
| `-g <target>` | 内核目标 | bsp |
| `-k <yes/no>` | 运行 menuconfig | no |
| `-e <yes/no>` | 使用 ccache | no |
| `-o <yes/no>` | 仅构建内核 | no |
| `-l` | 使用本地源码 | no |
| `-i <url>` | GitHub 镜像 | no |
| `-c <yes/no>` | 清理输出 | no |

---

## 🔧 添加新板型

```bash
# 1. 复制示例配置
cp configs/example.conf configs/myboard.conf

# 2. 编辑配置（至少修改这些）
nano configs/myboard.conf
# - BOARD_NAME
# - ARCH
# - LINUX_REPO
# - LINUX_BRANCH
# - LINUX_CONFIG

# 3. 构建
sudo ./build.sh -b myboard
```

详细说明请查看 → **[configs/README.md](configs/README.md)**

---

## 📦 构建输出

```
output/
├── linux/                      # 内核源码
├── bootloader-<board>/         # 引导程序文件
│   └── .done                   # 构建完成标记
└── <board>-kernel-pkgs/        # 内核 Debian 包
    ├── linux-dtb-*.deb
    ├── linux-image-*.deb
    ├── linux-headers-*.deb
    ├── linux-libc-dev-*.deb
    └── .done                   # 构建完成标记
```

---

## 🛠️ 依赖要求

```bash
sudo apt-get install \
    gcc make git bc \
    gcc-aarch64-linux-gnu \
    dialog
```

对于 ARM 32 位架构：
```bash
sudo apt-get install gcc-arm-linux-gnueabihf
```

---

## ❓ 常见问题

**Q: 提示 `$'\r': 未找到命令`？**  
A: 换行符问题，运行：`sed -i 's/\r$//' configs/*.conf`

**Q: 变量为空（LinuxRepo=）？**  
A: 检查配置文件中的 `case "${KERNEL_TARGET}" in` 语句

**Q: 权限错误？**  
A: 使用 `sudo` 运行脚本

**Q: 配置文件找不到？**  
A: 确保 `configs/` 目录下有对应的 `.conf` 文件

---

## 📚 文档导航

| 文档 | 说明 |
|------|------|
| [QUICKSTART.md](QUICKSTART.md) | 5分钟快速上手 |
| [TEST.md](TEST.md) | 测试指南 |
| [DEPLOY.md](DEPLOY.md) | 部署说明 |
| [configs/README.md](configs/README.md) | 配置文件说明 |
| [tools/README.md](tools/README.md) | 工具脚本说明 |

---

## 🧹 清理

```bash
# 清理构建产物（保留源码）
./build.sh clean

# 完全清理（包括源码）
sudo ./build.sh clean --all
```

**说明**：
- `./build.sh clean` - 清理 bootloader 和内核包，保留源码
- `./build.sh clean --all` - 完全删除 output 目录（需要 sudo）
- 同时会自动修复文件的换行符格式

---

**许可证**: GPL-3.0  
**当前版本**: 测试版（仅模拟构建流程）
