#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 1. 创建 ipq8074-ess.dtsi ==========
mkdir -p target/linux/qualcommax/dts/
cat > target/linux/qualcommax/dts/ipq8074-ess.dtsi << 'EOF'
#define ESS_PORT0			0
#define ESS_PORT1			1
#define ESS_PORT2			2
#define ESS_PORT3			3
#define ESS_PORT4			4
#define ESS_PORT5			5
#define ESS_PORT6			6
#define ESS_PORT7			7

#define MAC_MODE_PSGMII		0
#define MAC_MODE_SGMII		1
#define MAC_MODE_QSGMII		2
EOF

# ========== 2. 修改 ipq8071-ax3600.dtsi ==========
DTS_FILE="target/linux/qualcommax/dts/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    # 在文件开头插入必要的头文件
    sed -i '1i #include <dt-bindings/interrupt-controller/arm-gic.h>\n#include <dt-bindings/clock/qcom,gcc-ipq8074.h>\n#include <dt-bindings/reset/qcom,gcc-ipq8074.h>\n#include <dt-bindings/gpio/gpio.h>\n#include <dt-bindings/input/input.h>' "$DTS_FILE"
    
    # 修改 rootfs 分区大小
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0x10000000>/' "$DTS_FILE"
    
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    
    # 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    
    echo "✅ DTS 文件已修改"
fi

# ========== 3. 修改 ipq807x.mk ==========
MK_FILE="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "$MK_FILE" ]; then
    # 修改 xiaomi_ax3600 的 SOC
    sed -i 's/SOC := ipq8074/SOC := ipq8071/' "$MK_FILE"
    
    # 添加 redmi_ax6 配置（如果不存在）
    if ! grep -q "define Device/redmi_ax6" "$MK_FILE"; then
        cat >> "$MK_FILE" << 'MKEOF'

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

# ========== 4. 清理联发科 ==========
if [ -f ".config" ]; then
  sed -i '/mt76/d' .config
  sed -i '/mediatek/d' .config
fi

rm -rf package/kernel/mt76
./scripts/feeds uninstall -a mt76 2>/dev/null || true

# ========== 5. 添加 WiFi 固件修复脚本 ==========
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
