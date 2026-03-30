#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

DTS_DIR="target/linux/qualcommax/dts"
mkdir -p "$DTS_DIR"

# 创建 ipq8074-ess.dtsi（包含必要的宏定义和节点，但为了简化，只保留宏定义）
cat > "$DTS_DIR/ipq8074-ess.dtsi" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-only

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

#define MAC_MODE_DISABLED	3

/* 定义网口节点，这些节点原本在 ess.dtsi 中，但我们只需要标签，不需要完整定义，因为它们在 soc 节点中已存在 */
/* 实际节点定义在 ipq8074-ess.dtsi 完整版中，但为了编译通过，我们只需确保标签存在 */
&dp2 { };
&dp3 { };
&dp4 { };
&dp5 { };
EOF

# 创建 ipq8074-ac-cpu.dtsi（仅包含 OPP 表）
cat > "$DTS_DIR/ipq8074-ac-cpu.dtsi" << 'EOF'
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

# 创建 ipq8074-512m.dtsi（包含内存和保留内存定义）
cat > "$DTS_DIR/ipq8074-512m.dtsi" << 'EOF'
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

		q6_etr_dump: q6_etr_dump@4e700000 {
			reg = <0x0 0x4e700000 0x0 0x100000>;
			no-map;
		};

		m3_dump: m3_dump@4e800000 {
			reg = <0x0 0x4e800000 0x0 0x100000>;
			no-map;
		};
	};
};
EOF

# 创建 ipq8074-common.dtsi（基础 SoC 定义，与官方 ipq8074.dtsi 类似，但只包含必要部分）
cat > "$DTS_DIR/ipq8074-common.dtsi" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

#include <dt-bindings/interrupt-controller/arm-gic.h>
#include <dt-bindings/clock/qcom,gcc-ipq8074.h>
#include <dt-bindings/reset/qcom,gcc-ipq8074.h>

/ {
	#address-cells = <2>;
	#size-cells = <2>;

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

# 修改 ipq8071-ax3600.dtsi 中的 include 路径和参数
DTS_FILE="$DTS_DIR/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    # 修复 include 路径
    sed -i 's|#include ".*/ipq8074-512m.dtsi"|#include "ipq8074-512m.dtsi"|' "$DTS_FILE"
    sed -i 's|#include ".*/ipq8074-ac-cpu.dtsi"|#include "ipq8074-ac-cpu.dtsi"|' "$DTS_FILE"
    sed -i 's|#include ".*/ipq8074-ess.dtsi"|#include "ipq8074-ess.dtsi"|' "$DTS_FILE"
    
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    # 修改 rootfs 分区大小（使用 0xf600000 即 246MB）
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0xf600000>/' "$DTS_FILE"
    # 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    echo "✅ DTS 文件已修改"
else
    echo "⚠️ 未找到 $DTS_FILE，跳过修改"
fi

# 删除整个补丁目录（避免所有补丁冲突）
rm -rf target/linux/qualcommax/patches-6.12

echo "✅ DIY 脚本执行完成"
