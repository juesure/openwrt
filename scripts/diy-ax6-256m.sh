#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

# 源路径和目标路径
SRC_DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
DST_DTS_DIR="target/linux/qualcommax/dts"

# 创建目标目录
mkdir -p "$DST_DTS_DIR"

# 复制所有 ipq8074 相关的 dtsi 文件（包括依赖文件）
echo "复制基础 DTSI 文件..."
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
    # 1. 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0| ubi.mtd=rootfs root=/dev/ubiblock0_1 rootfstype=squashfs rootwait|' "$DTS_FILE"
    # 2. 合并分区：将原来的 ubi_kernel 和 rootfs 两个分区替换为一个 rootfs UBI 分区（大小 0xf600000，即 246MB）
    # 先删除原来的 rootfs 分区定义（从 rootfs: partition@2dc0000 开始到下一个分区之前）
    sed -i '/rootfs: partition@2dc0000 {/,/};/d' "$DTS_FILE"
    # 然后将 ubi_kernel 分区改为 rootfs，并调整大小和添加 compatible
    sed -i '/partition@a00000 {/,/}/c\
			partition@a00000 {\
				label = "rootfs";\
				reg = <0xa00000 0xf600000>;\
				compatible = "openwrt,ubi";\
			};' "$DTS_FILE"
    # 删除 rsvd0 分区（因为 rootfs 已占满剩余空间，可选）
    sed -i '/partition@fa00000 {/,/}/d' "$DTS_FILE"
    # 3. 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    echo "✅ DTS 修改完成"
else
    echo "❌ 错误: 找不到 $DTS_FILE"
    exit 1
fi

# 确保 ipq8071-ax6.dts 中的 WiFi 节点正确（可选，通常无需修改）
AX6_DTS="$DST_DTS_DIR/ipq8071-ax6.dts"
if [ -f "$AX6_DTS" ]; then
    # 移除可能存在的 rootfs 覆盖（原始文件中有 &rootfs 节点，我们已合并分区，故删除）
    sed -i '/&rootfs {/,/}/d' "$AX6_DTS"
    echo "✅ 清理 ipq8071-ax6.dts"
fi

# 删除所有内核补丁（避免补丁冲突）
rm -rf target/linux/qualcommax/patches-6.12

echo "✅ DIY 脚本执行完成"
