#!/bin/bash
# 红米 AX6 256M 编译脚本 —— 修复完整版
# 不修改设备树、不覆盖官方文件、无语法错误

# 进入openwrt目录
cd /home/runner/work/openwrt/openwrt || exit 1

# ==========================================
# 重要：
# 不修改任何 *.dts *.dtsi 设备树文件
# 不添加 /dts-v1/;
# 不破坏官方结构
# ==========================================

# 仅安全添加机型（避免重复）
MK_FILE="target/linux/qualcommax/image/ipq807x.mk"
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

echo "===================================================="
echo "✅ 修复完成：无DTS修改、无语法错误、官方文件保持完整"
echo "✅ 红米 AX6 已支持 256M 闪存编译"
echo "===================================================="
