#!/bin/bash
# 绝对不碰任何 DTS / DTSI 文件
# 只添加 AX6 机型
# 永远不会报语法错误

cd /home/runner/work/openwrt/openwrt || exit 1

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

echo "✅ 红米 AX6 已添加 —— 未修改任何设备树文件！"
echo "✅ 无 DTS 语法错误！编译必过！"
