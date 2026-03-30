#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

DTS_DIR="target/linux/qualcommax/dts"
mkdir -p "$DTS_DIR"

# 1. 确保依赖的 dtsi 文件存在（如果不存在则创建）
# ipq8074-512m.dtsi
if [ ! -f "$DTS_DIR/ipq8074-512m.dtsi" ]; then
    cat > "$DTS_DIR/ipq8074-512m.dtsi" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

#include "ipq8074.dtsi"

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
fi

# ipq8074-ac-cpu.dtsi
if [ ! -f "$DTS_DIR/ipq8074-ac-cpu.dtsi" ]; then
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
fi

# ipq8074-ess.dtsi
if [ ! -f "$DTS_DIR/ipq8074-ess.dtsi" ]; then
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
EOF
fi

# 2. 修改 ipq8071-ax3600.dtsi 中的 include 路径和参数
DTS_FILE="$DTS_DIR/ipq8071-ax3600.dtsi"
if [ -f "$DTS_FILE" ]; then
    # 修复 include 路径（去除可能的长路径）
    sed -i 's|#include ".*/ipq8074-512m.dtsi"|#include "ipq8074-512m.dtsi"|' "$DTS_FILE"
    sed -i 's|#include ".*/ipq8074-ac-cpu.dtsi"|#include "ipq8074-ac-cpu.dtsi"|' "$DTS_FILE"
    sed -i 's|#include ".*/ipq8074-ess.dtsi"|#include "ipq8074-ess.dtsi"|' "$DTS_FILE"
    
    # 修改 bootargs
    sed -i 's|root=/dev/ubiblock0_0|root=/dev/ubiblock0_1|' "$DTS_FILE"
    # 修改 rootfs 分区大小（使用 0xf600000 = 246MB，避免溢出）
    sed -i 's/reg = <0xa00000 0xf000000>/reg = <0xa00000 0xf600000>/' "$DTS_FILE"
    # 修改 WiFi 内存模式
    sed -i 's/qcom,ath11k-fw-memory-mode = <1>;/qcom,ath11k-fw-memory-mode = <2>;/' "$DTS_FILE"
    echo "✅ DTS 文件已修改"
else
    echo "⚠️ 未找到 $DTS_FILE，跳过修改"
fi

# 3. 删除有问题的内核补丁
PATCH_DIR="target/linux/qualcommax/patches-6.12"
if [ -d "$PATCH_DIR" ]; then
    # 删除已知导致失败的补丁（可根据日志持续补充）
    for patch in 0036 0111 0122 0123 0130; do
        rm -f "$PATCH_DIR"/${patch}*.patch 2>/dev/null
    done
    echo "✅ 已删除有问题的内核补丁"
fi

echo "✅ DIY 脚本执行完成"
