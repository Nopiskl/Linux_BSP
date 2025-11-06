# 部署说明

## 部署到 Linux 系统

将 BSP 目录复制到 Linux 系统后，执行以下步骤：

### 1. 转换文件格式

```bash
cd BSP

# 使用 cleanup.sh（推荐）
bash cleanup.sh

# 或手动转换
sed -i 's/\r$//' configs/*.conf tools/*.sh build.sh
chmod +x build.sh tools/*.sh cleanup.sh
```

### 2. 安装依赖

```bash
sudo apt-get update
sudo apt-get install -y \
    gcc make git bc \
    gcc-aarch64-linux-gnu \
    dialog
```

### 3. 验证配置

```bash
# 检查配置文件语法
bash -n configs/test-board.conf

# 手动加载测试
KERNEL_TARGET=bsp source configs/test-board.conf
echo "Board: $BOARD_NAME"
echo "Arch: $ARCH"
echo "Kernel Repo: $LINUX_REPO"
```

### 4. 运行构建

```bash
# 测试构建
sudo ./build.sh -b test-board -g bsp

# 检查输出
ls -la output/
```

## 完整检查清单

- [ ] 文件换行符已转换为 Unix 格式
- [ ] 脚本文件有执行权限
- [ ] 依赖已安装
- [ ] 配置文件语法正确
- [ ] 能正常运行构建
- [ ] 输出目录结构正确

## 故障排查

### 换行符问题

```bash
# 检查文件格式
file configs/test-board.conf

# 应显示: ASCII text
# 不应显示: CRLF line terminators

# 批量转换
find . -name "*.conf" -o -name "*.sh" | xargs sed -i 's/\r$//'
```

### 权限问题

```bash
# 设置执行权限
chmod +x build.sh tools/*.sh cleanup.sh
```

### 配置加载问题

```bash
# 测试配置加载
KERNEL_TARGET=bsp
source configs/test-board.conf
echo "Repo: $LINUX_REPO"
echo "Branch: $LINUX_BRANCH"
echo "Config: $LINUX_CONFIG"

# 如果为空，检查 case 语句
```

## 快速验证脚本

创建 `verify.sh` 进行快速验证：

```bash
#!/bin/bash
echo "Verifying BSP setup..."

# Check structure
for dir in configs tools; do
    if [ -d "$dir" ]; then
        echo "✓ $dir/ exists"
    else
        echo "✗ $dir/ missing"
    fi
done

# Check files
for file in build.sh cleanup.sh; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file missing"
    fi
done

# Check line endings
echo ""
echo "Checking line endings..."
for file in configs/*.conf tools/*.sh build.sh; do
    if file "$file" | grep -q CRLF; then
        echo "⚠ $file has CRLF (needs conversion)"
    else
        echo "✓ $file OK"
    fi
done

echo ""
echo "Verification completed!"
```

使用：
```bash
bash verify.sh
```

