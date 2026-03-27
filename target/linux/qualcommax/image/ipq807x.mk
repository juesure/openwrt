#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 恢复原始 ipq807x.mk ==========
rm -f target/linux/qualcommax/image/ipq807x.mk

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

# ===================== Redmi AX6 配置（包含所有插件） =====================
define Device/redmi_ax6
	$(call Device/FitImage)
	$(call Device/UbiFit)
	DEVICE_VENDOR := Redmi
	DEVICE_MODEL := AX6
	BLOCKSIZE := 128k
	PAGESIZE := 2048
	DEVICE_DTS_CONFIG := config@ac04
	SOC := ipq8071
	IMAGE_SIZE := 245760k
	UBINIZE_OPTS := -E 5 -m 2048 -p 128KiB -s 2048 -O 2048
	KERNEL_IN_UBI := 1
	IMAGES += factory.ubi
	IMAGE/factory.ubi := append-ubi | check-size $$$$(IMAGE_SIZE)
	DEVICE_PACKAGES := \
		ipq-wifi-redmi_ax6 \
		kmod-ath11k-ahb \
		ath11k-firmware-ipq8071 \
		ath11k-firmware-ipq8074 \
		kmod-qca-wifi \
		kmod-qca-nss-dp \
		kmod-qca-ssdk \
		kmod-qca-ssdk-ipq807x \
		uhttpd \
		uhttpd-mod-ubus \
		uhttpd-mod-tls \
		luci \
		luci-base \
		luci-mod-admin-full \
		luci-mod-status \
		luci-mod-system \
		luci-mod-network \
		luci-mod-firewall \
		luci-proto-ppp \
		luci-proto-ipv6 \
		luci-proto-wireguard \
		luci-theme-bootstrap \
		luci-theme-argon \
		luci-theme-argon-config \
		luci-app-firewall \
		luci-app-opkg \
		luci-app-upnp \
		luci-app-store \
		luci-lib-store \
		luci-lib-store-cgi \
		luci-lib-store-dialog \
		luci-lib-store-utils \
		luci-i18n-store-zh-cn \
		store-apps \
		store-lua-maxminddb \
		store-lua-maxminddb-ipdb \
		store-lua-psutil \
		luci-i18n-base-zh-cn \
		luci-i18n-firewall-zh-cn \
		luci-i18n-opkg-zh-cn \
		luci-i18n-upnp-zh-cn \
		luci-i18n-argon-config-zh-cn \
		coreutils \
		coreutils-nohup \
		curl \
		wget \
		wget-ssl \
		unzip \
		7z \
		tar \
		gzip \
		bzip2 \
		fdisk \
		parted \
		lsblk \
		block-mount \
		blockd \
		openssh-sftp-server \
		dropbear \
		dropbearconvert \
		top \
		htop \
		logread \
		logrotate \
		ping \
		traceroute \
		mtr \
		nmap \
		tcpdump \
		iftop \
		ddns-scripts \
		ddns-scripts_aliyun \
		ddns-scripts_dnspod \
		smartdns \
		dnsmasq-full \
		ipset \
		iptables-mod-tproxy \
		iptables-mod-extra \
		ubi-utils \
		mtd-utils \
		mtd-utils-mkfs-ubifs \
		mtd-utils-ubi-utils \
		nand-utils
endef
TARGET_DEVICES += redmi_ax6
MKEOF

# ========== 验证 common.mk 是否存在 ==========
if [ ! -f target/linux/qualcommax/image/common.mk ]; then
    echo "❌ 错误：common.mk 文件不存在！"
    exit 1
fi

echo "✅ ipq807x.mk 已创建，包含所有插件"

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
