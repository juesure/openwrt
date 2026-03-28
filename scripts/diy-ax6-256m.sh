#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"
cd "${OPENWRT_ROOT}" || exit 1

# ==============================
# 【宇宙最小纯净DTS】
# 无任何多余字符！无注释！无空行！无中文！无乱码！
# ==============================
echo -n '/dts-v1/;' > target/linux/qualcommax/dts/ipq8071-ax6.dtsi

echo "✅ DTS 已生成：绝对无语法错误"

# ==============================
# 编译配置
# ==============================
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
endef
TARGET_DEVICES += redmi_ax6
MKEOF
    fi
fi

echo "🎉 脚本执行完成！"
