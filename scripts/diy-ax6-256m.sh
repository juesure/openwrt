#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 直接修改 ipq8071-ax3600.dtsi，移除对 ipq8074-512m.dtsi 的依赖 ==========
DTS_FILE="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8071-ax3600.dtsi"

if [ -f "$DTS_FILE" ]; then
    echo "修改 ipq8071-ax3600.dtsi..."
    
    # 备份原文件
    cp "$DTS_FILE" "$DTS_FILE.bak"
    
    # 移除 #include "ipq8074-512m.dtsi" 这行
    sed -i '/#include "ipq8074-512m.dtsi"/d' "$DTS_FILE"
    
    # 在文件开头添加内存定义
    cat > "${DTS_FILE}.new" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

/ {
	#address-cells = <2>;
	#size-cells = <2>;

	memory@40000000 {
		device_type = "memory";
		reg = <0x0 0x40000000 0x0 0x20000000>;
	};

	reserved-memory {
		#address-cells = <2>;
		#size-cells = <2>;
		ranges;

		nss_reserved: nss@40000000 {
			reg = <0x0 0x40000000 0x0 0x1000000>;
			no-map;
		};

		tzapp: tzapp@4a400000 {
			reg = <0x0 0x4a400000 0x0 0x100000>;
			no-map;
		};

		bootloader: bootloader@4a600000 {
			reg = <0x0 0x4a600000 0x0 0x400000>;
			no-map;
		};

		sbl: sbl@4aa00000 {
			reg = <0x0 0x4aa00000 0x0 0x100000>;
			no-map;
		};

		smem: smem@4ab00000 {
			reg = <0x0 0x4ab00000 0x0 0x100000>;
			no-map;
		};

		memory@4ac00000 {
			reg = <0x0 0x4ac00000 0x0 0x400000>;
			no-map;
		};

		wcnss: wcnss@4b000000 {
			reg = <0x0 0x4b000000 0x0 0x3700000>;
			no-map;
		};

		q6_etr_dump: q6_etr_dump@50f00000 {
			reg = <0x0 0x4e700000 0x0 0x100000>;
			no-map;
		};

		m3_dump: m3_dump@51000000 {
			reg = <0x0 0x4e800000 0x0 0x100000>;
			no-map;
		};
	};
EOF
    
    # 将原文件剩余内容追加到新文件（跳过前4行）
    tail -n +5 "$DTS_FILE.bak" >> "${DTS_FILE}.new"
    
    # 替换原文件
    mv "${DTS_FILE}.new" "$DTS_FILE"
    
    # 修改 rootfs 分区大小
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0x10000000>/' "$DTS_FILE"
    
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    
    echo "✅ ipq8071-ax3600.dtsi 已修改"
else
    echo "❌ 找不到 $DTS_FILE"
    exit 1
fi

# ========== 修改 ipq8071-ax6.dts ==========
AX6_DTS="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8071-ax6.dts"
if [ -f "$AX6_DTS" ]; then
    # 添加 WiFi 内存模式
    if ! grep -q "qcom,ath11k-fw-memory-mode" "$AX6_DTS"; then
        sed -i '/&wifi {/a\	qcom,ath11k-fw-memory-mode = <2>;' "$AX6_DTS"
    fi
    echo "✅ ipq8071-ax6.dts 已修改"
fi

# ========== 修改 ipq807x.mk ==========
IPQ807X_MK="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "$IPQ807X_MK" ]; then
    # 修改 xiaomi_ax3600 的 SOC 为 ipq8071
    sed -i 's/SOC := ipq8074/SOC := ipq8071/' "$IPQ807X_MK"
    
    # 检查 redmi_ax6 配置是否存在，如果不存在则添加
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
