# 目录结构重构说明

## 📋 变更概述

BSP_T527 进行了重大目录结构重构，将原来的 `os/` 和 `target/` 目录合并为统一的 `rootfs/` 目录，提供更清晰、更易维护的组织结构。

## 🔄 变更对比

### 旧结构 (v1.0)

```
BSP_T527/
├── os/
│   ├── jammy/
│   │   ├── base-packages.list
│   │   └── apt-list/
│   │       └── sources.list
│   └── bookworm/
│       ├── base-packages.list
│       └── apt-list/
│           └── debian.sources
└── target/
    └── services/
        └── init-resize/
```

**问题**:
- ❌ 仅支持 2 个发行版
- ❌ `os/` 和 `target/` 分离不清晰
- ❌ 缺少版本信息
- ❌ 扩展性差

### 新结构 (v2.0)

```
BSP_T527/
└── rootfs/                      # 统一根目录
    ├── ubuntu/                  # Ubuntu 发行版系列
    │   ├── focal/              # 20.04 LTS
    │   │   ├── packages/
    │   │   │   └── base.list
    │   │   └── apt-sources/
    │   │       └── sources.list
    │   ├── jammy/              # 22.04 LTS ⭐
    │   │   ├── packages/
    │   │   │   └── base.list
    │   │   └── apt-sources/
    │   │       └── sources.list
    │   └── noble/              # 24.04 LTS
    │       ├── packages/
    │       │   └── base.list
    │       └── apt-sources/
    │           └── ubuntu.sources
    │
    ├── debian/                  # Debian 发行版系列
    │   ├── bullseye/           # 11
    │   │   ├── packages/
    │   │   │   └── base.list
    │   │   └── apt-sources/
    │   │       └── debian.sources
    │   ├── bookworm/           # 12 ⭐
    │   │   ├── packages/
    │   │   │   └── base.list
    │   │   └── apt-sources/
    │   │       └── debian.sources
    │   └── trixie/             # 13 (Testing)
    │       ├── packages/
    │       │   └── base.list
    │       └── apt-sources/
    │           └── debian.sources
    │
    ├── overlays/                # 系统覆盖文件
    │   ├── common/             # 通用配置
    │   └── services/           # 系统服务
    │       └── init-resize/    # 首次启动服务
    │
    ├── scripts/                 # 辅助脚本
    ├── distro-info.yaml        # 发行版信息
    └── README.md               # 详细说明
```

**优势**:
- ✅ 支持 6 个发行版（3 Ubuntu + 3 Debian）
- ✅ 清晰的层次结构
- ✅ 统一的 `rootfs/` 根目录
- ✅ 完整的版本信息
- ✅ 易于扩展新发行版
- ✅ 分离 overlays 和服务

## 🆕 新增发行版

### Ubuntu 系列

| 版本 | 代号 | LTS | 状态 |
|------|------|-----|------|
| 20.04 | Focal | ✅ | ⚪ 支持 |
| 22.04 | Jammy | ✅ | ⭐ 推荐 |
| 24.04 | Noble | ✅ | ⭐ 新增 |

### Debian 系列

| 版本 | 代号 | 状态 |
|------|------|------|
| 11 | Bullseye | ⚪ 支持 |
| 12 | Bookworm | ⭐ 推荐 |
| 13 | Trixie | ⚪ 测试版 |

## 📝 文件路径变更

### 包列表

| 旧路径 | 新路径 |
|--------|--------|
| `os/jammy/base-packages.list` | `rootfs/ubuntu/jammy/packages/base.list` |
| `os/bookworm/base-packages.list` | `rootfs/debian/bookworm/packages/base.list` |

### APT 源配置

| 旧路径 | 新路径 |
|--------|--------|
| `os/jammy/apt-list/sources.list` | `rootfs/ubuntu/jammy/apt-sources/sources.list` |
| `os/bookworm/apt-list/debian.sources` | `rootfs/debian/bookworm/apt-sources/debian.sources` |

### 系统服务

| 旧路径 | 新路径 |
|--------|--------|
| `target/services/init-resize/` | `rootfs/overlays/services/init-resize/` |

## 🔧 命令行变更

### 旧命令格式

```bash
# 仅支持版本代号
sudo bash tools/build-rootfs.sh -b example -v jammy -t cli
sudo bash tools/build-rootfs.sh -b example -v bookworm -t cli
```

### 新命令格式

```bash
# 方式 1: 完整路径（推荐）
sudo bash tools/build-rootfs.sh -b example -v ubuntu/jammy -t cli
sudo bash tools/build-rootfs.sh -b example -v debian/bookworm -t cli

# 方式 2: 简写（向后兼容）
sudo bash tools/build-rootfs.sh -b example -v jammy -t cli
sudo bash tools/build-rootfs.sh -b example -v bookworm -t cli
```

**说明**: 
- ✅ 新格式明确指定发行版类型
- ✅ 向后兼容旧格式（自动检测）
- ⭐ 建议使用完整路径格式

## 🚀 迁移步骤

### 如果你有自定义配置

#### 1. 备份旧配置

```bash
cp -r os/ os.backup
cp -r target/ target.backup
```

#### 2. 迁移包列表

