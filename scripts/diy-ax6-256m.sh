#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "${OPENWRT_ROOT}" || exit 1

# ==========================================
# 【重要】
# 完全删除所有生成/修改 DTS 设备树的代码
# 只添加 AX6 编译机型
# 绝对不碰官方 DTS 文件
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

echo "✅ 红米 AX6 已成功添加"
echo "✅ 未修改任何设备树文件 → 无语法错误！"
fi
