# 构建工具说明

本目录包含构建工具脚本，由主脚本 `build.sh` 自动调用。

## 工具列表

### get-sources.sh
获取内核和引导程序源码。

**参数**：
- `-b <board>` - 板型名称
- `-i <url>` - GitHub 镜像地址
- `-g <target>` - 内核目标

**功能**：创建模拟的源码目录结构。

### build-boot.sh
构建引导程序。

**参数**：
- `-b <board>` - 板型名称

**功能**：创建引导程序文件和标记。

### build-kernel.sh
构建内核。

**参数**：
- `-b <board>` - 板型名称
- `-k <yes/no>` - 是否运行 menuconfig
- `-g <target>` - 内核目标
- `-e <yes/no>` - 是否使用 ccache

**功能**：创建内核包和标记。

## 使用说明

这些工具通常由 `build.sh` 自动调用，无需手动运行。

如需单独测试某个工具：

```bash
cd output
bash ../tools/get-sources.sh -b test-board
bash ../tools/build-boot.sh -b test-board
bash ../tools/build-kernel.sh -b test-board
```

## 当前版本

当前为**测试版本**，仅输出调试信息和创建模拟文件。

要实现真实构建功能，需要：
1. 参考主构建系统的实现（`../scripts/`）
2. 添加真实的编译逻辑
3. 处理补丁、编译、打包等步骤

## 扩展这些工具

参考主构建系统的对应脚本：
- `../scripts/fetch.sh` - 真实的源码获取逻辑
- `../scripts/mkbootloader.sh` - 真实的引导程序构建
- `../scripts/mklinux.sh` - 真实的内核构建
