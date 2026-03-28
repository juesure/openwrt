#!/bin/bash
WORK_DIR="/home/runner/work/openwrt/openwrt/workdir"
OPENWRT_DIR="$WORK_DIR/openwrt"
cd "$OPENWRT_DIR" || exit 1

# ==============================
# AX6 256M 机型配置（安全无冲突）
# ==============================
MK_FILE="$OPENWRT_DIR/target/linux/qualcommax/image/ipq807x.mk"

# 清空重复内容，只保留一次 AX6 定义
sed -i '/define Device\/redmi_ax6/,/TARGET_DEVICES += redmi_ax6/d' "$MK_FILE"

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

# ==============================
# 插件：iStore + Docker + 国内源（安全不报错）
# ==============================
echo "✅ DIY 脚本完成：AX6 256M 已添加"
echo "✅ iStore/Docker/国内源 已在 config 中配置"
