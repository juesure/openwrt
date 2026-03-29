#!/bin/bash
WORK_DIR="/home/runner/work/openwrt/openwrt/workdir"
OPENWRT_DIR="$WORK_DIR/openwrt"
cd "$OPENWRT_DIR" || exit 1

MK_FILE="$OPENWRT_DIR/target/linux/qualcommax/image/ipq807x.mk"
sed -i '/redmi_ax6/d' "$MK_FILE"

cat >> "$MK_FILE" <<'EOF'
define Device/redmi_ax6
  $(call Device/xiaomi_ax3600)
  DEVICE_VENDOR := Redmi
  DEVICE_MODEL := AX6
  IMAGE_SIZE := 245760k
  DEVICE_PACKAGES := ipq-wifi-redmi_ax6
endef
TARGET_DEVICES += redmi_ax6
EOF

echo "✅ DIY 完成：AX6 256M 已配置"
