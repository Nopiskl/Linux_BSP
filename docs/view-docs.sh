#!/bin/bash

# BSP_T527 文档查看工具

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 显示欢迎信息
show_header() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}   ${GREEN}📚 BSP_T527 文档查看工具${NC}            ${BLUE}║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
    echo ""
}

# 显示文档列表
show_docs_menu() {
    echo -e "${YELLOW}核心文档：${NC}"
    echo ""
    echo "  ${GREEN}0${NC}. 📗 快速开始 (00-快速开始.md)"
    echo "     → 5分钟快速入门，适合所有新用户"
    echo ""
    echo "  ${GREEN}1${NC}. ⚙️  环境配置 (01-环境配置.md)"
    echo "     → 详细的环境准备和依赖安装"
    echo ""
    echo "  ${GREEN}2${NC}. 📘 构建指南 (02-构建指南.md)"
    echo "     → 完整的构建流程和高级用法"
    echo ""
    echo "  ${GREEN}3${NC}. 🗂️  RootFS配置 (03-RootFS配置.md)"
    echo "     → 根文件系统定制和软件包管理"
    echo ""
    echo "  ${GREEN}4${NC}. ❓ 常见问题 (04-常见问题.md)"
    echo "     → 24+ 常见问题快速解决方案"
    echo ""
    echo "  ${GREEN}5${NC}. 📂 目录结构 (05-目录结构.md)"
    echo "     → 项目文件组织和工具说明"
    echo ""
    echo -e "${YELLOW}其他文档：${NC}"
    echo ""
    echo "  ${GREEN}i${NC}. 📑 文档导航 (README.md)"
    echo "     → 完整的文档索引和使用指南"
    echo ""
    echo "  ${GREEN}d${NC}. 📄 文档说明 (DOCS_INFO.md)"
    echo "     → 文档体系介绍和优化说明"
    echo ""
    echo "  ${GREEN}q${NC}. 退出"
    echo ""
}

# 打开文档
open_doc() {
    local doc_file="$1"
    local doc_path="${DOCS_DIR}/${doc_file}"
    
    if [ ! -f "$doc_path" ]; then
        echo -e "${YELLOW}⚠️  文档不存在: ${doc_file}${NC}"
        return 1
    fi
    
    echo -e "${GREEN}📖 正在打开: ${doc_file}${NC}"
    echo ""
    
    # 尝试不同的查看器
    if command -v less >/dev/null 2>&1; then
        less -R "$doc_path"
    elif command -v more >/dev/null 2>&1; then
        more "$doc_path"
    elif command -v cat >/dev/null 2>&1; then
        cat "$doc_path"
        echo ""
        echo -e "${YELLOW}按 Enter 继续...${NC}"
        read
    else
        echo -e "${YELLOW}⚠️  无法找到文档查看器${NC}"
        return 1
    fi
}

# 主菜单
main_menu() {
    while true; do
        show_header
        show_docs_menu
        
        echo -n -e "${BLUE}请选择要查看的文档 (0-5, i, d, q): ${NC}"
        read choice
        
        case $choice in
            0)
                open_doc "00-快速开始.md"
                ;;
            1)
                open_doc "01-环境配置.md"
                ;;
            2)
                open_doc "02-构建指南.md"
                ;;
            3)
                open_doc "03-RootFS配置.md"
                ;;
            4)
                open_doc "04-常见问题.md"
                ;;
            5)
                open_doc "05-目录结构.md"
                ;;
            i|I)
                open_doc "README.md"
                ;;
            d|D)
                open_doc "DOCS_INFO.md"
                ;;
            q|Q)
                echo ""
                echo -e "${GREEN}👋 感谢使用 BSP_T527 文档！${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo -e "${YELLOW}⚠️  无效选择，请重试${NC}"
                echo ""
                sleep 2
                ;;
        esac
    done
}

# 如果提供了参数，直接打开文档
if [ $# -gt 0 ]; then
    if [ -f "${DOCS_DIR}/$1" ]; then
        open_doc "$1"
    else
        echo -e "${YELLOW}⚠️  找不到文档: $1${NC}"
        echo ""
        echo "可用的文档："
        ls -1 "${DOCS_DIR}"/*.md
        exit 1
    fi
else
    # 否则显示交互式菜单
    main_menu
fi
