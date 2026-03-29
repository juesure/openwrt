#!/bin/bash
WORK_DIR="/home/runner/work/openwrt/openwrt/workdir"
OPENWRT_DIR="$WORK_DIR/openwrt"
cd "$OPENWRT_DIR" || exit 1

echo "✅ DIY 脚本：检查 DTS 文件..."
if [ -f target/linux/qualcommax/dts/ipq8071-ax3600.dtsi ]; then
    echo "   ipq8071-ax3600.dtsi 存在"
else
    echo "❌ 错误：ipq8071-ax3600.dtsi 不存在"
    exit 1
fi
echo "✅ 准备就绪"
