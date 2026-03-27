#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 创建缺失的 DTSI 文件 ==========
DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/"
mkdir -p "$DTS_DIR"

echo "创建 ipq8074-512m.dtsi..."
cat > "${DTS_DIR}ipq8074-512m.dtsi" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

#include "ipq8074-common.dtsi"

/ {
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
};
EOF

echo "创建 ipq8074-common.dtsi..."
cat > "${DTS_DIR}ipq8074-common.dtsi" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

#include <dt-bindings/interrupt-controller/arm-gic.h>
#include <dt-bindings/clock/qcom,gcc-ipq8074.h>
#include <dt-bindings/reset/qcom,gcc-ipq8074.h>

/ {
	interrupt-parent = <&intc>;

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

echo "创建 ipq8074-ac-cpu.dtsi..."
cat > "${DTS_DIR}ipq8074-ac-cpu.dtsi" << 'EOF'
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

echo "创建 ipq8074-ess.dtsi..."
cat > "${DTS_DIR}ipq8074-ess.dtsi" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

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

# ========== 修改 ipq8071-ax3600.dtsi 中的引用 ==========
AX3600_DTSI="${DTS_DIR}ipq8071-ax3600.dtsi"
if [ -f "$AX3600_DTSI" ]; then
    echo "修改 ipq8071-ax3600.dtsi 中的分区大小和 bootargs..."
    # 修改 rootfs 分区大小
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0x10000000>/' "$AX3600_DTSI"
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$AX3600_DTSI"
    echo "✅ DTSI 文件已修改"
fi

# ========== 创建 ipq807x.mk ==========
IPQ807X_MK="target/linux/qualcommax/image/ipq807x.mk"
mkdir -p target/linux/qualcommax/image/

echo "创建 ipq807x.mk..."
cat > "${IPQ807X_MK}" << 'MKEOF'
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

# ========== 创建 common.mk ==========
COMMON_MK="target/linux/qualcommax/image/common.mk"
cat > "${COMMON_MK}" << 'CMKEOF'
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
CMKEOF

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

# ========== 验证 ==========
echo "========== 验证创建的文件 =========="
ls -la ${DTS_DIR}ipq8074*.dtsi 2>/dev/null || echo "未找到 ipq8074 文件"
ls -la target/linux/qualcommax/image/ipq807x.mk || echo "未找到 ipq807x.mk"

echo "✅ DIY 脚本执行完成"
