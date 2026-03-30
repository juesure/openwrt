#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
mkdir -p "$DTS_DIR"

# 下载缺失的 ipq8074 系列 dtsi 文件
for file in ipq8074.dtsi ipq8074-512m.dtsi ipq8074-ac-cpu.dtsi ipq8074-ess.dtsi; do
    if [ ! -f "$DTS_DIR/$file" ]; then
        echo "下载 $file ..."
        wget -q -O "$DTS_DIR/$file" "https://raw.githubusercontent.com/openwrt/openwrt/main/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/$file"
    fi
done

# 修改 ipq8071-ax3600.dtsi 中的 bootargs 和 rootfs 分区
DTS_FILE="target/linux/qualcommax/dts/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0x10000000>/' "$DTS_FILE"
    # 可选：修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
fi

echo "✅ DTS 准备完成"
