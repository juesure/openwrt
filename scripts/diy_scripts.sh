#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

SRC_DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
DST_DTS_DIR="target/linux/qualcommax/dts"
mkdir -p "$DST_DTS_DIR"

# 复制所有必要的 dtsi 文件到 dts 目录
for f in ipq8074-512m.dtsi ipq8074-ac-cpu.dtsi ipq8074-ess.dtsi ipq8074-cpr-regulator.dtsi ipq8074.dtsi; do
    if [ -f "$SRC_DTS_DIR/$f" ]; then
        cp "$SRC_DTS_DIR/$f" "$DST_DTS_DIR/$f"
        echo "✅ 复制 $f"
    else
        echo "⚠️ 警告: $SRC_DTS_DIR/$f 不存在，跳过"
    fi
done


# 删除内核补丁目录（避免补丁冲突）
rm -rf target/linux/qualcommax/patches-6.12

echo "✅ DIY 脚本执行完成"
