#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 创建缺失的 common.mk（qualcommax 平台专用）==========
echo "创建 target/linux/qualcommax/image/common.mk..."
mkdir -p target/linux/qualcommax/image/
cat > target/linux/qualcommax/image/common.mk << 'CMKEOF'
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2021 Robert Marko <robimarko@gmail.com>

# Common build definitions for IPQ807x

define Build/append-dtb
	cat $(KDIR)/image-$(DEVICE_DTS).dtb >> $@
endef

define Build/append-rootfs
	cat $(KDIR)/rootfs.$(1) >> $@
endef

define Build/append-ubi
	cat $(KDIR)/rootfs.ubi >> $@
endef

define Build/check-size
	@if [ $$(stat -c%s $@) -gt $(1) ]; then \
		echo "Error: $@ exceeds $(1) bytes"; \
		exit 1; \
	fi
endef

define Build/ubinize-kernel
	mkdir -p $(KDIR)/tmp
	$(STAGING_DIR_HOST)/bin/ubinize -o $@ -p 128KiB -m 2048 -s 2048 -O 2048 \
		$(foreach vol,$(1),-v $(vol)) \
		$(KDIR)/tmp/ubinize.cfg
endef

define Build/fit
	$(TOPDIR)/scripts/mkits.sh \
		-o $(KDIR)/tmp/$(DEVICE_NAME).its -k $@ \
		-d $(KDIR)/image-$(DEVICE_DTS).dtb
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -f $(KDIR)/tmp/$(DEVICE_NAME).its $@.new
	mv $@.new $@
endef

define Build/ubi
	rm -rf $(KDIR)/tmp/ubi
	mkdir -p $(KDIR)/tmp/ubi
	$(foreach vol,$(1), \
		$(STAGING_DIR_HOST)/bin/ubinize -o $(KDIR)/tmp/ubi/$(vol).img \
			-p $(BLOCKSIZE) -m $(PAGESIZE) -s 2048 -O 2048 \
			-v $(vol) $(KDIR)/tmp/ubi/$(vol).cfg;)
	cat $(KDIR)/tmp/ubi/*.img >> $@
endef
CMKEOF

# ========== 创建 ipq807x.mk ==========
echo "创建 ipq807x.mk..."
cat > target/linux/qualcommax/image/ipq807x.mk << 'MKEOF'
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2021 Robert Marko <robimarko@gmail.com>

include ./common.mk

define Build/asus-fake-ramdisk
	rm -rf $(KDIR)/tmp/fakerd
	dd if=/dev/zero bs=32 count=1 > $(KDIR)/tmp/fakerd
endef

define Build/asus-fake-rootfs
	$(eval comp=$(word 1,$(1)))
	$(eval filepath=$(word 2,$(1)))
	$(eval filecont=$(word 3,$(1)))
	rm -rf $(KDIR)/tmp/fakefs $(KDIR)/tmp/fakehsqs
	mkdir -p $(KDIR)/tmp/fakefs/$$(dirname $(filepath))
	echo '$(filecont)' > $(KDIR)/tmp/fakefs/$(filepath)
	$(STAGING_DIR_HOST)/bin/mksquashfs4 $(KDIR)/tmp/fakefs $(KDIR)/tmp/fakehsqs -comp $(comp) \
		-b 4096 -no-exports -no-sparse -no-xattrs -all-root -noappend \
		$(wordlist 4,$(words $(1)),$(1))
endef

define Build/asus-trx
	$(STAGING_DIR_HOST)/bin/asusuimage $(wordlist 1,$(words $(1)),$(1)) -i $@ -o $@.new
	mv $@.new $@
endef

define Build/netgear-rbx750-qsdk-ipq-factory
	$(CP) $(FLASH_SCRIPT) $(KDIR_TMP)/
	echo "VERSION : V8.0.0.0_$(LINUX_VERSION)" > $@.metadata
	echo "MODEL_ID : $(DEVICE_MODEL)" >> $@.metadata
	$(TOPDIR)/scripts/mkits-qsdk-ipq-image.sh $@.its $(FLASH_SCRIPT) txt $@.metadata ubi $@
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -f $@.its $@.new
	@mv $@.new $@
endef

define Build/wax6xx-netgear-tar
	mkdir $@.tmp
	mv $@ $@.tmp/nand-ipq807x-apps.img
	md5sum $@.tmp/nand-ipq807x-apps.img | cut -c 1-32 > $@.tmp/nand-ipq807x-apps.md5sum
	echo $(DEVICE_MODEL) > $@.tmp/metadata.txt
	echo $(DEVICE_MODEL)"_V99.9.9.9" > $@.tmp/version
	tar -C $@.tmp/ -cf $@ .
	rm -rf $@.tmp
endef

define Build/zyxel-nwax10ax-fit
	$(TOPDIR)/scripts/mkits-zyxel-fit-filogic.sh \
		$@.its $@ "$(ZYXEL_MODEL_ID) ff ff ff ff ff ff ff ff"
	PATH=$(LINUX_DIR)/scripts/dtc:$(PATH) mkimage -f $@.its $@.new
	@mv $@.new $@
endef

define Device/xiaomi_ax3600
	$(call Device/FitImage)
	$(call Device/UbiFit)
	DEVICE_VENDOR := Xiaomi
	DEVICE_MODEL := AX3600
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	DEVICE_DTS_CONFIG := config@ac04
	SOC := ipq8071
	KERNEL_SIZE := 36608k
	DEVICE_PACKAGES := ipq-wifi-xiaomi_ax3600
endef
TARGET_DEVICES += xiaomi_ax3600

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

# ========== 创建 ipq8074-ess.dtsi ==========
echo "创建 ipq8074-ess.dtsi..."
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

# ========== 修改 ipq8071-ax3600.dtsi ==========
DTS_FILE="target/linux/qualcommax/dts/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    echo "修改 $DTS_FILE..."
    sed -i 's|#include "ipq8074-512m.dtsi"|/* #include "ipq8074-512m.dtsi" */|' "$DTS_FILE"
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0x10000000>/' "$DTS_FILE"
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    echo "✅ DTS 文件已修改"
fi

# ========== 修改 ipq8071-ax6.dts ==========
AX6_DTS="target/linux/qualcommax/dts/ipq8071-ax6.dts"
if [ -f "$AX6_DTS" ]; then
    if ! grep -q "qcom,ath11k-fw-memory-mode" "$AX6_DTS"; then
        sed -i '/&wifi {/a\	qcom,ath11k-fw-memory-mode = <2>;' "$AX6_DTS"
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
