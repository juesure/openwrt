#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

# 删除整个补丁目录，避免补丁冲突
rm -rf target/linux/qualcommax/patches-6.12

echo "✅ DIY 脚本执行完成"
