#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

# 删除所有我们添加的额外 dtsi 文件（如果存在）
rm -f target/linux/qualcommax/dts/ipq8074-common.dtsi
rm -f target/linux/qualcommax/dts/ipq8074-512m.dtsi
rm -f target/linux/qualcommax/dts/ipq8074-ac-cpu.dtsi
rm -f target/linux/qualcommax/dts/ipq8074-ess.dtsi

# 修改 ipq8071-ax3600.dtsi
DTS_FILE="target/linux/qualcommax/dts/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    # 修改 rootfs 分区大小（使用 0xf600000 即 246MB）
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0xf600000>/' "$DTS_FILE"
    # 修改 WiFi 内存模式（在 &wifi 节点中）
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    echo "✅ DTS 文件已修改"
else
    echo "⚠️ 未找到 $DTS_FILE，跳过修改"
fi

# 删除整个补丁目录（避免所有补丁冲突）
rm -rf target/linux/qualcommax/patches-6.12

echo "✅ DIY 脚本执行完成"
