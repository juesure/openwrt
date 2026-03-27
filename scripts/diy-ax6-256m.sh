#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 设置正确的 DTS 目录 ==========
DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
mkdir -p "$DTS_DIR"

# ========== 创建 IPQ8071 专用的 DTSI 文件 ==========
echo "创建 IPQ8071 专用 DTSI 文件..."

# 1. 创建 ipq8071-512m.dtsi
cat > "${DTS_DIR}ipq8071-512m.dtsi" << 'EOF'
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

	cpus {
		#address-cells = <1>;
		#size-cells = <0>;

		cpu@0 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x0>;
			enable-method = "psci";
			next-level-cache = <&L2_0>;
		};

		cpu@1 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x1>;
			enable-method = "psci";
			next-level-cache = <&L2_0>;
		};

		cpu@2 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x2>;
			enable-method = "psci";
			next-level-cache = <&L2_0>;
		};

		cpu@3 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x3>;
			enable-method = "psci";
			next-level-cache = <&L2_0>;
		};

		L2_0: l2-cache {
			compatible = "cache";
			cache-level = <2>;
		};
	};

	psci {
		compatible = "arm,psci-1.0";
		method = "smc";
	};

	soc: soc@0 {
		#address-cells = <1>;
		#size-cells = <1>;
		ranges = <0 0 0 0xffffffff>;
		compatible = "simple-bus";

		intc: interrupt-controller@b000000 {
			compatible = "qcom,msm-qgic2";
			interrupt-controller;
			#interrupt-cells = <3>;
			reg = <0x0b000000 0x1000>,
			      <0x0b002000 0x1000>;
		};

		timer@b120000 {
			compatible = "arm,armv7-timer-mem";
			#address-cells = <1>;
			#size-cells = <1>;
			ranges;
			reg = <0x0b120000 0x1000>;
			clock-frequency = <19200000>;

			frame@b120000 {
				frame-number = <0>;
				interrupts = <GIC_SPI 8 IRQ_TYPE_LEVEL_HIGH>,
					     <GIC_SPI 7 IRQ_TYPE_LEVEL_HIGH>;
				reg = <0x0b121000 0x1000>,
				      <0x0b122000 0x1000>;
			};
		};

		apcs_glb: mailbox@b111000 {
			compatible = "qcom,ipq6018-apcs-apps-global";
			reg = <0x0b111000 0x1000>;
			#clock-cells = <1>;
			clocks = <&xo>;
			clock-names = "xo";
		};
	};

	clocks {
		xo: xo {
			compatible = "fixed-clock";
			clock-frequency = <19200000>;
			#clock-cells = <0>;
		};

		sleep_clk: sleep_clk {
			compatible = "fixed-clock";
			clock-frequency = <32000>;
			#clock-cells = <0>;
		};
	};

	timer {
		compatible = "arm,armv8-timer";
		interrupts = <GIC_PPI 2 IRQ_TYPE_LEVEL_LOW>,
			     <GIC_PPI 3 IRQ_TYPE_LEVEL_LOW>,
			     <GIC_PPI 4 IRQ_TYPE_LEVEL_LOW>,
			     <GIC_PPI 1 IRQ_TYPE_LEVEL_LOW>;
	};
};
EOF

# 2. 创建 ipq8071-ac-cpu.dtsi
cat > "${DTS_DIR}ipq8071-ac-cpu.dtsi" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

/ {
	cpu_opp_table: opp-table-cpu {
		compatible = "operating-points-v2";
		opp-shared;

		opp-1017600000 {
			opp-hz = <0 1017600000>;
			opp-microvolt = <704000>;
			clock-latency-ns = <200000>;
		};
		opp-1104000000 {
			opp-hz = <0 1104000000>;
			opp-microvolt = <752000>;
			clock-latency-ns = <200000>;
		};
		opp-1200000000 {
			opp-hz = <0 1200000000>;
			opp-microvolt = <800000>;
			clock-latency-ns = <200000>;
		};
		opp-1320000000 {
			opp-hz = <0 1320000000>;
			opp-microvolt = <856000>;
			clock-latency-ns = <200000>;
		};
		opp-1401600000 {
			opp-hz = <0 1401600000>;
			opp-microvolt = <912000>;
			clock-latency-ns = <200000>;
		};
	};
};
EOF

