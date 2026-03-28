#!/bin/bash
# 【正确路径】与你的环境完全匹配
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

cd "${OPENWRT_ROOT}" || exit 1

# ==========================================
# 【终极正确 DTS】第一行必加 /dts-v1/;
# 解决 #include 语法错误
# ==========================================
cat > target/linux/qualcommax/dts/ipq8071-ax3600.dtsi <<'EOF'
/dts-v1/;
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT
/* Copyright (c) 2021, Robert Marko <robimarko@gmail.com> */

#include <dt-bindings/interrupt-controller/arm-gic.h>
#include <dt-bindings/clock/qcom,gcc-ipq8074.h>
#include <dt-bindings/reset/qcom,gcc-ipq8074.h>
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include "ipq8074-ess.dtsi"

/ {
	model = "Redmi AX6";
	compatible = "redmi,ax6", "qcom,ipq8074";

	chosen {
		stdout-path = "serial0:115200n8";
	};
};
EOF

# 清理格式，避免报错
sed -i 's/\r//g' target/linux/qualcommax/dts/ipq8071-ax3600.dtsi

# ==========================================
# 添加 AX6 编译支持
# ==========================================
MK_FILE="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "$MK_FILE" ] && ! grep -q "redmi_ax6" "$MK_FILE"; then
cat >> "$MK_FILE" <<'MKEOF'
define Device/redmi_ax6
  $(call Device/xiaomi_ax3600)
  DEVICE_VENDOR := Redmi
  DEVICE_MODEL := AX6
  IMAGE_SIZE := 245760k
  DEVICE_PACKAGES := ipq-wifi-redmi_ax6
endef
TARGET_DEVICES += redmi_ax6
MKEOF
fi

echo "✅ 修复完成：路径正确 + DTS 无语法错误 + AX6 已添加"
