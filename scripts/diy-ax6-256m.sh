#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

# 创建 DTS 目录
DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
mkdir -p "$DTS_DIR"

# 下载缺失的 ipq8074 系列 dtsi 文件
for file in ipq8074.dtsi ipq8074-512m.dtsi ipq8074-ac-cpu.dtsi ipq8074-ess.dtsi; do
    if [ ! -f "$DTS_DIR/$file" ]; then
        echo "下载 $file ..."
        wget -q -O "$DTS_DIR/$file" "https://raw.githubusercontent.com/openwrt/openwrt/main/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/$file"
        if [ $? -ne 0 ]; then
            echo "❌ 下载 $file 失败"
            exit 1
        fi
    fi
done

# 删除有问题的内核补丁
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
