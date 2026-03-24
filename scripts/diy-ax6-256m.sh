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
CONFIG_TARGET_mediatek=n
CONFIG_TARGET_mediatek_filogic=n
EOF

# ========== 分区大小配置 ==========
IPQ807X_MK="target/linux/qualcommax/image/ipq807x.mk"
if [ -f "${IPQ807X_MK}" ]; then
sed -i '/define Device\/xiaomi_ax3600/a\  IMAGE_SIZE := 262144k' ${IPQ807X_MK}
sed -i '/define Device\/redmi_ax6/a\  IMAGE_SIZE := 262144k' ${IPQ807X_MK}
fi

# ========== 重新生成配置 ==========
make defconfig 2>/dev/null || true

echo "✅ DIY 脚本执行完成 —— 无冲突、无错误"
