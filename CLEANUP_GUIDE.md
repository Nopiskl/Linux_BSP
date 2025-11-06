# 清理功能使用指南

## 🎯 概述

BSP 构建框架现已将清理功能集成到 `build.sh` 中，提供更统一、便捷的使用体验。

---

## 📋 清理命令

### 1. **智能清理（推荐）**

```bash
./build.sh clean
```

**功能**：
- ✅ 清理构建产物（bootloader-* 和 *-kernel-pkgs）
- ✅ 保留源码目录（output/linux/）
- ✅ 自动修复文件换行符
- ✅ 不需要 sudo（除非文件属于 root）

**适用场景**：
- 重新构建前清理旧文件
- 释放磁盘空间但保留源码
- 日常开发使用

---

### 2. **完全清理**

```bash
sudo ./build.sh clean --all
```

**功能**：
- ✅ 删除整个 output 目录
- ✅ 包括所有源码和构建产物
- ✅ 自动修复文件换行符
- ⚠️ 需要 sudo 权限

**适用场景**：
- 完全重新开始
- 切换到不同的内核版本
- 清理所有临时文件

---

## 🔧 使用示例

### 首次部署

```bash
cd BSP

# 1. 修复换行符（如果从 Windows 复制文件）
./build.sh clean

# 2. 开始构建
sudo ./build.sh -b test-board
```

### 日常开发

```bash
# 修改配置后重新构建
./build.sh clean
sudo ./build.sh -b test-board

# 修改源码后仅重建内核
./build.sh clean
sudo ./build.sh -b test-board -o yes -l
```

### 切换内核版本

```bash
# 完全清理
sudo ./build.sh clean --all

# 使用新配置构建
sudo ./build.sh -b test-board -g mainline
```

---

## 📊 清理对比

| 命令 | 删除构建产物 | 删除源码 | 修复换行符 | 需要 sudo |
|------|-------------|---------|-----------|-----------|
| `./build.sh clean` | ✅ | ❌ | ✅ | 可选* |
| `./build.sh clean --all` | ✅ | ✅ | ✅ | ✅ |

\* 如果构建产物属于 root 用户，则需要 sudo

---

## ⚠️ 注意事项

### 权限问题

如果看到权限错误：

```bash
⚠ Failed to remove bootloader-example (try sudo)
```

解决方法：

```bash
# 方法 1: 使用 sudo
sudo ./build.sh clean

# 方法 2: 完全清理
sudo ./build.sh clean --all
```

### 保留源码

如果想保留下载的源码：

```bash
# ✅ 使用智能清理
./build.sh clean

# ❌ 不要使用
./build.sh clean --all
```

---

## 🗑️ cleanup.sh 已废弃

`cleanup.sh` 脚本已被标记为废弃，建议使用新的命令：

```bash
# ❌ 旧方法（已废弃）
bash cleanup.sh
bash cleanup.sh --all

# ✅ 新方法（推荐）
./build.sh clean
./build.sh clean --all
```

**原因**：
- 功能统一到 build.sh
- 更直观的命令结构
- 避免维护多个脚本

---

## 📝 FAQ

**Q: 为什么清理后还有 output/linux/ 目录？**  
A: `./build.sh clean` 默认保留源码目录，使用 `clean --all` 完全删除。

**Q: 清理会删除我的配置文件吗？**  
A: 不会。清理只影响 output 目录，configs/ 目录完全不受影响。

**Q: 可以只清理某个板型的构建产物吗？**  
A: 可以手动删除：`sudo rm -rf output/bootloader-<board> output/<board>-kernel-pkgs`

**Q: 换行符修复是什么？**  
A: 将 Windows CRLF 格式转换为 Unix LF 格式，避免脚本执行错误。

---

## 🎉 总结

| 需求 | 命令 |
|------|------|
| 首次部署 | `./build.sh clean` |
| 重新构建 | `./build.sh clean` |
| 完全清理 | `sudo ./build.sh clean --all` |
| 修复换行符 | `./build.sh clean` |

**推荐工作流**：

```bash
# 1. 首次使用
./build.sh clean
sudo ./build.sh -b myboard

# 2. 修改配置
nano configs/myboard.conf
./build.sh clean
sudo ./build.sh -b myboard

# 3. 完全重来
sudo ./build.sh clean --all
sudo ./build.sh -b myboard
```

