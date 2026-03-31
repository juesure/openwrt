#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

SRC_DTS_DIR="target/linux/qualcommax/files/arch/arm64/boot/dts/qcom"
DST_DTS_DIR="target/linux/qualcommax/dts"

# 创建目标目录
mkdir -p "$DST_DTS_DIR"
echo "📁 创建目录: $DST_DTS_DIR"

# 复制所有源 DTS 文件（包括子目录）到 dts 目录
echo "📋 复制所有 DTS 源文件到 $DST_DTS_DIR ..."
cp -r "$SRC_DTS_DIR"/* "$DST_DTS_DIR"/ 2>/dev/null || true
if [ -d "$DST_DTS_DIR" ] && [ "$(ls -A "$DST_DTS_DIR")" ]; then
    echo "✅ DTS 文件复制成功"
else
    echo "❌ DTS 文件复制失败，目标目录为空"
    exit 1
fi

# ========== 生成修改后的 ipq8071-ax3600.dtsi ==========
AX3600_DTS="$DST_DTS_DIR/ipq8071-ax3600.dtsi"
cat > "$AX3600_DTS" << 'EOF'
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

&qpic_nand {
	status = "okay";

	/*
	 * Bootloader will find the NAND DT node by the compatible and
	 * then "fixup" it by adding the partitions from the SMEM table
	 * using the legacy bindings thus making it impossible for us
	 * to change the partition table or utilize NVMEM for calibration.
	 * So add a dummy partitions node that bootloader will populate
	 * and set it as disabled so the kernel ignores it instead of
	 * printing warnings due to the broken way bootloader adds the
	 * partitions.
	 */
	partitions {
		status = "disabled";
	};

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

					caldata_qca9889: caldata@4d000 {
						reg = <0x33000 0x844>;
					};
				};
			};

			partition@880000 {
				label = "bdata";
				reg = <0x880000 0x80000>;
			};

			partition@900000 {
				/* This is crash + crash_syslog parts combined */
				label = "pstore";
				reg = <0x900000 0x100000>;
			};

			/* 单个 rootfs 分区（UBI），大小 246MB */
			partition@a00000 {
				label = "rootfs";
				reg = <0xa00000 0xf600000>;
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

	switch_lan_bmp = <(ESS_PORT3 | ESS_PORT4 | ESS_PORT5)>; /* lan port bitmap */
	switch_wan_bmp = <ESS_PORT2>; /* wan port bitmap */
	switch_mac_mode = <MAC_MODE_PSGMII>; /* mac mode for uniphy instance0*/

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

	qcom,ath11k-fw-memory-mode = <2>;
};
EOF

# 验证 ipq8071-ax3600.dtsi 关键修改
if grep -q 'root=/dev/ubiblock0_1' "$AX3600_DTS" && \
   grep -q 'reg = <0xa00000 0xf600000>' "$AX3600_DTS" && \
   grep -q 'qcom,ath11k-fw-memory-mode = <2>' "$AX3600_DTS"; then
    echo "✅ ipq8071-ax3600.dtsi 修改成功"
else
    echo "❌ ipq8071-ax3600.dtsi 修改失败，关键内容缺失"
    exit 1
fi

# ========== 生成修改后的 ipq8071-ax6.dts ==========
AX6_DTS="$DST_DTS_DIR/ipq8071-ax6.dts"
cat > "$AX6_DTS" << 'EOF'
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
EOF

if [ -f "$AX6_DTS" ]; then
    echo "✅ ipq8071-ax6.dts 已生成"
else
    echo "❌ ipq8071-ax6.dts 生成失败"
    exit 1
fi

# ========== 删除补丁目录 ==========
PATCH_DIR="target/linux/qualcommax/patches-6.12"
rm -rf "$PATCH_DIR"
if [ ! -d "$PATCH_DIR" ]; then
    echo "✅ 补丁目录已删除"
else
    echo "❌ 补丁目录删除失败"
    exit 1
fi

echo "✅ DIY 脚本执行完成，所有修改已确认"
