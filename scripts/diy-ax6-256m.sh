#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

DTS_DIR="target/linux/qualcommax/dts"
DTS_ARCH_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"

# 创建目录
mkdir -p "$DTS_DIR" "$DTS_ARCH_DIR"

# 将必要的 ipq8074*.dtsi 文件复制到 dts 目录（与 ipq8071-ax3600.dtsi 同目录）
for file in ipq8074.dtsi ipq8074-512m.dtsi ipq8074-ac-cpu.dtsi ipq8074-ess.dtsi; do
    src="$DTS_ARCH_DIR/$file"
    dst="$DTS_DIR/$file"
    if [ -f "$src" ]; then
        cp "$src" "$dst"
        echo "复制 $file 到 $DTS_DIR"
    else
        # 如果目标不存在，尝试从官方下载并放置到 dts 目录
        echo "下载 $file 到 $DTS_DIR ..."
        wget -q -O "$dst" "https://raw.githubusercontent.com/openwrt/openwrt/main/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/$file"
        if [ $? -ne 0 ]; then
            echo "❌ 下载 $file 失败"
            exit 1
        fi
    fi
done

# 修改 ipq8071-ax3600.dtsi 中的 include 路径（直接使用文件名，因为现在在同一目录）
DTS_FILE="$DTS_DIR/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    echo "修改 $DTS_FILE ..."
    # 将 include 中的路径去掉，只保留文件名
    sed -i 's|#include "ipq8074-512m.dtsi"|#include "ipq8074-512m.dtsi"|' "$DTS_FILE"  # 原本就没有路径，保持原样
    # 但如果有类似 #include "../../files/arch/arm64/boot/dts/qcom/ipq8074-512m.dtsi" 的路径，需要替换
    sed -i 's|#include ".*/ipq8074-512m.dtsi"|#include "ipq8074-512m.dtsi"|' "$DTS_FILE"
    sed -i 's|#include ".*/ipq8074-ac-cpu.dtsi"|#include "ipq8074-ac-cpu.dtsi"|' "$DTS_FILE"
    sed -i 's|#include ".*/ipq8074-ess.dtsi"|#include "ipq8074-ess.dtsi"|' "$DTS_FILE"
    
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

# 删除导致失败的内核补丁
PATCH_FILE="target/linux/qualcommax/patches-6.12/0036-v6.13-arm64-dts-qcom-ipq-change-labels-to-lower-case.patch"
if [ -f "$PATCH_FILE" ]; then
    echo "删除有问题的补丁: $PATCH_FILE"
    rm -f "$PATCH_FILE"
fi

echo "✅ DIY 脚本执行完成"
