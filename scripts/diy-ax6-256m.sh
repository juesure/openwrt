#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

# 删除所有可能冲突的内核补丁
rm -rf target/linux/qualcommax/patches-6.12

DTS_FILE="target/linux/qualcommax/dts/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    # 确保 include 路径正确（使用原始相对路径）
    # 如果文件中已经是正确路径，以下命令不会修改；如果被改坏了，则恢复
    sed -i 's|#include "ipq8074-512m.dtsi"|#include "../../files/arch/arm64/boot/dts/qcom/ipq8074-512m.dtsi"|' "$DTS_FILE"
    sed -i 's|#include "ipq8074-ac-cpu.dtsi"|#include "../../files/arch/arm64/boot/dts/qcom/ipq8074-ac-cpu.dtsi"|' "$DTS_FILE"
    sed -i 's|#include "ipq8074-ess.dtsi"|#include "../../files/arch/arm64/boot/dts/qcom/ipq8074-ess.dtsi"|' "$DTS_FILE"
    
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    # 修改 rootfs 分区大小（从 0xf000000 改为 0xf600000）
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0xf600000>/' "$DTS_FILE"
    # 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    
    echo "✅ DTS 文件已修复并修改参数"
else
    echo "❌ 错误：找不到 $DTS_FILE"
    exit 1
fi

echo "✅ DIY 脚本执行完成"