# 3. 创建 ipq8074-ess.dtsi（简化版）
cat > "${DTS_DIR}ipq8074-ess.dtsi" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

/ {
	ess-switch@3a000000 {
		compatible = "qcom,ipq8074-ess-switch";
		reg = <0x3a000000 0x1000000>;
		reg-names = "core";
		interrupts-extended = <&intc GIC_SPI 188 IRQ_TYPE_LEVEL_HIGH>;
		interrupt-names = "macirq";
		clocks = <&gcc GCC_CMN_12GPLL_AHB_CLK>,
			 <&gcc GCC_CMN_12GPLL_SYS_CLK>;
		clock-names = "ahb", "sys";
		resets = <&gcc GCC_ESS_RESET>;
		reset-names = "ess";
		qcom,mdio = <&mdio>;
		qcom,phy-reset = <&tlmm 37 GPIO_ACTIVE_LOW>;
		#address-cells = <1>;
		#size-cells = <0>;

		switch-cpu@0 {
			compatible = "qcom,ess-switch-cpu";
			reg = <0>;
		};

		switch-cpu@1 {
			compatible = "qcom,ess-switch-cpu";
			reg = <1>;
		};
	};

	mdio: mdio@90000 {
		compatible = "qcom,ipq8074-mdio";
		reg = <0x90000 0x64>;
		#address-cells = <1>;
		#size-cells = <0>;
		status = "disabled";
	};

	edma: edma@3a001000 {
		compatible = "qcom,ipq8074-edma";
		reg = <0x3a001000 0x8000>;
		reg-names = "edma";
		interrupts = <GIC_SPI 189 IRQ_TYPE_LEVEL_HIGH>,
			     <GIC_SPI 190 IRQ_TYPE_LEVEL_HIGH>,
			     <GIC_SPI 191 IRQ_TYPE_LEVEL_HIGH>,
			     <GIC_SPI 192 IRQ_TYPE_LEVEL_HIGH>;
		interrupt-names = "rx0", "rx1", "tx0", "tx1";
		clocks = <&gcc GCC_EDMA_CLK>,
			 <&gcc GCC_EDMA_AXI_CLK>;
		clock-names = "core", "axi";
		resets = <&gcc GCC_EDMA_RESET>;
		reset-names = "edma";
		status = "disabled";
	};
};

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

# 4. 创建 ipq8071-ax3600.dtsi（关键：引用 ipq8071-512m.dtsi，不是 ipq8074）
cat > "${DTS_DIR}ipq8071-ax3600.dtsi" << 'DTSEOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

#include "ipq8071-512m.dtsi"
#include "ipq8071-ac-cpu.dtsi"
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

# 5. 创建 ipq8071-ax6.dts
cat > "${DTS_DIR}ipq8071-ax6.dts" << 'DTSEOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Zhijun You <hujy652@gmail.com> */

/dts-v1/;

#include "ipq8071-ax3600.dtsi"

/ {
	model = "Redmi AX6";
	compatible = "redmi,ax6", "qcom,ipq8071";

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

# ========== 下载 common.mk 并创建 ipq807x.mk ==========
echo "创建 ipq807x.mk..."
COMMON_MK_PATH="target/linux/qualcommax/image/common.mk"
mkdir -p target/linux/qualcommax/image/

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

# 创建 common.mk（如果不存在）
if [ ! -f "${COMMON_MK_PATH}" ]; then
    cat > "${COMMON_MK_PATH}" << 'EOF'
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

define Build/qsdk-ipq-factory-nand
	$(STAGING_DIR_HOST)/bin/mkfwimage2 -v -f 0x44000000 -p 0x44000000:0x200000:$(1) -p 0x44200000:0x200000:$(2) -o $@
endef

define Build/ubinize-kernel
	mkdir -p $(KDIR)/tmp
	$(STAGING_DIR_HOST)/bin/ubinize -o $@ -p 128KiB -m 2048 -s 2048 -O 2048 \
		$(foreach vol,$(1),-v $(vol)) \
		$(KDIR)/tmp/ubinize.cfg
endef
EOF
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
