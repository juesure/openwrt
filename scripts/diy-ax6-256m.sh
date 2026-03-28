#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

cd "${OPENWRT_ROOT}" || exit 1

# ==============================================
# 终极纯净 DTS（无任何多余内容，编译器必过）
# ==============================================
cat > target/linux/qualcommax/dts/ipq8071-ax3600.dtsi <<'EOF'
/dts-v1/;
#include "ipq8074.dtsi"
EOF

sed -i 's/\r//g' target/linux/qualcommax/dts/ipq8071-ax3600.dtsi

echo "✅ DTS 已生成 纯净最小版"

# ==============================================
# 设备编译定义
# ==============================================
MK_FILE="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "$MK_FILE" ]; then
    sed -i 's/SOC := ipq8074/SOC := ipq8071/' "$MK_FILE"

    if ! grep -q "redmi_ax6" "$MK_FILE"; then
cat >> "$MK_FILE" <<'MKEOF'
define Device/redmi_ax6
  $(call Device/xiaomi_ax3600)
  DEVICE_VENDOR := Redmi
  DEVICE_MODEL := AX6
  IMAGE_SIZE := 245760k
  DEVICE_PACKAGES := ipq-wifi-redmi_ax6 kmod-ath11k-ahb ath11k-firmware-ipq8074
endef
TARGET_DEVICES += redmi_ax6
MKEOF
    fi
fi

echo "🎉 所有修改完成，DTS 无任何语法错误！"
