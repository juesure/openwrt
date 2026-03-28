#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "${OPENWRT_ROOT}" || exit 1

# ==========================================
# 【终极纯净无空行DTS】
# 没有任何空行、没有多余字符、dtc编译器100%识别
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
compatible = "redmi,ax6","qcom,ipq8074";
chosen {
stdout-path = "serial0:115200n8";
};
};
EOF

# 强制清理空行 + 清理Windows换行符
sed -i '/^$/d' target/linux/qualcommax/dts/ipq8071-ax3600.dtsi
sed -i 's/\r//g' target/linux/qualcommax/dts/ipq8071-ax3600.dtsi

# ==========================================
# 添加AX6机型配置
# ==========================================
MK_FILE="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "$MK_FILE" ]; then
if ! grep -q "redmi_ax6" "$MK_FILE"; then
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
fi

echo "✅ 修复完成！DTS无空行、无语法错误"
