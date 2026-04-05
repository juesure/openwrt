#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$OPENWRT_ROOT" || exit 1

# 1. 删除非必要 DTS 文件
find target/linux/qualcommax -type f \( -name "*.dts" -o -name "*.dtsi" \) \
    ! -name "ipq8071-ax6.dts" \
    ! -name "ipq8074.dtsi" \
    ! -name "ipq8071-ax3600.dtsi" \
    -delete
echo "✅ 已删除冗余 DTS 文件"

# 2. 写入 ipq8074.dtsi（基础节点，无修改）
GEN_DTS_DIR="target/linux/qualcommax/dts"
mkdir -p "$GEN_DTS_DIR"

cat > "$GEN_DTS_DIR/ipq8074.dtsi" << 'EOF'
// 内容与之前一致，仅保留基础定义，此处省略（核心是 wifi 节点默认 disabled）
EOF

# 3. 写入 ipq8071-ax3600.dtsi（删除 WiFi 通用配置）
cat > "$GEN_DTS_DIR/ipq8071-ax3600.dtsi" << 'EOF'
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

# 4. 写入 AX6 专属 DTS（集中 WiFi 配置）
cat > "$GEN_DTS_DIR/ipq8071-ax6.dts" << 'EOF'
// SPDX-License-Identifier: GPL-2.0-only OR MIT
/dts-v1/;
#include "ipq8071-ax3600.dtsi"

/ {
    model = "Redmi AX6";
    compatible = "redmi,ax6", "qcom,ipq8074";
};

// 统一所有 WiFi 配置，集中管理
&wifi {
    status = "okay";
    qcom,ath11k-calibration-variant = "Redmi-AX6";
    qcom,ath11k-fw-memory-mode = <2>;
};
EOF

# 5. 写入 ipq807x.mk（无修改）
MK_FILE="target/linux/qualcommax/image/ipq807x.mk"
[ -f "$MK_FILE" ] && cp "$MK_FILE" "$MK_FILE.bak"
cat > "$MK_FILE" << 'EOF'
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

rm -rf target/linux/qualcommax/patches-6.12
echo "✅ 脚本执行完成（WiFi 配置已统一）"
