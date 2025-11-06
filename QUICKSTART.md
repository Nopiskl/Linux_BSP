# 5分钟快速上手

## 准备

```bash
cd BSP

# 安装依赖
sudo apt-get install gcc make git bc gcc-aarch64-linux-gnu dialog

# 转换文件格式（重要！）
./build.sh clean
```

## 运行

### 最简单的方式

```bash
sudo ./build.sh
```

然后按提示选择配置。

### 使用命令行

```bash
sudo ./build.sh -b test-board
```

## 查看结果

```bash
# 查看输出
ls -la output/

# 引导程序
ls output/bootloader-test-board/

# 内核包
ls output/test-board-kernel-pkgs/*.deb
```

## 常用命令

```bash
# 仅内核
sudo ./build.sh -b test-board -o yes

# 使用本地源码
sudo ./build.sh -b test-board -l

# 配置内核
sudo ./build.sh -b test-board -k yes

# 使用 ccache 加速
sudo ./build.sh -b test-board -e yes

# 清理构建产物
./build.sh clean

# 完全清理
sudo ./build.sh clean --all
```

## 创建新板型

```bash
# 复制示例
cp configs/example.conf configs/myboard.conf

# 编辑配置
nano configs/myboard.conf

# 至少修改这些：
# - BOARD_NAME
# - ARCH
# - LINUX_REPO
# - LINUX_CONFIG

# 构建
sudo ./build.sh -b myboard
```

## 故障排查

**换行符错误？**
```bash
./build.sh clean
```

**权限错误？**
```bash
sudo ./build.sh -b test-board
```

**配置文件找不到？**
```bash
ls configs/*.conf
```

## 下一步

详细文档请查看：
- **README.md** - 完整说明
- **TEST.md** - 测试指南
- **configs/README.md** - 配置说明
