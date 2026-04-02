#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

SRC_DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
DST_DTS_DIR="target/linux/qualcommax/dts"
mkdir -p "$DST_DTS_DIR"

# 复制所有必需的 dtsi 文件（包括 ipq8074.dtsi）
for f in ipq8074.dtsi ipq8074-512m.dtsi ipq8074-ac-cpu.dtsi ipq8074-ess.dtsi ipq8074-hk-cpu.dtsi ipq8074-cpr-regulator.dtsi; do
    if [ -f "$SRC_DTS_DIR/$f" ]; then
        cp "$SRC_DTS_DIR/$f" "$DST_DTS_DIR/$f"
        echo "✅ 复制 $f"
    else
        echo "⚠️ 警告: $SRC_DTS_DIR/$f 不存在，跳过"
    fi
done

# 修改 ipq8071-ax3600.dtsi
DTS_FILE="$DST_DTS_DIR/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    echo "修改 $DTS_FILE ..."
    # bootargs
    sed -i 's|root=/dev/ubiblock0_0| ubi.mtd=rootfs root=/dev/ubiblock0_1 rootfstype=squashfs rootwait|' "$DTS_FILE"
    # 合并分区：删除原 rootfs 分区，修改 ubi_kernel 为 rootfs，大小 0xf600000
    sed -i '/rootfs: partition@2dc0000 {/,/}/d' "$DTS_FILE"
    sed -i '/partition@a00000 {/,/}/c\
			partition@a00000 {\
				label = "rootfs";\
				reg = <0xa00000 0xf600000>;\
				compatible = "openwrt,ubi";\
			};' "$DTS_FILE"
    sed -i '/partition@fa00000 {/,/}/d' "$DTS_FILE"
    # WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    echo "✅ DTS 修改完成"
else
    echo "❌ 错误: 找不到 $DTS_FILE"
    exit 1
fi

# 删除补丁目录
rm -rf target/linux/qualcommax/patches-6.12

echo "✅ DIY 脚本执行完成"
