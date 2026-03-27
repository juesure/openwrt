#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 清理联发科 ==========
if [ -f ".config" ]; then
  sed -i '/mt76/d' .config
  sed -i '/mediatek/d' .config
fi

rm -rf package/kernel/mt76
./scripts/feeds uninstall -a mt76 2>/dev/null || true

# ========== 锁定平台 ==========
cat > .config << EOF
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq807x=y
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y
CONFIG_TARGET_MULTI_PROFILE=n
CONFIG_TARGET_ALL_PROFILES=n
CONFIG_TARGET_mediatek=n
CONFIG_TARGET_mediatek_filogic=n
EOF

# ========== 修改 ipq807x.mk 中的 redmi_ax6 配置 ==========
IPQ807X_MK="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "${IPQ807X_MK}" ]; then
  # 备份原文件
  cp ${IPQ807X_MK} ${IPQ807X_MK}.bak
  
  # 查找 redmi_ax6 定义并修改
  # 先删除旧的 redmi_ax6 定义
  sed -i '/^define Device\/redmi_ax6/,/^endef/d' ${IPQ807X_MK}
  sed -i '/^TARGET_DEVICES += redmi_ax6/d' ${IPQ807X_MK}
  
  # 在 xiaomi_ax3600 定义后添加新的 redmi_ax6 定义
  cat >> ${IPQ807X_MK} << 'MKEOF'

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
		luci-i18n-base-zh-cn \
		luci-i18n-argon-config-zh-cn \
		luci-app-store \
		luci-lib-store \
		luci-i18n-store-zh-cn \
		store-apps
endef
TARGET_DEVICES += redmi_ax6
MKEOF
fi

# ========== 添加 WiFi 固件修复脚本 ==========
mkdir -p files/etc/init.d
cat > files/etc/init.d/fix-wifi << 'EOF'
#!/bin/sh /etc/rc.common

START=98

start() {
    # 修复 WiFi 固件路径
    if [ -d /lib/firmware/ath11k/IPQ8074/hw2.0 ] && [ ! -f /lib/firmware/ath11k/IPQ8074/q6_fw.mdt ]; then
        echo "修复 WiFi 固件路径..."
        cd /lib/firmware/ath11k/IPQ8074/
        ln -sf hw2.0/* . 2>/dev/null
        echo "WiFi 固件修复完成"
    fi
}
EOF
chmod +x files/etc/init.d/fix-wifi

# ========== 重新生成配置 ==========
make defconfig 2>/dev/null || true

echo "✅ DIY 脚本执行完成 —— 已适配256M Flash，包含 WiFi 固件修复和 iStore"
