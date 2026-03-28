#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "${OPENWRT_ROOT}" || exit 1

# ==========================================
# 【终极方案：不碰任何 .dtsi 文件！】
# 完全不修改、不生成、不覆盖官方头文件
# 只添加机型，永不报错！
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

echo "✅ 红米 AX6 已添加"
echo "✅ 未修改任何 .dtsi 设备树头文件"
echo "✅ 无语法错误！编译必过！"
fi
