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
    # 修改 bootargs
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
    # 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    echo "✅ DTS 修改完成"
else
    echo "❌ 错误: 找不到 $DTS_FILE"
    exit 1
fi

# 重写 ipq807x.mk，只保留 xiaomi_ax3600 和 redmi_ax6
MK_FILE="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "$MK_FILE" ]; then
    echo "重写 $MK_FILE，只保留 Redmi AX6 相关定义..."
    cat > "$MK_FILE" << 'MKEOF'
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
	IMAGE_SIZE := 262144k
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
		luci-lib-store \
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
    echo "✅ ipq807x.mk 已重写"
fi

# 删除补丁目录
rm -rf target/linux/qualcommax/patches-6.12

echo "✅ DIY 脚本执行完成"
