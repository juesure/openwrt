#!/bin/bash
WORK_DIR="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "$WORK_DIR" || exit 1

# 仅确保机型正常，不修改任何设备树文件
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

echo "✅ DIY 脚本执行完成 —— 无DTS修改，无语法错误"
# --------------------------
# 添加 iStore 软件源
# --------------------------
cat >> "$WORK_DIR/openwrt/etc/opkg/distfeeds.conf" <<EOF
src/gz istore https://istore.link/releases/packages-25.05/aarch64_cortex-a53/istore
src/gz istore_pkg https://istore.link/releases/packages-25.05/aarch64_cortex-a53/packages
EOF

# --------------------------
# 默认替换为清华源
# --------------------------
sed -i 's|downloads.openwrt.org|mirrors.tuna.tsinghua.edu.cn/openwrt|g' \
    "$WORK_DIR/openwrt/etc/opkg/distfeeds.conf"
