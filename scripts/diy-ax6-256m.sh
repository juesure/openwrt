#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

SRC_DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
DST_DTS_DIR="target/linux/qualcommax/dts"

# 创建目标目录
mkdir -p "$DST_DTS_DIR"

# 复制所有源 DTS 文件（包括子目录）到 dts 目录，确保所有依赖都在同一位置
echo "复制所有 DTS 源文件到 $DST_DTS_DIR ..."
cp -r "$SRC_DTS_DIR"/* "$DST_DTS_DIR"/ 2>/dev/null || true

# 修改 ipq8071-ax3600.dtsi
AX3600_DTS="$DST_DTS_DIR/ipq8071-ax3600.dtsi"
if [ -f "$AX3600_DTS" ]; then
    echo "修改 $AX3600_DTS ..."
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0| ubi.mtd=rootfs root=/dev/ubiblock0_1 rootfstype=squashfs rootwait|' "$AX3600_DTS"
    
    # 修改 rootfs 分区：将原有的 ubi_kernel 分区改为 rootfs，大小设为 0xf600000 (246MB)
    # 注意：原始文件中有两个分区：ubi_kernel (0xa00000 0x23c0000) 和 rootfs (0x2dc0000 0xd240000)
    # 我们保留 ubi_kernel 的地址，但将其 label 改为 rootfs，大小改为 0xf600000，并添加 compatible
    # 然后删除原来的 rootfs 分区
    sed -i '/partition@a00000 {/,/}/c\
			partition@a00000 {\
				label = "rootfs";\
				reg = <0xa00000 0xf600000>;\
				compatible = "openwrt,ubi";\
			};' "$AX3600_DTS"
    
    # 删除原来的 rootfs 分区定义（位于 @2dc0000）
    sed -i '/rootfs: partition@2dc0000 {/,/}/d' "$AX3600_DTS"
    
    # 添加 rsvd0 分区（可选）
    sed -i '/partition@a00000 {/a\
\
			partition@fa00000 {\
				label = "rsvd0";\
				reg = <0xfa00000 0x80000>;\
				read-only;\
			};' "$AX3600_DTS"
    
    # 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$AX3600_DTS"
    
    echo "✅ $AX3600_DTS 已修改"
else
    echo "❌ 错误：找不到 $AX3600_DTS"
    exit 1
fi

# 修改 ipq8071-ax6.dts（移除可能存在的 rootfs 覆盖）
AX6_DTS="$DST_DTS_DIR/ipq8071-ax6.dts"
if [ -f "$AX6_DTS" ]; then
    # 删除可能覆盖 rootfs 的 &rootfs 节点
    sed -i '/&rootfs {/,/}/d' "$AX6_DTS"
    echo "✅ $AX6_DTS 已清理（移除 rootfs 覆盖）"
fi

# 删除整个补丁目录，避免补丁冲突
rm -rf target/linux/qualcommax/patches-6.12
echo "✅ 已删除补丁目录"

echo "✅ DIY 脚本执行完成"
