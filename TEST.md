# 测试指南

## 测试准备

### 1. 转换换行符（重要！）

```bash
cd BSP
sed -i 's/\r$//' configs/*.conf tools/*.sh build.sh
```

### 2. 检查文件权限

```bash
chmod +x build.sh tools/*.sh
```

### 3. 验证配置文件

```bash
# 语法检查
bash -n configs/test-board.conf

# 手动加载测试
source configs/test-board.conf
echo "Board: $BOARD_NAME"
echo "Arch: $ARCH"
echo "Kernel: $LINUX_REPO"
```

## 运行测试

### 测试1：交互式模式

```bash
sudo ./build.sh
```

**预期行为**：
- 显示板型选择对话框
- 显示内核目标对话框
- 显示其他配置对话框
- 开始构建过程

### 测试2：命令行模式

```bash
sudo ./build.sh -b test-board -g bsp
```

**预期行为**：
- 直接开始构建
- 无交互式对话框

### 测试3：仅内核构建

```bash
sudo ./build.sh -b test-board -g bsp -o yes
```

**预期行为**：
- 跳过引导程序构建
- 仅构建内核包

### 测试4：本地源码模式

```bash
# 首次构建
sudo ./build.sh -b test-board -g bsp

# 二次构建（使用本地源码）
sudo ./build.sh -b test-board -g bsp -l
```

**预期行为**：
- 跳过源码下载
- 使用已有源码

### 测试5：清理构建

```bash
sudo ./build.sh -b test-board -g bsp -c yes
```

**预期行为**：
- 清理 output 目录
- 重新开始构建

## 验证结果

### 检查输出目录

```bash
ls -la output/

# 应包含:
# linux/
# bootloader-test-board/
# test-board-kernel-pkgs/
```

### 检查构建标记

```bash
# 引导程序标记
cat output/bootloader-test-board/.done
# 应输出: test-board

# 内核标记
cat output/test-board-kernel-pkgs/.done
# 应输出: defconfig
```

### 检查生成的文件

```bash
# 引导程序文件
ls -lh output/bootloader-test-board/

# 内核包文件
ls -lh output/test-board-kernel-pkgs/*.deb
```

## 测试检查清单

- [ ] 换行符已转换
- [ ] 配置文件语法正确
- [ ] 交互式模式正常工作
- [ ] 命令行模式正常工作
- [ ] 参数正确传递
- [ ] 增量构建正常工作
- [ ] 输出目录结构正确
- [ ] 标记文件正确创建
- [ ] 调试信息输出完整

## 常见错误及解决

### 错误1: `$'\r': 未找到命令`

**解决**：
```bash
sed -i 's/\r$//' configs/*.conf tools/*.sh build.sh
```

### 错误2: `未预期的记号`

**原因**: 配置文件语法错误

**解决**：
```bash
bash -n configs/test-board.conf
# 检查语法错误位置
```

### 错误3: 变量为空

**原因**: 配置未正确加载或 `KERNEL_TARGET` 不匹配

**解决**：
```bash
# 检查 case 语句
grep -A 10 "case" configs/test-board.conf

# 手动测试
KERNEL_TARGET=bsp source configs/test-board.conf
echo $LINUX_REPO
```

### 错误4: 工具脚本找不到

**解决**：
```bash
ls -la tools/
chmod +x tools/*.sh
```

## 预期输出示例

成功的构建应显示：

```
+-------[ Build Config ]--------
| Board=test-board
| Arch=arm64
| Target=bsp
| LinuxRepo=https://github.com/torvalds/linux.git
| LinuxBranch=v6.1
| LinuxConfig=defconfig
+-------------------------------
==========================================
Step 1: Fetching sources...
==========================================
[TEST] Get Sources Tool
[DEBUG] Started at: ...
[TEST] Fetch simulation completed!
==========================================
Step 2: Building bootloader...
==========================================
[TEST] Build Bootloader Tool
[TEST] Bootloader build simulation completed!
==========================================
Step 3: Building kernel...
==========================================
[TEST] Build Kernel Tool
[TEST] Kernel build simulation completed!
==========================================
Build Summary
==========================================
✓ Bootloader: .../output/bootloader-test-board
✓ Kernel packages: .../output/test-board-kernel-pkgs

Build completed successfully!
```
