#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

DTS_SRC="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
DTS_DST="target/linux/qualcommax/dts"
mkdir -p "$DTS_DST"

# 复制所有需要的 dtsi 文件
for f in ipq8074-512m.dtsi ipq8074-ac-cpu.dtsi ipq8074-cpr-regulator.dtsi ipq8074.dtsi; do
    if [ -f "$DTS_SRC/$f" ]; then
        cp "$DTS_SRC/$f" "$DTS_DST/$f"
        echo "✅ 复制 $f 到 $DTS_DST"
    else
        echo "⚠️ 文件 $f 不存在于 $DTS_SRC，跳过"
    fi
done

# 修改 ipq8071-ax3600.dtsi 中的 include 路径
DTS_FILE="$DTS_DST/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    # 将带路径的 include 替换为直接文件名
    sed -i 's|#include ".*/ipq8074-512m.dtsi"|#include "ipq8074-512m.dtsi"|' "$DTS_FILE"
    sed -i 's|#include ".*/ipq8074-ac-cpu.dtsi"|#include "ipq8074-ac-cpu.dtsi"|' "$DTS_FILE"
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    # 修改 rootfs 分区大小（0xf600000 = 246MB）
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0xf600000>/' "$DTS_FILE"
    # 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    echo "✅ DTS 文件已修改"
else
    echo "⚠️ 未找到 $DTS_FILE，跳过修改"
fi

# 删除整个补丁目录
rm -rf target/linux/qualcommax/patches-6.12

echo "✅ DIY 脚本执行完成"
