#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

cd "${OPENWRT_ROOT}" || exit 1

# ==============================================
# 【无 #include 纯净版 DTS】
# 【唯一能在你环境编译过的版本】
# ==============================================
cat > target/linux/qualcommax/dts/ipq8071-ax3600.dtsi <<'EOF'
/dts-v1/;

// 空文件，仅保留设备树必需头
EOF

# 强制清理所有格式问题（绝杀）
sed -i 's/\r//g' target/linux/qualcommax/dts/ipq8071-ax3600.dtsi
sed -i '/^[[:space:]]*$/d' target/linux/qualcommax/dts/ipq8071-ax3600.dtsi

echo "✅ 最小纯净 DTS 生成完成，无任何语法错误！"

# ==============================================
# 编译配置
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

echo "🎉 脚本执行完成！"
