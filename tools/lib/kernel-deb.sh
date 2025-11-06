#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0
#
# Kernel Debian Package Generation Functions
# Simplified version for BSP framework

# 检查内核配置选项是否启用
is_enabled() {
    grep -q "^$1=y" include/config/auto.conf 2>/dev/null
}

# 生成 MD5 校验和
# gen_md5 <output_file> <source_path>
gen_md5(){
    pushd "$2" > /dev/null
    find . -type f ! -path './DEBIAN/*' -printf '%P\0' | xargs -r0 md5sum > "$1"
    popd > /dev/null
}

# 生成 changelog 文件
# gen_changelog <file> <package_type> <board_name> <kernel_version>
gen_changelog(){
    cat <<- CHANGELOG > "$1"
linux-${2}-${3} (${4}) stable; urgency=low

  * Kernel package for ${3}
  * Kernel version: ${4}

 -- BSP Builder <builder@localhost>  $(date -R)
CHANGELOG
}

# 生成 copyright 文件
gen_copyright(){
    cat <<- COPYRIGHT > "$1"
This package contains the Linux kernel.

The sources may be found at:
https://www.kernel.org/pub/linux/kernel

Copyright: 1991 - $(date +%Y) Linus Torvalds and others.

The git repository for mainline kernel development is at:
git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; version 2 dated June, 1991.

On Debian GNU/Linux systems, the complete text of the GNU General Public
License version 2 can be found in '/usr/share/common-licenses/GPL-2'.
COPYRIGHT
}

# 生成 DTB 包的 control 文件
# gen_dtb_control <file> <version> <board_name> <arch> <kernel_version> <size>
gen_dtb_control(){
    cat <<- CONTROL > "$1"
Package: linux-dtb-${3}
Version: ${2}
Architecture: ${4}
Maintainer: BSP Builder <builder@localhost>
Section: kernel
Priority: optional
Provides: linux-dtb
Description: Linux kernel device tree blobs for ${3}
 This package contains device tree blobs from Linux kernel version ${5}.
Installed-Size: ${6}
CONTROL
}

# 生成 DTB 包的 postinst 脚本
gen_dtb_postinst(){
    cat <<- POSTINST > "$1"
#!/bin/bash
set -e
cd /boot
if [ -d "dtb-${3}" ]; then
    rm -rf dtb 2>/dev/null || true
    mv "dtb-${3}" dtb
fi
true
POSTINST
    chmod +x "$1"
}

# 生成 DTB 包的 preinst 脚本
gen_dtb_preinst(){
    cat <<- PREINST > "$1"
#!/bin/bash
set -e
rm -rf /boot/dtb 2>/dev/null || true
rm -rf /boot/dtb-${3} 2>/dev/null || true
true
PREINST
    chmod +x "$1"
}

# 生成 Image 包的 control 文件
# gen_image_control <file> <version> <board_name> <arch> <kernel_version> <size>
gen_image_control(){
    cat <<- CONTROL > "$1"
Package: linux-image-${3}
Version: ${2}
Architecture: ${4}
Maintainer: BSP Builder <builder@localhost>
Section: kernel
Priority: optional
Provides: linux-image
Description: Linux kernel image for ${3}
 This package contains the Linux kernel version ${5}, modules and related files.
Installed-Size: ${6}
CONTROL
}

# 生成 Image 包的安装/卸载脚本
gen_image_postinst(){
    cat <<- POSTINST > "$1"
#!/bin/bash
set -e
true
POSTINST
    chmod +x "$1"
}

gen_image_postrm(){
    cat <<- POSTRM > "$1"
#!/bin/bash
set -e
true
POSTRM
    chmod +x "$1"
}

gen_image_preinst(){
    cat <<- PREINST > "$1"
#!/bin/bash
set -e
true
PREINST
    chmod +x "$1"
}

gen_image_prerm(){
    cat <<- PRERM > "$1"
#!/bin/bash
set -e
true
PRERM
    chmod +x "$1"
}

# 生成 Headers 包的 control 文件
gen_headers_control(){
    cat <<- CONTROL > "$1"
Package: linux-headers-${3}
Version: ${2}
Architecture: ${4}
Maintainer: BSP Builder <builder@localhost>
Section: devel
Priority: optional
Provides: linux-headers
Depends: make, gcc, libc6-dev, bison, flex, libssl-dev, libelf-dev
Description: Linux kernel headers for ${3}
 This package provides kernel header files for version ${5}.
 These headers are used for building external kernel modules.
Installed-Size: ${6}
CONTROL
}

# 生成 Headers 包的安装脚本
gen_headers_postinst(){
    cat <<- POSTINST > "$1"
#!/bin/bash
set -e
cd /lib/modules/${4}
rm -f build source 2>/dev/null || true
ln -sf /usr/src/linux-headers-${4} build
ln -sf /usr/src/linux-headers-${4} source
true
POSTINST
    chmod +x "$1"
}

gen_headers_preinst(){
    cat <<- PREINST > "$1"
#!/bin/bash
set -e
true
PREINST
    chmod +x "$1"
}

gen_headers_prerm(){
    cat <<- PRERM > "$1"
#!/bin/bash
set -e
true
PRERM
    chmod +x "$1"
}

# 生成 libc-dev 包的 control 文件
gen_libc_dev_control(){
    cat <<- CONTROL > "$1"
Package: linux-libc-dev-${3}
Version: ${2}
Architecture: ${4}
Maintainer: BSP Builder <builder@localhost>
Section: devel
Priority: optional
Provides: linux-libc-dev
Conflicts: linux-libc-dev
Multi-Arch: same
Description: Linux kernel headers for userspace development
 This package provides userspace headers from the Linux kernel.
 These headers are used by the installed headers for GNU glibc and other system libraries.
Installed-Size: ${6}
CONTROL
}

