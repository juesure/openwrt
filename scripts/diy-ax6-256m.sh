#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

# 删除导致失败的内核补丁
PATCH_FILE="target/linux/qualcommax/patches-6.12/0036-v6.13-arm64-dts-qcom-ipq-change-labels-to-lower-case.patch"
if [ -f "$PATCH_FILE" ]; then
    echo "删除有问题的补丁: $PATCH_FILE"
    rm -f "$PATCH_FILE"
fi

# 修改 ipq8071-ax3600.dtsi 中的 bootargs 和 rootfs 分区
DTS_FILE="target/linux/qualcommax/dts/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    echo "修改 $DTS_FILE ..."
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    # 修改 rootfs 分区大小（使用 0xf600000 即 246MB，避免溢出）
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0xf600000>/' "$DTS_FILE"
    # 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    echo "✅ DTS 修改完成"
else
    echo "⚠️ 未找到 $DTS_FILE，跳过修改"
fi

echo "✅ DIY 脚本执行完成"
