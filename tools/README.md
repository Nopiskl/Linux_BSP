# BSP 构建工具说明

本目录包含 BSP 构建系统的核心工具脚本。

---

## 📁 文件结构

```
tools/
├── build-kernel.sh       # 内核构建脚本（主要）
├── build-boot.sh         # Bootloader 构建脚本
├── get-sources.sh        # 源码获取脚本
├── lib/
│   └── kernel-deb.sh    # Debian 包生成函数库
└── README.md            # 本文件
```

---

## 🔧 工具说明

### 1. build-kernel.sh

**功能**：编译 Linux 内核并生成 Debian 包

**特性**：
- ✅ 完整的内核编译流程
- ✅ 自动生成 4 个 .deb 包（dtb, image, headers, libc-dev）
- ✅ 支持 ccache 加速编译
- ✅ 支持 menuconfig 交互配置
- ✅ 支持内核补丁自动应用
- ✅ 智能跳过已构建的包

**使用方法**：
```bash
# 通常不直接调用，由 build.sh 自动调用
cd output
sudo ../tools/build-kernel.sh -b <板型> -k <yes/no> -e <yes/no>
```

**参数**：
- `-b <board>` - 板型名称
- `-k <yes/no>` - 是否运行 menuconfig
- `-e <yes/no>` - 是否使用 ccache
- `-g <target>` - 内核目标（保留参数，兼容性）

**输出**：
```
output/
└── <board>-kernel-pkgs/
    ├── linux-dtb-*.deb         # 设备树
    ├── linux-image-*.deb       # 内核镜像和模块
    ├── linux-headers-*.deb     # 内核头文件
    ├── linux-libc-dev-*.deb    # 用户空间头文件
    └── .done                   # 完成标记
```

---

### 2. build-boot.sh

**功能**：构建 Bootloader

**状态**：目前为测试脚本，待完善

**使用方法**：
```bash
cd output
sudo ../tools/build-boot.sh -b <板型>
```

---

### 3. get-sources.sh

**功能**：从 Git 仓库获取内核和 bootloader 源码

**状态**：目前为测试脚本，待完善

**使用方法**：
```bash
cd output
sudo ../tools/get-sources.sh -b <板型> -i <镜像URL> -g <目标>
```

---

## 📚 lib/kernel-deb.sh

Debian 包生成函数库，包含以下函数：

### 通用函数
- `is_enabled()` - 检查内核配置选项
- `gen_md5()` - 生成 MD5 校验和
- `gen_changelog()` - 生成 changelog
- `gen_copyright()` - 生成 copyright

### DTB 包函数
- `gen_dtb_control()` - control 文件
- `gen_dtb_postinst()` - 安装后脚本
- `gen_dtb_preinst()` - 安装前脚本

### Image 包函数
- `gen_image_control()` - control 文件
- `gen_image_postinst()` - 安装后脚本
- `gen_image_postrm()` - 卸载后脚本
- `gen_image_preinst()` - 安装前脚本
- `gen_image_prerm()` - 卸载前脚本

### Headers 包函数
- `gen_headers_control()` - control 文件
- `gen_headers_postinst()` - 安装后脚本
- `gen_headers_preinst()` - 安装前脚本
- `gen_headers_prerm()` - 卸载前脚本

### libc-dev 包函数
- `gen_libc_dev_control()` - control 文件

---

## 🔄 构建流程

### 完整构建流程

```bash
# 1. 准备工作
cd BSP

# 2. 运行构建（自动调用所有工具）
sudo ./build.sh -b myboard
```

### 内核构建详细流程

```
build.sh
   ↓
调用 get-sources.sh (如果需要)
   ↓
调用 build-boot.sh (如果不是 kernel-only)
   ↓
调用 build-kernel.sh
   ↓
   1. 加载配置 (configs/myboard.conf)
   2. 应用补丁 (如果 LINUX_PATHDIR != "none")
   3. 配置内核 (make defconfig 或 menuconfig)
   4. 编译内核 (make -j$(nproc))
   5. 安装 DTB
   6. 安装 Image & Modules
   7. 安装 Headers
   8. 安装 libc-dev
   9. 生成 Debian 控制文件
   10. 打包成 .deb
   11. 创建 .done 标记
```

---

## ⚙️ 环境要求

### 必需工具
```bash
# 基本编译工具
gcc, make, git, bc

# 交叉编译器
gcc-aarch64-linux-gnu (ARM64)
gcc-arm-linux-gnueabihf (ARM32)

# Debian 打包工具
dpkg-deb

# 可选：加速工具
ccache
```

### 安装依赖
```bash
# Ubuntu/Debian
sudo apt-get install \
    gcc make git bc \
    gcc-aarch64-linux-gnu \
    dpkg-dev \
    ccache
```

---

## 🎯 使用示例

### 示例 1：基本构建

```bash
cd BSP
sudo ./build.sh -b myboard
```

### 示例 2：配置内核

```bash
sudo ./build.sh -b myboard -k yes
# 在 menuconfig 中修改配置
# 配置会保存到 output/user_defconfig
```

### 示例 3：快速重新编译

```bash
# 使用 ccache + 本地源码 + 仅内核
sudo ./build.sh -b myboard -l -o yes -e yes
# 速度可提升 80%
```

### 示例 4：手动调用构建脚本

```bash
cd output

# 手动构建内核
sudo ../tools/build-kernel.sh \
    -b myboard \
    -k no \
    -e yes
```

---

## 🐛 调试技巧

### 1. 查看详细日志

脚本会输出详细的构建步骤，注意看：
```
=========================================="
Compiling Linux Kernel
=========================================="
```

### 2. 检查中间文件

```bash
cd output
ls -la deb-data/     # 查看打包前的文件
```

### 3. 测试单个步骤

可以修改 `build-kernel.sh`，注释掉 `set -e`，逐步执行

### 4. 检查包内容

```bash
dpkg -c output/myboard-kernel-pkgs/linux-image-*.deb
```

---

## 📝 开发说明

### 修改 build-kernel.sh

如果需要自定义构建流程：

1. 修改编译选项：找到 `compile_linux()` 函数
2. 修改包结构：找到 `install_*()` 函数
3. 修改包信息：修改 `lib/kernel-deb.sh`

### 添加新功能

建议创建新函数，保持主流程简洁：

```bash
my_custom_step(){
    echo "Doing custom work..."
    # your code here
}

# 在主流程中调用
compile_linux
install_dtb
my_custom_step  # 新增
install_image_modules
```

---

## ⚠️ 注意事项

1. **必须在 output 目录下运行**
   - 所有工具脚本假定工作目录为 `output/`
   - 通过 `build.sh` 自动处理

2. **需要 sudo 权限**
   - 编译和打包需要 root 权限
   - 或者配置好 fakeroot

3. **磁盘空间**
   - 内核源码：~1-2 GB
   - 编译产物：~5-10 GB
   - .deb 包：~100-500 MB

4. **编译时间**
   - 首次：30-60 分钟（取决于 CPU）
   - ccache 后：5-10 分钟

---

## 🔗 参考资料

- [Linux Kernel Documentation](https://www.kernel.org/doc/)
- [Debian Package Guide](https://www.debian.org/doc/manuals/maint-guide/)
- [AvaotaOS Build Framework](https://github.com/AvaotaSBC/AvaotaOS)

---

**需要帮助？** 查看主项目 README.md 或 QUICKSTART.md
