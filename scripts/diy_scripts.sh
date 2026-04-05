#!/bin/bash
set -euo pipefail  # 开启严格模式，捕获所有错误
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

# 1. 检查并进入 OpenWRT 根目录
if [ ! -d "$OPENWRT_ROOT" ]; then
    echo "❌ 错误：OpenWRT 根目录不存在 - $OPENWRT_ROOT"
    exit 1
fi
cd "$OPENWRT_ROOT" || { echo "❌ 无法进入目录 $OPENWRT_ROOT"; exit 1; }
echo "✅ 已进入 OpenWRT 根目录：$OPENWRT_ROOT"

# 2. 彻底清理旧文件（避免缓存/权限冲突）
sudo rm -rf target/linux/qualcommax/*  # 使用 sudo 确保权限
echo "✅ 已彻底清理 qualcommax 目录"

# 3. 重建完整目录结构（关键！修复路径不存在问题）
mkdir -p target/linux/qualcommax/dts
mkdir -p target/linux/qualcommax/image
sudo chmod -R 777 target/linux/qualcommax  # 赋予全权限
echo "✅ 已重建目录结构并赋予权限"

# ========== 核心：ipq8074.dtsi（无语法错误） ==========
cat > target/linux/qualcommax/dts/ipq8074.dtsi << 'EOF'
// SPDX-License-Identifier: GPL-2.0-only OR MIT
#include <dt-bindings/interrupt-controller/arm-gic.h>
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/clock/qcom,gcc-ipq8074.h>

/ {
	interrupt-parent = <&intc>;
	#address-cells = <2>;
	#size-cells = <2>;

	cpus {
		#address-cells = <1>;
		#size-cells = <0>;

		cpu0: cpu@0 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x0>;
			enable-method = "psci";
			next-level-cache = <&L2_0>;
		};

		cpu1: cpu@1 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x1>;
			enable-method = "psci";
			next-level-cache = <&L2_0>;
		};

		cpu2: cpu@2 {
			device_type = "cpu";
			compatible = "arm,cortex-a53";
			reg = <0x2>;
			enable-method = "psci";
			next-level-cache = <&L2_0>;
		};

		cpu3: cpu@3 {
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

	timer {
		compatible = "arm,armv8-timer";
		interrupts = <GIC_PPI 2 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,
			     <GIC_PPI 3 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,
			     <GIC_PPI 4 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>,
			     <GIC_PPI 1 (GIC_CPU_MASK_SIMPLE(4) | IRQ_TYPE_LEVEL_LOW)>;
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

		gcc: clock-controller@1800000 {
			compatible = "qcom,gcc-ipq8074";
			reg = <0x01800000 0x80000>;
			#clock-cells = <1>;
			#reset-cells = <1>;
			#power-domain-cells = <1>;
		};

		tlmm: pinctrl@1000000 {
			compatible = "qcom,ipq8074-tlmm";
			reg = <0x01000000 0x300000>;
			gpio-controller;
			#gpio-cells = <2>;
			interrupt-controller;
			#interrupt-cells = <2>;
			gpio-ranges = <&tlmm 0 0 128>;
		};

		blsp1_uart5: serial@78b3000 {
			compatible = "qcom,msm-uartdm-v1.4", "qcom,msm-uartdm";
			reg = <0x078b3000 0x200>;
			interrupts = <GIC_SPI 308 IRQ_TYPE_LEVEL_HIGH>;
			clocks = <&gcc GCC_BLSP1_UART3_APPS_CLK>,
				 <&gcc GCC_BLSP1_AHB_CLK>;
			clock-names = "core", "iface";
			status = "disabled";
		};

		prng: rng@22000 {
			compatible = "qcom,prng";
			reg = <0x00022000 0x200>;
			clocks = <&gcc GCC_PRNG_AHB_CLK>;
			clock-names = "core";
			status = "disabled";
		};

		cryptobam: dma-controller@704000 {
			compatible = "qcom,bam-v1.7.0";
			reg = <0x00704000 0x20000>;
			interrupts = <GIC_SPI 207 IRQ_TYPE_LEVEL_HIGH>;
			#dma-cells = <1>;
			qcom,ee = <1>;
			qcom,controlled-remotely;
			status = "disabled";
		};

		crypto: crypto@73a000 {
			compatible = "qcom,crypto-v5.1";
			reg = <0x0073a000 0x6000>;
			clocks = <&gcc GCC_CRYPTO_AHB_CLK>,
				 <&gcc GCC_CRYPTO_AXI_CLK>,
				 <&gcc GCC_CRYPTO_CLK>;
			clock-names = "iface", "bus", "core";
			dmas = <&cryptobam 2>, <&cryptobam 3>;
			dma-names = "rx", "tx";
			status = "disabled";
		};

		qpic_bam: dma-controller@7984000 {
			compatible = "qcom,bam-v1.7.0";
			reg = <0x07984000 0x1a000>;
			interrupts = <GIC_SPI 286 IRQ_TYPE_LEVEL_HIGH>;
			#dma-cells = <1>;
			qcom,ee = <1>;
			qcom,controlled-remotely;
			status = "disabled";
		};

		qpic_nand: nand-controller@79b0000 {
			compatible = "qcom,ipq8074-nand";
			reg = <0x079b0000 0x10000>;
			#address-cells = <1>;
			#size-cells = <0>;
			clocks = <&gcc GCC_QPIC_CLK>,
				 <&gcc GCC_QPIC_AHB_CLK>;
			clock-names = "core", "aon";
			dmas = <&qpic_bam 0>,
			       <&qpic_bam 1>,
			       <&qpic_bam 2>;
			dma-names = "tx", "rx", "cmd";
			status = "disabled";
		};

		mdio: mdio@90000 {
			compatible = "qcom,ipq8074-mdio";
			reg = <0x00090000 0x64>;
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

		switch: ess-switch@3a000000 {
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
			#address-cells = <1>;
			#size-cells = <0>;
			status = "disabled";

			switch-cpu@0 {
				compatible = "qcom,ess-switch-cpu";
				reg = <0>;
			};

			switch-cpu@1 {
				compatible = "qcom,ess-switch-cpu";
				reg = <1>;
			};

			dp2: ethernet@2 {
				compatible = "qcom,ess-switch-port";
				reg = <2>;
				phy-mode = "sgmii";
				status = "disabled";
			};

			dp3: ethernet@3 {
				compatible = "qcom,ess-switch-port";
				reg = <3>;
				phy-mode = "sgmii";
				status = "disabled";
			};

			dp4: ethernet@4 {
				compatible = "qcom,ess-switch-port";
				reg = <4>;
				phy-mode = "sgmii";
				status = "disabled";
			};

			dp5: ethernet@5 {
				compatible = "qcom,ess-switch-port";
				reg = <5>;
				phy-mode = "sgmii";
				status = "disabled";
			};
		};

		wifi: wifi@4a000000 {
			compatible = "qcom,ipq8074-wifi";
			reg = <0x4a000000 0x800000>;
			clocks = <&gcc GCC_WIFI_CLK>;
			clock-names = "core";
			status = "disabled";
		};
	};
};
EOF

# ========== ipq8071-ax3600.dtsi ==========
cat > target/linux/qualcommax/dts/ipq8071-ax3600.dtsi << 'EOF'
// SPDX-License-Identifier: GPL-2.0-only OR MIT
#include "ipq8074.dtsi"
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

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
	};

	memory {
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

		q6_etr_dump: q6_etr_dump@4e700000 {
			reg = <0x0 0x4e700000 0x0 0x100000>;
			no-map;
		};

		m3_dump: m3_dump@4e800000 {
			reg = <0x0 0x4e800000 0x0 0x100000>;
			no-map;
		};
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&tlmm 34 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
		};
	};

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

&blsp1_uart5 {
	status = "okay";
};

&cryptobam {
	status = "okay";
};

&crypto {
	status = "okay";
};

&mdio {
	status = "okay";
	pinctrl-0 = <&mdio_pins>;
	pinctrl-names = "default";
	reset-gpios = <&tlmm 37 GPIO_ACTIVE_LOW>;

	ethernet-phy-package@0 {
		compatible = "qcom,qca8075-package";
		reg = <0>;
		#address-cells = <1>;
		#size-cells = <0>;

		ethernet_phy_1: ethernet-phy@1 {
			reg = <1>;
			compatible = "ethernet-phy-ieee802.3-c22";
		};

		ethernet_phy_2: ethernet-phy@2 {
			reg = <2>;
			compatible = "ethernet-phy-ieee802.3-c22";
		};

		ethernet_phy_3: ethernet-phy@3 {
			reg = <3>;
			compatible = "ethernet-phy-ieee802.3-c22";
		};

		ethernet_phy_4: ethernet-phy@4 {
			reg = <4>;
			compatible = "ethernet-phy-ieee802.3-c22";
		};
	};
};

&qpic_bam {
	status = "okay";
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
				label = "pstore";
				reg = <0x900000 0x100000>;
			};

			partition@a00000 {
				label = "rootfs";
				reg = <0xa00000 0xf600000>;
				compatible = "openwrt,ubi";
			};
		};
	};
};

&prng {
	status = "okay";
};

&switch {
	status = "okay";
	switch_lan_bmp = <0x38>;
	switch_wan_bmp = <0x04>;
	switch_mac_mode = <0>;

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

&tlmm {
	mdio_pins: mdio-pins {
		pins = "gpio68", "gpio69";
		function = "mdio";
		drive-strength = <8>;
		bias-pull-up;
	};
};

&dp2 {
	status = "okay";
	phy-handle = <&ethernet_phy_1>;
	label = "wan";
	nvmem-cells = <&macaddr_dp2>;
	nvmem-cell-names = "mac-address";
};

&dp3 {
	status = "okay";
	phy-handle = <&ethernet_phy_2>;
	label = "lan1";
	nvmem-cells = <&macaddr_dp3>;
	nvmem-cell-names = "mac-address";
};

&dp4 {
	status = "okay";
	phy-handle = <&ethernet_phy_3>;
	label = "lan2";
	nvmem-cells = <&macaddr_dp4>;
	nvmem-cell-names = "mac-address";
};

&dp5 {
	status = "okay";
	phy-handle = <&ethernet_phy_4>;
	label = "lan3";
	nvmem-cells = <&macaddr_dp5>;
	nvmem-cell-names = "mac-address";
};

&edma {
	status = "okay";
};
EOF

# ========== Redmi AX6 专属 DTS ==========
cat > target/linux/qualcommax/dts/ipq8071-ax6.dts << 'EOF'
// SPDX-License-Identifier: GPL-2.0-only OR MIT
/dts-v1/;
#include "ipq8071-ax3600.dtsi"

/ {
	model = "Redmi AX6";
	compatible = "redmi,ax6", "qcom,ipq8074";
};

&wifi {
	status = "okay";
	qcom,ath11k-calibration-variant = "Redmi-AX6";
	qcom,ath11k-fw-memory-mode = <2>;
};
EOF

# ========== ipq807x.mk（修复路径/权限） ==========
cat > target/linux/qualcommax/image/ipq807x.mk << 'EOF'
# SPDX-License-Identifier: GPL-2.0-only
# Copyright (C) 2021 OpenWrt.org

define Device/redmi_ax6
  DEVICE_VENDOR := Redmi
  DEVICE_MODEL := AX6
  DEVICE_DTS := ipq8071-ax6
  DEVICE_DTS_DIR := ../dts
  IMAGE_SIZE := 258048k
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  SUBPAGESIZE := 2048
  VID_HDR_OFFSET := 2048
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := append-kernel | append-rootfs | pad-rootfs | append-metadata | check-size $$$$(IMAGE_SIZE)
endef
TARGET_DEVICES += redmi_ax6
EOF

# 4. 验证文件是否写入成功
if [ -f "target/linux/qualcommax/image/ipq807x.mk" ] && [ -f "target/linux/qualcommax/dts/ipq8071-ax6.dts" ]; then
    echo "✅ 所有文件写入成功！"
    echo "✅ 脚本执行完成，可开始编译"
else
    echo "❌ 文件写入失败，请检查权限"
    exit 1
fi
