#!/bin/bash

# BSP_T527 Documentation Viewer / 文档查看工具

DOCS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CN_DIR="${DOCS_DIR}/CN"
EN_DIR="${DOCS_DIR}/EN"

# Display header
show_header() {
    clear
    echo "=========================================="
    echo "BSP_T527 Documentation Viewer"
    echo "文档查看工具"
    echo "=========================================="
    echo ""
}

# Main menu
show_main_menu() {
    echo "Select Language / 选择语言:"
    echo ""
    echo "  1. Chinese (中文)"
    echo "  2. English"
    echo "  3. View Index (查看索引)"
    echo "  q. Quit (退出)"
    echo ""
}

# Chinese documentation menu
show_cn_menu() {
    echo "=========================================="
    echo "Chinese Documentation / 中文文档"
    echo "=========================================="
    echo ""
    echo "  1. 快速开始 (快速开始.md)"
    echo "  2. 板型配置 (板型配置.md)"
    echo "  3. 内核配置 (内核配置.md)"
    echo "  4. RootFS配置 (RootFS配置.md)"
    echo "  5. 常见问题 (常见问题.md)"
    echo "  6. 目录结构 (目录结构.md)"
    echo ""
    echo "  b. Back to main menu (返回主菜单)"
    echo "  q. Quit (退出)"
    echo ""
}

# English documentation menu
show_en_menu() {
    echo "=========================================="
    echo "English Documentation / 英文文档"
    echo "=========================================="
    echo ""
    echo "  1. Quick Start (Quick-Start.md)"
    echo "  2. Board Configuration (Board-Configuration.md)"
    echo "  3. Kernel Configuration (Kernel-Configuration.md)"
    echo "  4. RootFS Configuration (RootFS-Configuration.md)"
    echo "  5. FAQ (FAQ.md)"
    echo "  6. Directory Structure (Directory-Structure.md)"
    echo ""
    echo "  b. Back to main menu (返回主菜单)"
    echo "  q. Quit (退出)"
    echo ""
}

# Open document
open_doc() {
    local doc_path="$1"
    local doc_name="$2"
    
    if [ ! -f "$doc_path" ]; then
        echo "Warning: Document not found: ${doc_name}"
        echo "按 Enter 继续..."
        read
        return 1
    fi
    
    echo "Opening: ${doc_name}"
    echo ""
    
    # Try different viewers
    if command -v less >/dev/null 2>&1; then
        less -R "$doc_path"
    elif command -v more >/dev/null 2>&1; then
        more "$doc_path"
    elif command -v cat >/dev/null 2>&1; then
        cat "$doc_path"
        echo ""
        echo "Press Enter to continue..."
        read
    else
        echo "Error: Cannot find document viewer"
        return 1
    fi
}

# Chinese documentation handler
cn_docs_menu() {
    while true; do
        show_header
        show_cn_menu
        
        echo -n "Select document (1-6, b, q): "
        read choice
        
        case $choice in
            1)
                open_doc "${CN_DIR}/快速开始.md" "快速开始.md"
                ;;
            2)
                open_doc "${CN_DIR}/板型配置.md" "板型配置.md"
                ;;
            3)
                open_doc "${CN_DIR}/内核配置.md" "内核配置.md"
                ;;
            4)
                open_doc "${CN_DIR}/RootFS配置.md" "RootFS配置.md"
                ;;
            5)
                open_doc "${CN_DIR}/常见问题.md" "常见问题.md"
                ;;
            6)
                open_doc "${CN_DIR}/目录结构.md" "目录结构.md"
                ;;
            b|B)
                return 0
                ;;
            q|Q)
                echo ""
                echo "Goodbye!"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo "Invalid selection, please try again"
                echo ""
                sleep 2
                ;;
        esac
    done
}

# English documentation handler
en_docs_menu() {
    while true; do
        show_header
        show_en_menu
        
        echo -n "Select document (1-6, b, q): "
        read choice
        
        case $choice in
            1)
                open_doc "${EN_DIR}/Quick-Start.md" "Quick-Start.md"
                ;;
            2)
                open_doc "${EN_DIR}/Board-Configuration.md" "Board-Configuration.md"
                ;;
            3)
                open_doc "${EN_DIR}/Kernel-Configuration.md" "Kernel-Configuration.md"
                ;;
            4)
                open_doc "${EN_DIR}/RootFS-Configuration.md" "RootFS-Configuration.md"
                ;;
            5)
                open_doc "${EN_DIR}/FAQ.md" "FAQ.md"
                ;;
            6)
                open_doc "${EN_DIR}/Directory-Structure.md" "Directory-Structure.md"
                ;;
            b|B)
                return 0
                ;;
            q|Q)
                echo ""
                echo "Goodbye!"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo "Invalid selection, please try again"
                echo ""
                sleep 2
                ;;
        esac
    done
}

# Main menu handler
main_menu() {
    while true; do
        show_header
        show_main_menu
        
        echo -n "Your choice (1-3, q): "
        read choice
        
        case $choice in
            1)
                cn_docs_menu
                ;;
            2)
                en_docs_menu
                ;;
            3)
                open_doc "${DOCS_DIR}/README.md" "README.md"
                ;;
            q|Q)
                echo ""
                echo "Goodbye!"
                echo ""
                exit 0
                ;;
            *)
                echo ""
                echo "Invalid selection, please try again"
                echo ""
                sleep 2
                ;;
        esac
    done
}

# Handle command-line arguments
if [ $# -gt 0 ]; then
    # Direct file access
    if [ "$1" == "cn" ] || [ "$1" == "CN" ]; then
        cn_docs_menu
    elif [ "$1" == "en" ] || [ "$1" == "EN" ]; then
        en_docs_menu
    elif [ -f "${DOCS_DIR}/$1" ]; then
        open_doc "${DOCS_DIR}/$1" "$1"
    elif [ -f "${CN_DIR}/$1" ]; then
        open_doc "${CN_DIR}/$1" "$1"
    elif [ -f "${EN_DIR}/$1" ]; then
        open_doc "${EN_DIR}/$1" "$1"
    else
        echo "Document not found: $1"
        echo ""
        echo "Available documents:"
        echo ""
        echo "Chinese (CN):"
        ls -1 "${CN_DIR}"/*.md 2>/dev/null | sed 's|.*/|  |'
        echo ""
        echo "English (EN):"
        ls -1 "${EN_DIR}"/*.md 2>/dev/null | sed 's|.*/|  |'
        echo ""
        echo "Usage:"
        echo "  $0          - Interactive menu"
        echo "  $0 cn       - Chinese docs menu"
        echo "  $0 en       - English docs menu"
        echo "  $0 <file>   - Open specific file"
        exit 1
    fi
else
    # Interactive menu
    main_menu
fi
