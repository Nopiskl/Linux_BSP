#!/bin/bash
#
# RootFS 配置验证脚本
# 检查所有发行版配置文件的完整性

echo "=========================================="
echo "RootFS Configuration Validator"
echo "=========================================="
echo ""

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS_COUNT=0
FAIL_COUNT=0

# 检查单个发行版
check_distro() {
    local distro=$1
    local version=$2
    local path="${BASE_DIR}/${distro}/${version}"
    
    echo "Checking ${distro}/${version}..."
    
    # 检查目录
    if [ ! -d "${path}" ]; then
        echo "  ✗ Directory not found: ${path}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        return 1
    fi
    
    # 检查包列表
    if [ -f "${path}/packages/base.list" ]; then
        local pkg_count=$(wc -w < "${path}/packages/base.list")
        echo "  ✓ base.list (${pkg_count} packages)"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  ✗ base.list not found"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    # 检查 APT 源
    if [ -d "${path}/apt-sources" ]; then
        local src_files=$(ls -1 ${path}/apt-sources/ 2>/dev/null | wc -l)
        if [ $src_files -gt 0 ]; then
            echo "  ✓ apt-sources/ (${src_files} files)"
            PASS_COUNT=$((PASS_COUNT + 1))
        else
            echo "  ✗ apt-sources/ is empty"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        echo "  ✗ apt-sources/ not found"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    echo ""
}

# Ubuntu 系列
echo "=== Ubuntu Distributions ==="
check_distro "ubuntu" "focal"
check_distro "ubuntu" "jammy"
check_distro "ubuntu" "noble"

# Debian 系列
echo "=== Debian Distributions ==="
check_distro "debian" "bullseye"
check_distro "debian" "bookworm"
check_distro "debian" "trixie"

# Overlays
echo "=== Overlays ==="
if [ -d "${BASE_DIR}/overlays/services/init-resize" ]; then
    echo "✓ overlays/services/init-resize/"
    PASS_COUNT=$((PASS_COUNT + 1))
    
    if [ -f "${BASE_DIR}/overlays/services/init-resize/init-resize.sh" ]; then
        echo "  ✓ init-resize.sh"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  ✗ init-resize.sh not found"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
    
    if [ -f "${BASE_DIR}/overlays/services/init-resize/init-resize.service" ]; then
        echo "  ✓ init-resize.service"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo "  ✗ init-resize.service not found"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
else
    echo "✗ overlays/services/init-resize/ not found"
    FAIL_COUNT=$((FAIL_COUNT + 3))
fi
echo ""

# 文档
echo "=== Documentation ==="
if [ -f "${BASE_DIR}/README.md" ]; then
    echo "✓ README.md"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "✗ README.md not found"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [ -f "${BASE_DIR}/distro-info.yaml" ]; then
    echo "✓ distro-info.yaml"
    PASS_COUNT=$((PASS_COUNT + 1))
else
    echo "✗ distro-info.yaml not found"
    FAIL_COUNT=$((FAIL_COUNT + 1))
fi
echo ""

# 总结
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo "✓ Passed: ${PASS_COUNT}"
echo "✗ Failed: ${FAIL_COUNT}"
echo ""

if [ ${FAIL_COUNT} -eq 0 ]; then
    echo "🎉 All checks passed!"
    exit 0
else
    echo "⚠️  Some checks failed. Please review the output above."
    exit 1
fi

