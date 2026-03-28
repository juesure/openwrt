#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 正确的 DTS 路径 ==========
# 注意：您的 DTS 文件在 target/linux/qualcommax/dts/ 下
DTS_DIR="target/linux/qualcommax/dts/"

# ========== 检查并修改 ipq8071-ax3600.dtsi ==========
DTS_FILE="${DTS_DIR}ipq8071-ax3600.dtsi"

if [ -f "$DTS_FILE" ]; then
    echo "✅ 找到 $DTS_FILE，检查修改..."
    
    # 检查 rootfs 大小是否已修改
    if grep -q "reg = <0xa00000 0x10000000>" "$DTS_FILE"; then
        echo "   rootfs 大小已修改"
    else
        echo "   修改 rootfs 分区大小..."
        sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0x10000000>/' "$DTS_FILE"
    fi
    
    # 检查 bootargs 是否已修改
    if grep -q "root=/dev/ubiblock0_1" "$DTS_FILE"; then
        echo "   bootargs 已修改"
    else
        echo "   修改 bootargs..."
        sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    fi
    
    echo "✅ DTS 文件检查完成"
else
    echo "❌ 找不到 $DTS_FILE"
    echo "当前目录下查找 DTS 文件："
    find target -name "ipq8071-ax3600.dtsi" 2>/dev/null
    exit 1
fi

# ========== 检查并修改 ipq8071-ax6.dts ==========
AX6_DTS="${DTS_DIR}ipq8071-ax6.dts"
if [ -f "$AX6_DTS" ]; then
    if ! grep -q "qcom,ath11k-fw-memory-mode" "$AX6_DTS"; then
        sed -i '/&wifi {/a\	qcom,ath11k-fw-memory-mode = <2>;' "$AX6_DTS"
        echo "✅ ipq8071-ax6.dts 已添加 WiFi 内存模式"
    else
        echo "✅ ipq8071-ax6.dts 已包含 WiFi 内存模式"
    fi
fi

# ========== 检查并修改 ipq807x.mk ==========
IPQ807X_MK="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "$IPQ807X_MK" ]; then
    # 修改 xiaomi_ax3600 的 SOC
    sed -i 's/SOC := ipq8074/SOC := ipq8071/' "$IPQ807X_MK"
    
    # 检查 redmi_ax6 配置是否存在
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
        echo "✅ ipq807x.mk 已添加 redmi_ax6 配置"
    else
        echo "✅ ipq807x.mk 已包含 redmi_ax6 配置"
    fi
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
