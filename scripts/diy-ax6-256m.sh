#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 自动查找 DTS 文件路径 ==========
echo "查找 DTS 文件..."

# 可能的 DTS 路径
DTS_PATHS=(
    "target/linux/qualcommax/dts/ipq8071-ax3600.dtsi"
    "target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8071-ax3600.dtsi"
    "target/linux/qualcommax/dts/ipq8071-ax3600.dtsi"
)

DTS_FILE=""
for path in "${DTS_PATHS[@]}"; do
    if [ -f "$path" ]; then
        DTS_FILE="$path"
        echo "✅ 找到 DTS 文件: $path"
        break
    fi
done

if [ -z "$DTS_FILE" ]; then
    echo "❌ 找不到 ipq8071-ax3600.dtsi"
    echo "查找目录:"
    find target -name "ipq8071-ax3600.dtsi" 2>/dev/null || echo "未找到"
    exit 1
fi

# ========== 修改 DTS 文件 ==========
echo "修改 $DTS_FILE..."

# 1. 注释掉第4行的 include
sed -i '4s|#include "ipq8074-512m.dtsi"|/* #include "ipq8074-512m.dtsi" */|' "$DTS_FILE"

# 2. 修改 rootfs 分区大小
sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0x10000000>/' "$DTS_FILE"

# 3. 修改 bootargs
sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"

echo "✅ DTS 文件已修改"

# ========== 查找并修改 ipq8071-ax6.dts ==========
AX6_PATHS=(
    "target/linux/qualcommax/dts/ipq8071-ax6.dts"
    "target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8071-ax6.dts"
)

AX6_DTS=""
for path in "${AX6_PATHS[@]}"; do
    if [ -f "$path" ]; then
        AX6_DTS="$path"
        echo "✅ 找到 AX6 DTS 文件: $path"
        break
    fi
done

if [ -n "$AX6_DTS" ]; then
    if ! grep -q "qcom,ath11k-fw-memory-mode" "$AX6_DTS"; then
        sed -i '/&wifi {/a\	qcom,ath11k-fw-memory-mode = <2>;' "$AX6_DTS"
    fi
    echo "✅ ipq8071-ax6.dts 已修改"
fi

# ========== 查找并修改 ipq807x.mk ==========
IPQ807X_PATHS=(
    "target/linux/qualcommax/image/ipq807x.mk"
)

IPQ807X_MK=""
for path in "${IPQ807X_PATHS[@]}"; do
    if [ -f "$path" ]; then
        IPQ807X_MK="$path"
        echo "✅ 找到 ipq807x.mk: $path"
        break
    fi
done

if [ -n "$IPQ807X_MK" ]; then
    # 修改 xiaomi_ax3600 的 SOC
    sed -i 's/SOC := ipq8074/SOC := ipq8071/' "$IPQ807X_MK"
    
    # 检查 redmi_ax6 配置
    if ! grep -q "define Device/redmi_ax6" "$IPQ807X_MK"; then
        cat >> "$IPQ807X_MK" << 'MKEOF'

define Device/redmi_ax6
	$(call Device/xiaomi_ax3600)
	DEVICE_VENDOR := Redmi
	DEVICE_MODEL := AX6
	IMAGE_SIZE := 245760k
	UBINIZE_OPTS := -E 5 -m 2048 -p 128KiB -s 2048 -O 2048
	KERNEL_IN_UBI := 1
	IMAGES += factory.ubi
	IMAGE/factory.ubi := append-ubi | check-size $$$$(IMAGE_SIZE)
	DEVICE_PACKAGES := ipq-wifi-redmi_ax6 \
		kmod-ath11k-ahb \
		ath11k-firmware-ipq8071 \
		ath11k-firmware-ipq8074 \
		uhttpd \
		uhttpd-mod-ubus \
		luci \
		luci-base \
		luci-mod-admin-full \
		luci-theme-argon \
		luci-app-store \
		luci-i18n-store-zh-cn \
		luci-i18n-base-zh-cn \
		coreutils \
		curl \
		wget \
		dropbear \
		block-mount
endef
TARGET_DEVICES += redmi_ax6
MKEOF
    fi
    echo "✅ ipq807x.mk 已修改"
fi

# ========== 清理联发科 ==========
if [ -f ".config" ]; then
  sed -i '/mt76/d' .config
  sed -i '/mediatek/d' .config
fi

rm -rf package/kernel/mt76
./scripts/feeds uninstall -a mt76 2>/dev/null || true

# ========== 添加 WiFi 固件修复脚本 ==========
mkdir -p files/etc/init.d
cat > files/etc/init.d/fix-wifi << 'EOF'
#!/bin/sh /etc/rc.common

START=98

start() {
    if [ -d /lib/firmware/ath11k/IPQ8074/hw2.0 ] && [ ! -f /lib/firmware/ath11k/IPQ8074/q6_fw.mdt ]; then
        cd /lib/firmware/ath11k/IPQ8074/ && ln -sf hw2.0/* . 2>/dev/null
    fi
}
EOF
chmod +x files/etc/init.d/fix-wifi

echo "✅ DIY 脚本执行完成"
