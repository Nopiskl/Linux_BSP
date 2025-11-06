#!/bin/bash
# Line Ending Fixer
# Fix Windows CRLF line endings to Unix LF format

echo "=========================================="
echo "Line Ending Fixer"
echo "=========================================="
echo ""
echo "This tool is deprecated. Please use:"
echo "  ./build.sh clean"
echo ""
echo "Fixing line endings anyway..."
echo ""

FIXED=0

# Fix configs/
if [ -d "configs" ]; then
    find configs/ -type f \( -name "*.sh" -o -name "*.conf" \) 2>/dev/null | while read -r file; do
        if [ -f "$file" ] && file "$file" | grep -q CRLF; then
            sed -i 's/\r$//' "$file"
            echo "  ✓ Fixed $file"
            FIXED=$((FIXED + 1))
        fi
    done
fi

# Fix tools/
if [ -d "tools" ]; then
    find tools/ -type f -name "*.sh" 2>/dev/null | while read -r file; do
        if [ -f "$file" ] && file "$file" | grep -q CRLF; then
            sed -i 's/\r$//' "$file"
            echo "  ✓ Fixed $file"
            FIXED=$((FIXED + 1))
        fi
    done
fi

# Fix root scripts
for script in build.sh cleanup.sh; do
    if [ -f "$script" ] && file "$script" | grep -q CRLF; then
        sed -i 's/\r$//' "$script"
        echo "  ✓ Fixed $script"
        FIXED=$((FIXED + 1))
    fi
done

if [ $FIXED -eq 0 ]; then
    echo "  (All files already in Unix format)"
fi
echo ""

echo "=========================================="
echo "Done! Use './build.sh clean' next time."
echo "=========================================="
