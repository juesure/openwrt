#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 下载缺失的 DTSI 文件 ==========
DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
mkdir -p "$DTS_DIR"

# 下载 ipq8074-512m.dtsi
if [ ! -f "${DTS_DIR}ipq8074-512m.dtsi" ]; then
    echo "下载 ipq8074-512m.dtsi..."
    wget -q -O "${DTS_DIR}ipq8074-512m.dtsi" \
        "https://raw.githubusercontent.com/openwrt/openwrt/main/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8074-512m.dtsi"
fi

# 下载 ipq8074-ac-cpu.dtsi
if [ ! -f "${DTS_DIR}ipq8074-ac-cpu.dtsi" ]; then
    echo "下载 ipq8074-ac-cpu.dtsi..."
    wget -q -O "${DTS_DIR}ipq8074-ac-cpu.dtsi" \
        "https://raw.githubusercontent.com/openwrt/openwrt/main/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8074-ac-cpu.dtsi"
fi

# 下载 ipq8074-ess.dtsi
if [ ! -f "${DTS_DIR}ipq8074-ess.dtsi" ]; then
    echo "下载 ipq8074-ess.dtsi..."
    wget -q -O "${DTS_DIR}ipq8074-ess.dtsi" \
        "https://raw.githubusercontent.com/openwrt/openwrt/main/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8074-ess.dtsi"
fi

# 下载 ipq8074-cpr-regulator.dtsi
if [ ! -f "${DTS_DIR}ipq8074-cpr-regulator.dtsi" ]; then
    echo "下载 ipq8074-cpr-regulator.dtsi..."
    wget -q -O "${DTS_DIR}ipq8074-cpr-regulator.dtsi" \
        "https://raw.githubusercontent.com/openwrt/openwrt/main/target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq8074-cpr-regulator.dtsi"
fi

echo "✅ DTSI 文件下载完成"

# ========== 创建 ipq8071-ax6.dts ==========
cat > "${DTS_DIR}ipq8071-ax6.dts" << 'DTSEOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Zhijun You <hujy652@gmail.com> */

/dts-v1/;

#include "ipq8071-ax3600.dtsi"

/ {
	model = "Redmi AX6";
	compatible = "redmi,ax6", "qcom,ipq8074";

	leds {
		compatible = "gpio-leds";

		led_system_blue: system-blue {
			label = "blue:system";
			gpios = <&tlmm 21 GPIO_ACTIVE_HIGH>;
		};

		led_system_yellow: system-yellow {
			label = "yellow:system";
			gpios = <&tlmm 22 GPIO_ACTIVE_HIGH>;
		};

		network-blue {
			label = "blue:network";
			gpios = <&tlmm 42 GPIO_ACTIVE_HIGH>;
		};

		network-yellow {
			label = "yellow:network";
			gpios = <&tlmm 43 GPIO_ACTIVE_HIGH>;
		};
	};
};

&wifi {
	qcom,ath11k-calibration-variant = "Redmi-AX6";
};
DTSEOF

# ========== 创建 ipq8071-ax3600.dtsi ==========
cat > "${DTS_DIR}ipq8071-ax3600.dtsi" << 'DTSEOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

#include "ipq8074-512m.dtsi"
#include "ipq8074-ac-cpu.dtsi"
#include "ipq8074-ess.dtsi"
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>

/ {
	aliases {
		serial0 = &blsp1_uart5;
		led-boot = &led_system_yellow;
		led-failsafe = &led_system_yellow;
		led-running = &led_system_blue;
		led-upgrade = &led_system_yellow;
		label-mac-device = &dp2;
	};

	chosen {
		stdout-path = "serial0:115200n8";
		bootargs-append = " ubi.mtd=rootfs root=/dev/ubiblock0_1 rootfstype=squashfs rootwait";
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&tlmm 34 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
		};
	};
};

&blsp1_uart5 {
	status = "okay";
};

&prng {
	status = "okay";
};

&cryptobam {
	status = "okay";
};

&crypto {
	status = "okay";
};

&qpic_bam {
	status = "okay";
};

&tlmm {
	mdio_pins: mdio-pins {
		mdc {
			pins = "gpio68";
			function = "mdc";
			drive-strength = <8>;
			bias-pull-up;
		};

		mdio {
			pins = "gpio69";
			function = "mdio";
			drive-strength = <8>;
			bias-pull-up;
		};
	};
};

