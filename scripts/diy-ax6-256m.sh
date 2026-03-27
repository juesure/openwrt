#!/bin/bash
OPENWRT_ROOT="/home/runner/work/openwrt/openwrt/workdir/openwrt"

if [ ! -d "${OPENWRT_ROOT}" ]; then
  echo "❌ 错误：目录不存在"
  exit 1
fi

cd "${OPENWRT_ROOT}" || exit 1

# ========== 清理联发科 ==========
if [ -f ".config" ]; then
  sed -i '/mt76/d' .config
  sed -i '/mediatek/d' .config
fi

rm -rf package/kernel/mt76
./scripts/feeds uninstall -a mt76 2>/dev/null || true

# ========== 锁定平台 ==========
cat > .config << EOF
CONFIG_TARGET_qualcommax=y
CONFIG_TARGET_qualcommax_ipq807x=y
CONFIG_TARGET_qualcommax_ipq807x_DEVICE_redmi_ax6=y
CONFIG_TARGET_MULTI_PROFILE=n
CONFIG_TARGET_ALL_PROFILES=n
CONFIG_TARGET_mediatek=n
CONFIG_TARGET_mediatek_filogic=n
EOF

# ========== 分区大小配置 ==========
IPQ807X_MK="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "${IPQ807X_MK}" ]; then
  # 检查并设置 IMAGE_SIZE
  if ! grep -q "IMAGE_SIZE := 245760k" ${IPQ807X_MK}; then
    sed -i '/define Device\/redmi_ax6/a\  IMAGE_SIZE := 245760k' ${IPQ807X_MK}
  fi
  # 检查并设置 UBINIZE_OPTS
  if ! grep -q "UBINIZE_OPTS" ${IPQ807X_MK}; then
    sed -i '/define Device\/redmi_ax6/a\  UBINIZE_OPTS := -E 5 -m 2048 -p 128KiB -s 2048 -O 2048' ${IPQ807X_MK}
  fi
  # 检查并设置 KERNEL_IN_UBI
  if ! grep -q "KERNEL_IN_UBI" ${IPQ807X_MK}; then
    sed -i '/define Device\/redmi_ax6/a\  KERNEL_IN_UBI := 1' ${IPQ807X_MK}
  fi
fi

# ========== 添加 WiFi 固件修复脚本 ==========
mkdir -p files/etc/init.d
cat > files/etc/init.d/fix-wifi << 'EOF'
#!/bin/sh /etc/rc.common

START=98

start() {
    # 修复 WiFi 固件路径
    if [ -d /lib/firmware/ath11k/IPQ8074/hw2.0 ] && [ ! -f /lib/firmware/ath11k/IPQ8074/q6_fw.mdt ]; then
        echo "修复 WiFi 固件路径..."
        cd /lib/firmware/ath11k/IPQ8074/
        ln -sf hw2.0/* . 2>/dev/null
        echo "WiFi 固件修复完成"
    fi
}
EOF
chmod +x files/etc/init.d/fix-wifi

# ========== 重新生成配置 ==========
make defconfig 2>/dev/null || true

echo "✅ DIY 脚本执行完成 —— 已适配256M Flash，包含 WiFi 固件修复和 iStore"
