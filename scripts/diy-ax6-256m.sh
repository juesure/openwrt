#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

cd "${OPENWRT_ROOT}" || exit 1

# ==========================================
# 【重要】
# 完全不生成、不修改任何 DTS 文件
# 只添加编译机型
# ==========================================

MK_FILE="target/linux/qualcommax/image/ipq807x.mk"

if [ -f "$MK_FILE" ]; then
    # 只修改机型配置，不碰设备树
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

    echo "✅ 红米 AX6 机型已添加"
    echo "✅ 不修改任何 DTS 文件 → 无语法错误！"
fi
