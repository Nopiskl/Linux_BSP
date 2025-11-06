#!/bin/bash
#
# SPDX-License-Identifier: GPL-3.0
#
# First Boot Partition Resize Script
# Automatically expand root partition to use full disk

set -e

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a /var/log/init-resize.log
}

log "=========================================="
log "First Boot Partition Resize"
log "=========================================="

# 获取根分区信息
ROOT_PART=$(findmnt -n -o SOURCE /)
ROOT_DEV=$(lsblk -no pkname ${ROOT_PART})
PART_NUM=$(echo ${ROOT_PART} | grep -oE '[0-9]+$')

log "Root partition: ${ROOT_PART}"
log "Root device: /dev/${ROOT_DEV}"
log "Partition number: ${PART_NUM}"

# 检查是否需要调整大小
PART_SIZE=$(lsblk -bno SIZE ${ROOT_PART})
DEV_SIZE=$(lsblk -bno SIZE /dev/${ROOT_DEV})
FREE_SPACE=$((DEV_SIZE - PART_SIZE))

log "Partition size: ${PART_SIZE} bytes"
log "Device size: ${DEV_SIZE} bytes"
log "Free space: ${FREE_SPACE} bytes"

# 如果剩余空间小于 100MB，则不需要调整
if [ ${FREE_SPACE} -lt 104857600 ]; then
    log "Free space < 100MB, no need to resize"
    log "Disabling init-resize service..."
    systemctl disable init-resize.service
    exit 0
fi

log "Resizing partition..."

# 使用 parted 调整分区表
parted -s /dev/${ROOT_DEV} resizepart ${PART_NUM} 100% || {
    log "ERROR: Failed to resize partition"
    exit 1
}

# 通知内核重新读取分区表
partprobe /dev/${ROOT_DEV} || {
    log "WARNING: partprobe failed, will resize on next boot"
    exit 0
}

# 调整文件系统大小
log "Resizing filesystem..."
resize2fs ${ROOT_PART} || {
    log "ERROR: Failed to resize filesystem"
    exit 1
}

# 禁用此服务（仅运行一次）
log "Disabling init-resize service..."
systemctl disable init-resize.service

log "Partition resize completed successfully!"
log "=========================================="

exit 0