```bash
# Ubuntu Jammy
cp os/jammy/base-packages.list rootfs/ubuntu/jammy/packages/base.list

# Debian Bookworm
cp os/bookworm/base-packages.list rootfs/debian/bookworm/packages/base.list
```

#### 3. 迁移 APT 源

```bash
# Ubuntu Jammy
cp os/jammy/apt-list/sources.list rootfs/ubuntu/jammy/apt-sources/

# Debian Bookworm
cp os/bookworm/apt-list/debian.sources rootfs/debian/bookworm/apt-sources/
```

#### 4. 更新脚本调用

```bash
# 旧命令
-v jammy

# 新命令（推荐）
-v ubuntu/jammy

# 或保持不变（自动检测）
-v jammy
```

### 如果你使用默认配置

无需迁移，直接使用新格式即可！

## 📚 新功能

### 1. 发行版信息文件

`rootfs/distro-info.yaml` 包含所有支持发行版的详细信息：

```yaml
ubuntu:
  jammy:
    version: "22.04"
    lts: true
    eol_date: "2027-04"
    recommended: true
```

### 2. Overlays 系统

新增 `rootfs/overlays/` 目录用于系统覆盖文件：

```
overlays/
├── common/          # 所有发行版通用
│   ├── etc/
│   ├── usr/
│   └── opt/
└── services/        # SystemD 服务
    └── init-resize/
```

使用方法：

```bash
# 添加自定义脚本
cat > rootfs/overlays/common/usr/local/bin/my-script.sh <<EOF
#!/bin/bash
echo "Custom script"
EOF

# 添加新服务
mkdir -p rootfs/overlays/services/my-service
```

### 3. 详细文档

新增完整的 `rootfs/README.md`，包含：
- 📖 完整目录结构说明
- 🎯 发行版选择指南
- 📦 包列表管理
- 🔧 自定义配置
- 🐛 故障排除

## ✅ 验证新结构

### 查看目录结构

```bash
tree -L 3 rootfs/
```

### 列出所有支持的发行版

```bash
ls -1 rootfs/*/*/packages/base.list | sed 's|rootfs/||;s|/packages/base.list||'
```

预期输出：
```
ubuntu/focal
ubuntu/jammy
ubuntu/noble
debian/bullseye
debian/bookworm
debian/trixie
```

### 测试构建

```bash
cd output

# Ubuntu 22.04
sudo bash ../tools/build-rootfs.sh -b example -v ubuntu/jammy -t cli

# Debian 12
sudo bash ../tools/build-rootfs.sh -b example -v debian/bookworm -t cli
```

## 🎓 最佳实践

### 选择发行版

1. **生产环境**: Ubuntu Jammy 或 Debian Bookworm
2. **开发环境**: Ubuntu Jammy (包更新)
3. **最新特性**: Ubuntu Noble
4. **长期稳定**: Debian Bookworm

### 命名规范

```bash
# 推荐：使用完整路径
-v ubuntu/jammy
-v debian/bookworm

# 可用：简写（自动检测）
-v jammy
-v bookworm
```

### 自定义包列表

```bash
# 编辑基础包
nano rootfs/ubuntu/jammy/packages/base.list

# 添加桌面包（新建文件）
nano rootfs/ubuntu/jammy/packages/desktop-xfce.list
```

## 🔗 相关文档

- [RootFS 详细说明](rootfs/README.md)
- [构建详细指南](ROOTFS_BUILD.md)
- [快速开始](QUICKSTART_ROOTFS.md)
- [项目总结](SUMMARY.md)

## 💡 常见问题

### Q1: 旧命令还能用吗？

✅ 可以！构建脚本自动检测版本代号并转换为新格式。

```bash
# 旧格式（仍然有效）
-v jammy  # 自动识别为 ubuntu/jammy
-v bookworm  # 自动识别为 debian/bookworm
```

### Q2: 如何添加新的发行版？

参考 [rootfs/README.md](rootfs/README.md) 中的"添加新发行版"章节。

### Q3: 旧的 os/ 目录删除了吗？

✅ 是的，旧的 `os/` 和 `target/` 目录已被删除，所有内容已迁移到 `rootfs/`。

### Q4: 如何恢复旧结构？

如果需要回退，可以从 Git 历史恢复：

```bash
git checkout <commit-before-migration> -- os/ target/
```

## 📊 统计对比

| 项目 | 旧结构 | 新结构 | 改进 |
|------|--------|--------|------|
| 支持发行版 | 2 | 6 | +300% |
| Ubuntu 版本 | 1 | 3 | +200% |
| Debian 版本 | 1 | 3 | +200% |
| 文档页数 | 2 | 5+ | +150% |
| 目录层次 | 混乱 | 清晰 | ✅ |
| 可扩展性 | 低 | 高 | ✅ |

## 🎉 总结

这次重构带来了：

1. ✅ **更多选择**: 6 个发行版可选
2. ✅ **更清晰**: 统一的 `rootfs/` 目录
3. ✅ **更灵活**: Overlays 系统
4. ✅ **更完善**: 详细的文档
5. ✅ **向后兼容**: 旧命令仍然有效

**升级建议**: 🌟 立即升级到新结构！

---

**迁移日期**: 2025-11-06
**版本**: v2.0
**作者**: BSP_T527 Project