&qpic_nand {
	status = "okay";

	nand@0 {
		reg = <0>;
		nand-ecc-strength = <4>;
		nand-ecc-step-size = <512>;
		nand-bus-width = <8>;

		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "0:sbl1";
				reg = <0x0 0x100000>;
				read-only;
			};

			partition@100000 {
				label = "0:mibib";
				reg = <0x100000 0x100000>;
				read-only;
			};

			partition@200000 {
				label = "0:qsee";
				reg = <0x200000 0x300000>;
				read-only;
			};

			partition@500000 {
				label = "0:devcfg";
				reg = <0x500000 0x80000>;
				read-only;
			};

			partition@580000 {
				label = "0:rpm";
				reg = <0x580000 0x80000>;
				read-only;
			};

			partition@600000 {
				label = "0:cdt";
				reg = <0x600000 0x80000>;
				read-only;
			};

			partition@680000 {
				label = "0:appsblenv";
				reg = <0x680000 0x80000>;
			};

			partition@700000 {
				label = "0:appsbl";
				reg = <0x700000 0x100000>;
				read-only;
			};

			partition@800000 {
				label = "0:art";
				reg = <0x800000 0x80000>;
				read-only;

				nvmem-layout {
					compatible = "fixed-layout";
					#address-cells = <1>;
					#size-cells = <1>;

					macaddr_dp2: macaddr@6 {
						reg = <0x6 0x6>;
					};

					macaddr_dp3: macaddr@c {
						reg = <0xc 0x6>;
					};

					macaddr_dp4: macaddr@12 {
						reg = <0x12 0x6>;
					};

					macaddr_dp5: macaddr@18 {
						reg = <0x18 0x6>;
					};
				};
			};

			partition@880000 {
				label = "bdata";
				reg = <0x880000 0x80000>;
			};

			partition@900000 {
				label = "crash";
				reg = <0x900000 0x80000>;
			};

			partition@980000 {
				label = "crash_syslog";
				reg = <0x980000 0x80000>;
			};

			partition@a00000 {
				label = "rootfs";
				reg = <0xa00000 0xf000000>;
				compatible = "openwrt,ubi";
			};

			partition@fa00000 {
				label = "rsvd0";
				reg = <0xfa00000 0x80000>;
				read-only;
			};
		};
	};
};

&mdio {
	status = "okay";
	pinctrl-0 = <&mdio_pins>;
	pinctrl-names = "default";
	reset-gpios = <&tlmm 37 GPIO_ACTIVE_LOW>;

	ethernet-phy-package@0 {
		#address-cells = <1>;
		#size-cells = <0>;
		compatible = "qcom,qca8075-package";
		reg = <0>;

		qca8075_1: ethernet-phy@1 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <1>;
		};

		qca8075_2: ethernet-phy@2 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <2>;
		};

		qca8075_3: ethernet-phy@3 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <3>;
		};

		qca8075_4: ethernet-phy@4 {
			compatible = "ethernet-phy-ieee802.3-c22";
			reg = <4>;
		};
	};
};

&switch {
	status = "okay";
	switch_lan_bmp = <(ESS_PORT3 | ESS_PORT4 | ESS_PORT5)>;
	switch_wan_bmp = <ESS_PORT2>;
	switch_mac_mode = <MAC_MODE_PSGMII>;

	qcom,port_phyinfo {
		port@2 {
			port_id = <2>;
			phy_address = <1>;
		};
		port@3 {
			port_id = <3>;
			phy_address = <2>;
		};
		port@4 {
			port_id = <4>;
			phy_address = <3>;
		};
		port@5 {
			port_id = <5>;
			phy_address = <4>;
		};
	};
};

&edma {
	status = "okay";
};

&dp2 {
	status = "okay";
	phy-handle = <&qca8075_1>;
	label = "wan";
	nvmem-cells = <&macaddr_dp2>;
	nvmem-cell-names = "mac-address";
};

&dp3 {
	status = "okay";
	phy-handle = <&qca8075_2>;
	label = "lan1";
	nvmem-cells = <&macaddr_dp3>;
	nvmem-cell-names = "mac-address";
};

&dp4 {
	status = "okay";
	phy-handle = <&qca8075_3>;
	label = "lan2";
	nvmem-cells = <&macaddr_dp4>;
	nvmem-cell-names = "mac-address";
};

&dp5 {
	status = "okay";
	phy-handle = <&qca8075_4>;
	label = "lan3";
	nvmem-cells = <&macaddr_dp5>;
	nvmem-cell-names = "mac-address";
};

&wifi {
	status = "okay";
};
DTSEOF

# ========== 下载 common.mk ==========
COMMON_MK_PATH="target/linux/qualcommax/image/common.mk"
mkdir -p target/linux/qualcommax/image/
if [ ! -f "${COMMON_MK_PATH}" ]; then
    wget -q -O "${COMMON_MK_PATH}" \
        "https://raw.githubusercontent.com/openwrt/openwrt/main/target/linux/qualcommax/image/common.mk"
fi

# ========== 创建 ipq807x.mk ==========
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
