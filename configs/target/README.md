# Target 配置目录

此目录存放目标板的内核配置文件和设备树文件。

## 📁 目录结构

```
target/
├── defconfig/              # 内核配置文件（.config 或 defconfig）
│   ├── example_defconfig   # 示例配置
│   └── ...
│
├── dts/                    # 设备树文件（.dts 和 .dtsi）
│   ├── example.dts         # 示例设备树
│   └── ...
│
└── README.md               # 本文件
```

---

## 🎯 使用优先级

**编译内核时的配置优先级：**

1. **target/defconfig/** - 优先使用此目录下的配置文件
2. **内核源码自带的 defconfig** - 如果 target/ 中没有，使用内核源码中的配置
3. **board/*.conf 中指定的 LINUX_CONFIG** - 作为配置名称索引

---

## 📝 defconfig/ - 内核配置文件

### 文件命名规范

```
<board>_defconfig           # 标准命名
<board>_<variant>_defconfig # 带变体的命名

示例：
- example_defconfig
- t527_dev_defconfig
- t527_minimal_defconfig
```

### 配置文件类型

#### 1. defconfig（推荐）

精简的内核配置文件，只包含与默认值不同的选项。

**优点：**
- 文件小（通常几KB）
- 易于维护
- 跨内核版本移植性好

**创建方法：**
```bash
# 在内核源码目录
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- savedefconfig
mv defconfig configs/target/defconfig/myboard_defconfig
```

#### 2. .config（完整配置）

包含所有内核配置选项的完整文件。

**优点：**
- 包含所有选项的完整记录
- 可直接用作 .config

**缺点：**
- 文件大（通常几MB）
- 包含大量默认值

**使用方法：**
```bash
# 直接复制 .config 文件
cp output/linux/.config configs/target/defconfig/myboard.config
```

### 使用示例

#### 示例 1：创建新的 defconfig

```bash
# 1. 进入内核源码目录
cd output/linux

# 2. 加载基础配置
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- sun55i_t527_bsp_defconfig

# 3. 自定义配置
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- menuconfig

# 4. 保存为 defconfig
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- savedefconfig

# 5. 移动到 target 目录
mv defconfig ../../configs/target/defconfig/myboard_defconfig
```

#### 示例 2：使用已有的 defconfig

在 `board/*.conf` 中配置：

```bash
# 方法1：使用 target 目录中的配置（推荐）
LINUX_CONFIG="myboard_defconfig"  # 会自动在 target/defconfig/ 中查找

# 方法2：使用内核源码中的配置
LINUX_CONFIG="arch/arm64/configs/sun55i_t527_bsp_defconfig"
```

---

## 🌳 dts/ - 设备树文件

### 文件类型

#### 1. .dts（设备树源文件）

板级设备树文件，描述硬件配置。

```dts
/dts-v1/;

/ {
    model = "Example Board";
    compatible = "vendor,example-board";

    memory@40000000 {
        device_type = "memory";
        reg = <0x0 0x40000000 0x0 0x80000000>;
    };

    // 更多硬件描述...
};
```

#### 2. .dtsi（设备树包含文件）

可复用的设备树片段，通常描述 SoC 级别的硬件。

```dts
// soc-common.dtsi
/{
    cpus {
        // CPU 配置
    };
    
    soc {
        // SoC 外设配置
    };
};
```

### 设备树组织

```
dts/
├── vendor/                 # 按厂商组织
│   ├── allwinner/
│   │   ├── sun55i-t527.dtsi        # SoC 基础设备树
│   │   └── sun55i-t527-board.dts   # 板级设备树
│   └── rockchip/
│
├── example.dts            # 或直接放在根目录
└── example-variant.dts
```

### 使用方法

#### 在 board/*.conf 中配置：

```bash
# 指定设备树文件（不含 .dts 后缀）
DEVICE_DTS="example"                    # 使用 target/dts/example.dts
DEVICE_DTS="vendor/allwinner/t527-dev"  # 使用子目录中的设备树
```

#### 编译时处理：

构建系统会：
1. 检查 `target/dts/` 是否存在指定的 .dts 文件
2. 如果存在，复制到内核源码的 `arch/arm64/boot/dts/` 目录
3. 修改对应的 Makefile 以编译该设备树
4. 编译生成 .dtb 文件

---

## 🔄 工作流程

### 完整的配置工作流

```
1. 准备配置文件
   ├─ 创建/获取 defconfig
   └─ 创建/获取 .dts 文件

2. 放置文件
   ├─ defconfig → target/defconfig/
   └─ .dts      → target/dts/

3. 配置 board/*.conf
   ├─ LINUX_CONFIG="myboard_defconfig"
   └─ DEVICE_DTS="myboard"

4. 执行构建
   └─ ./build.sh -b myboard
```

### 构建系统查找顺序

#### defconfig 查找顺序：

1. `target/defconfig/${LINUX_CONFIG}`
2. `target/defconfig/${LINUX_CONFIG}.config`
3. 内核源码 `arch/${ARCH}/configs/${LINUX_CONFIG}`
4. 内核源码根目录 `.config`

#### 设备树查找顺序：

1. `target/dts/${DEVICE_DTS}.dts`
2. `target/dts/${DEVICE_DTS}/${DEVICE_DTS}.dts`
3. 内核源码 `arch/${ARCH}/boot/dts/${DEVICE_DTS}.dts`

---

## 📖 最佳实践

### 1. defconfig 管理

✅ **推荐做法：**
- 使用 `savedefconfig` 生成精简配置
- 为不同用途创建不同配置（minimal, full, debug）
- 定期与上游内核配置同步
- 添加清晰的注释说明配置目的

❌ **不推荐：**
- 直接使用完整的 .config（除非有特殊需求）
- 手动编辑 defconfig（应使用 menuconfig）
- 混用不同内核版本的配置

### 2. 设备树管理

✅ **推荐做法：**
- 使用 .dtsi 复用公共配置
- 为不同硬件变体创建单独的 .dts
- 保持与上游设备树兼容
- 添加详细的硬件描述注释

❌ **不推荐：**
- 在一个 .dts 中描述所有变体
- 重复定义相同的硬件节点
- 使用非标准的 compatible 字符串

### 3. 版本管理

✅ **推荐做法：**
- 使用 Git 管理配置文件
- 为重要更改添加 commit 信息
- 标记已测试的稳定配置

```bash
# 提交配置更改
git add configs/target/
git commit -m "Add defconfig for board X with feature Y enabled"
```

---

## 📝 示例配置

### 示例 1：最小配置

**文件：** `target/defconfig/example_minimal_defconfig`

```
# 最小配置示例
CONFIG_ARM64=y
CONFIG_ARCH_SUNXI=y
CONFIG_MMC=y
CONFIG_MMC_SUNXI=y
CONFIG_EXT4_FS=y
# ... 更多必要选项
```

### 示例 2：完整功能配置

**文件：** `target/defconfig/example_full_defconfig`

```
# 完整功能配置
CONFIG_ARM64=y
CONFIG_ARCH_SUNXI=y

# 文件系统
CONFIG_EXT4_FS=y
CONFIG_VFAT_FS=y
CONFIG_TMPFS=y

# 网络
CONFIG_NET=y
CONFIG_INET=y
CONFIG_WIRELESS=y

# USB
CONFIG_USB=y
CONFIG_USB_STORAGE=y

# ... 更多功能
```

### 示例 3：调试配置

**文件：** `target/defconfig/example_debug_defconfig`

```
# 调试配置
CONFIG_DEBUG_KERNEL=y
CONFIG_DEBUG_INFO=y
CONFIG_FTRACE=y
CONFIG_KGDB=y
# ... 调试选项
```

---

## 🛠️ 工具和命令

### 配置对比

```bash
# 对比两个配置的差异
scripts/diffconfig defconfig1 defconfig2

# 查看配置选项说明
make ARCH=arm64 helpnewconfig
```

### 配置验证

```bash
# 验证配置文件
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig

# 检查未设置的配置项
make ARCH=arm64 listnewconfig
```

### 配置文档

```bash
# 生成配置文档
make ARCH=arm64 htmldocs
```

---

## 📚 相关文档

- [内核配置指南](../../docs/02-构建指南.md#自定义内核配置)
- [设备树文档](https://www.kernel.org/doc/Documentation/devicetree/)
- [板级配置说明](../board/README.md)

---

<div align="center">

**作者：Nopiskl** | [返回上级目录](../README.md)

</div>

