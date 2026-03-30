#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

DTS_DIR="target/linux/qualcommax/dts"
mkdir -p "$DTS_DIR"

# 源文件目录（files 下的 DTS）
SRC_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"

# 复制所有依赖的 dtsi 文件到 dts 目录
for f in ipq8074.dtsi ipq8074-512m.dtsi ipq8074-ac-cpu.dtsi; do
    if [ -f "$SRC_DIR/$f" ]; then
        cp "$SRC_DIR/$f" "$DTS_DIR/$f"
        echo "✅ 复制 $f 到 $DTS_DIR"
    else
        echo "⚠️ 源文件 $SRC_DIR/$f 不存在，跳过"
    fi
done

# 修改 ipq8071-ax3600.dtsi 中的 include 路径和参数
DTS_FILE="$DTS_DIR/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    # 将 include 中的长路径替换为直接文件名
    sed -i 's|#include "../../files/arch/arm64/boot/dts/qcom/ipq8074-512m.dtsi"|#include "ipq8074-512m.dtsi"|' "$DTS_FILE"
    sed -i 's|#include "../../files/arch/arm64/boot/dts/qcom/ipq8074-ac-cpu.dtsi"|#include "ipq8074-ac-cpu.dtsi"|' "$DTS_FILE"
    sed -i 's|#include "../../files/arch/arm64/boot/dts/qcom/ipq8074-ess.dtsi"|#include "ipq8074-ess.dtsi"|' "$DTS_FILE"
    
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    # 修改 rootfs 分区大小（从 0xf000000 改为 0xf600000）
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0xf600000>/' "$DTS_FILE"
    # 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    echo "✅ DTS 文件已修改"
else
    echo "⚠️ 未找到 $DTS_FILE，跳过修改"
fi

# 删除有问题的内核补丁目录
rm -rf target/linux/qualcommax/patches-6.12

echo "✅ DIY 脚本执行完成"
